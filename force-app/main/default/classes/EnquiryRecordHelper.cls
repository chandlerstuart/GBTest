/*
Name:  EnquiryRecordHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Enquiry Record Helper class supports the processing of
work items being generated for each action

Coverage: EnquiryRecordHelper - 82%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-20  Initial development.
1.1  J Radcliffe   2019-05-24  Support TODAY text for field mappings
1.2  J Radcliffe   2019-06-03  Change method return type from List<EnquiryManager.Enquiry> to Boolean (runtime exception check)
1.3  J Radcliffe   2019-06-03  Exclude Enquiries with errors
1.4  J Radcliffe   2019-06-03  Change in terminology from 'record' to 'sfRecord'
1.5  J Radcliffe   2019-06-04  Introduced required field feature
1.6  Mark Cane&    2019-06-04  mapEnquiryToSObject>added IsRequired__c field to query - switched 1.3 change to isAborted property.
1.7  J Radcliffe   2019-06-10  Extended Error Handling
1.8  Mark Cane&    2019-06-20  Constants and structured exception handling added.
1.9  J Radcliffe   2019-06-24  Bug Fix - Null reference error
1.10 Mark Cane&    2019-07-01  mapEnquiryToSObject>added field validation - mappings skipped if field name does not exist. Unique SOQL field logic added. Abort enquiries on runtime exception.
1.11 J Radcliffe   2019-08-15  De-couple ActionTypes from Field Mappings - Introducing Action Type Field Mapping Groups
1.12 J Radcliffe   2019-09-05  Even if Update Action is 'Override', do not clear existing data if Enquiry Property is blank
1.13 J Radcliffe   2019-09-16  Bug Fix - Add check for 'Append' update type
1.14 J Radcliffe   2020-01-09  Support for mapping String property to Decimal/Integer Fields - Use case: Mapping trackingInformation.campaignId to Integer field 
1.15 J Radcliffe   2020-02-19  Bug Fix - Statically defined values overriding existing data even if set to 'Omit'+ refactoring/simplification of conditional logic
1.16 J Radcliffe   2020-03-25  Bug Fix - Null checks for Data Type conversion methods
1.17 Mark Cane&    2020-03-30  Bug Fix - Variable does not exist: m (283:21).
1.18 J Radcliffe   2020-10-05  Support for mapping Boolean property with 'Omit' Override Behaviour
1.19 J Radcliffe   2020-11-04  Bug Fix - Handle Long Integers
1.20 Mark Cane&    2022-10-21  Bug Fix - CampaignIds as comma separated list causes numeric data type conversion error.
1.21 Mark Cane&    2023-11-23  Enhancements. ActionTypeRequest related changes.
1.22 Mark Cane&    2023-12-04  Enhancements. Data type conversion enhancements.
1.23 J Radcliffe   2023-12-19  Bug Fix - Small alteration to 1.19. Max integer length = 9, not 10.
*/
public with sharing class EnquiryRecordHelper {
    
    private static final String DUPE_MATCH_ACTION_TYPE_UPDATE = 'Update';//1.8+
    private static final String UPDATE_ACTION_OVERRIDE = 'Override';//1.8+
    private static final String UPDATE_ACTION_OMIT = 'Omit';//1.8+
    private static final String UPDATE_ACTION_APPEND = 'Append';//1.13+

    //Query records that require updating and map the data accross, else map enquiry data to new sObject
    public static Boolean mapEnquiryToSObject(List<EnquiryManager.Enquiry> enquiries){        
        try{
            ActionType__mdt actionType;
            for(EnquiryManager.Enquiry e : enquiries){
                if(e.isAborted) continue;//1.3,1.6~
                if(e.actionType != null){
                    actionType = e.actionType; 
                    break;
                }
            }
            if (actionType==null) return true;

            if(actionType.WorkItemFieldMappingGroup__c == null){//1.11+
                for (EnquiryManager.Enquiry e : enquiries){
                        e.errorMessages.put('1050',Label.Enquiry_Validation_Error_Invalid_Action_Type_Work_Item_Field_Mappings);
                        e.isAborted=true;
                }
                return false;
            }

            Map<String, Schema.SobjectField> fieldMap = DescribeHelper.getObjectFieldMap(actionType.SObjectType__c);//1.10+

            //Retrieve field mapping data for the relevant action
            ActionTypeFieldMapping__mdt[] fieldMappings = [select EnquiryPropertyName__c, EnquiryPropertyDataType__c, StaticValue__c, UseStaticValue__c,
                                                                SObjectFieldAPIName__c, SObjectFieldDataType__c, UpdateAction__c, IsRequired__c
                                                            from ActionTypeFieldMapping__mdt 
                                                            where ActionTypeFieldMappingGroup__c = :actionType.WorkItemFieldMappingGroup__c];//1.6~//1.11~

            //Retrieve or create sObject, based on configured Dupe Action
            if(actionType.DupeMatchAction__c==DUPE_MATCH_ACTION_TYPE_UPDATE){

                Map<String,Id> enquiryKeyWithDupeRecordId = new Map<String,Id>();
                Set<Id> dupeIds = new Set<Id>();

                for(EnquiryManager.Enquiry enq : enquiries){
                    if(enq.isAborted) continue;//1.3,1.6~
                    if(enq.duplicateEnquiryId != null && !dupeIds.contains(enq.duplicateEnquiryId)){
                        dupeIds.add(enq.duplicateEnquiryId);
                        enq.uniqueIdentifier = enq.clientDetails.accountId+enq.tripDetails.territoryId+String.valueOf(Math.random()*1000000);
                        enquiryKeyWithDupeRecordId.put(enq.uniqueIdentifier,enq.duplicateEnquiryId);
                    }
                }
                
                //Dynamically Query Duplicate records
                Set<String> fieldsAdded = new Set<String>{ 'Id' };//1.10+ - avoid SOQL query exception when field named multiple times in select clause.

                String q = 'select Id';
                for(ActionTypeFieldMapping__mdt fm : fieldMappings){
                    if (String.isBlank(fm.SObjectFieldAPIName__c) || !fieldMap.containsKey(fm.SObjectFieldAPIName__c)) continue;//1.10+ - ignore invalid field names.
                    if (fieldsAdded.contains(fm.SObjectFieldAPIName__c)) continue;//1.10+ - skip added fields.

                    q+=','+String.escapeSingleQuotes(fm.SObjectFieldAPIName__c);                    
                    fieldsAdded.add(fm.SObjectFieldAPIName__c);//1.10+
                }
                q+=' from '+actionType.SObjectType__c+' where Id in:dupeIds';
                
                Map<Id,sObject> dupeRecordMap = new Map<Id,sObject>(Database.query(q));

                //If successfully retrieved, set the Enquiry.record as the dupe record else create a new sObject
                for(EnquiryManager.Enquiry enq : enquiries){
                    if(enq.isAborted) continue;//1.3,1.6~
                    if(enquiryKeyWithDupeRecordId.containsKey(enq.uniqueIdentifier) 
                    && enquiryKeyWithDupeRecordId.get(enq.uniqueIdentifier) != null
                    && dupeRecordMap != null && dupeRecordMap.values().size()>0
                    && dupeRecordMap.containsKey(enquiryKeyWithDupeRecordId.get(enq.uniqueIdentifier))){
                        enq.sfRecord = dupeRecordMap.get(enquiryKeyWithDupeRecordId.get(enq.uniqueIdentifier));
                    }else{
                        enq.sfRecord = DescribeHelper.globalDescribe.get(actionType.SObjectType__c).newSObject();
                    }
                }
            }else{
                //Create new sObject
                for(EnquiryManager.Enquiry enq : enquiries){
                    if(enq.isAborted) continue;//1.3
                    enq.sfRecord = DescribeHelper.globalDescribe.get(actionType.SObjectType__c).newSObject();
                }
            }
            
            //Map enquiry details to SObject/s
            for(EnquiryManager.Enquiry enq : enquiries){
                if(enq.isAborted) continue;//1.3,1.6~
                //Final check to confirm a record exists
                if(enq.sfRecord == null){
                    enq.sfRecord = DescribeHelper.globalDescribe.get(actionType.SObjectType__c).newSObject();
                }
                for(ActionTypeFieldMapping__mdt fm : fieldMappings){
                    if (String.isNotBlank(fm.SObjectFieldAPIName__c) && !fieldMap.containsKey(fm.SObjectFieldAPIName__c)){

                        //Note, there is no means currently to log a message (only SaveResults, Exceptions or API Requests).
                        //As such, an Enquiry level general errorMessage is added; the technical detail is added as a warningMessage.
                        //warningMessages are added to the logged API request but not returned to the calling agent.
                        //Todo - enable error message logging via the IEnquiryLogHandler interface.

                        if (!enq.errorMessages.containsKey('1025')) enq.warningMessages.put('1025',Label.Enquiry_Validation_Error_Invalid_Action_Type_Configuration);
                        enq.warningMessages.put('W1025',Label.Enquiry_Validation_Error_Invalid_Object_Field_API_Name+' ['+fm.SObjectFieldAPIName__c+']');

                        continue;//1.10+ - ignore invalid field names.
                    }                    
                    enq.sfRecord = validateAndMapFields(enq.sfRecord,enq,fm);
                }
                //Allow Field Truncation
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
                if(enq.sfRecord != null) enq.sfRecord.setOptions(dml);
            }
            return true;

        } catch(exception ex){ 
            LogHelper.logExceptions(ex, 'EnquiryRecordHelper', 'mapEnquiryToSObject');
            for (EnquiryManager.Enquiry e : enquiries){ e.errorMessages.put('1005',Label.Enquiry_Technical_Error); e.isAborted=true; }//1.10+
        }//1.8+
        return false;//1.2
    }

    public static sObject validateAndMapFields(sObject sfRecord, EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        try {
            if(fm.IsRequired__c && enq.getValue(fm.EnquiryPropertyName__c) == null){//1.5
                enq.errorMessages.put('1020',Label.Enquiry_Validation_Error_Missing_Required_Field+': '+fm.EnquiryPropertyName__c);
                return sfRecord;
            }
            if(fm.UseStaticValue__c && fm.StaticValue__c == null) return sfRecord;
            if(!fm.UseStaticValue__c && (fm.EnquiryPropertyName__c == null || enq.getValue(fm.EnquiryPropertyName__c) == null)) return sfRecord;

            //1.15-
            /*if((fm != null && fm.UpdateAction__c==UPDATE_ACTION_OVERRIDE 1.12 && (!fm.UseStaticValue__c && enq.getValue(fm.EnquiryPropertyName__c) != null && String.valueOf(enq.getValue(fm.EnquiryPropertyName__c)) != '') 
                || (fm.UseStaticValue__c && fm.StaticValue__c != null)) 
                || (sfRecord != null && sfRecord.get(fm.SObjectFieldAPIName__c) == null)){//1.9+*/
        
            //1.15+
            //If update action is 'Override' or no value currently exists in the sfRecord field
            if((fm.UpdateAction__c==UPDATE_ACTION_OVERRIDE || (sfRecord != null && sfRecord.get(fm.SObjectFieldAPIName__c) == null))
            //and either a value has been passed or statically defined (there is a value to set in the field)
            && ((!fm.UseStaticValue__c && enq.getValue(fm.EnquiryPropertyName__c) != null && String.valueOf(enq.getValue(fm.EnquiryPropertyName__c)) != '') || (fm.UseStaticValue__c && fm.StaticValue__c != null))){
                if((fm.SObjectFieldDataType__c == fm.EnquiryPropertyDataType__c) || fm.UseStaticValue__c){
                    //Override the existing values
                    //New
                    switch on fm.SObjectFieldDataType__c {
                        when 'String' {
                            sfRecord.put(fm.SObjectFieldAPIName__c,(String)getStringValue(enq,fm));
                        }
                        when 'Integer' {
                            sfRecord.put(fm.SObjectFieldAPIName__c,(Integer)getIntegerValue(enq,fm));
                        }
                        when 'Date' {
                            sfRecord.put(fm.SObjectFieldAPIName__c,(Date)getDateValue(enq,fm));
                        }
                        when 'DateTime' {
                            sfRecord.put(fm.SObjectFieldAPIName__c,(DateTime)getDateTimeValue(enq,fm));
                        }
                        when 'Boolean' {
                            sfRecord.put(fm.SObjectFieldAPIName__c,(Boolean)getBooleanValue(enq,fm));
                        }
                        when 'Decimal' {
                            sfRecord.put(fm.SObjectFieldAPIName__c,(Decimal)getDecimalValue(enq,fm));
                        }
                        when else {
                            sfRecord.put(fm.SObjectFieldAPIName__c,String.valueOf(enq.getValue(fm.EnquiryPropertyName__c)));
                        }
                    }
                    //[Removed for release] system.debug('sfRecord: '+sfRecord);
                } else{
                    //Reformat and override the existing value
                    sfRecord = handleDataTypeMismatch(sfRecord, enq, fm, true);
                }
            } else if(fm.UpdateAction__c==UPDATE_ACTION_OMIT){
                //1.18+
                if(fm.SObjectFieldDataType__c == 'Boolean' &&  sfRecord != null && enq.getValue(fm.EnquiryPropertyName__c) != null && enq.getValue(fm.EnquiryPropertyName__c) == true
                    && (sfRecord.get(fm.SObjectFieldAPIName__c) == null || sfRecord.get(fm.SObjectFieldAPIName__c) == false )){
                    sfRecord.put(fm.SObjectFieldAPIName__c,true);
                    return sfRecord;
                }

                //Exit with no changes (leave existing data as is)
                return sfRecord;
            } else if(fm.UpdateAction__c == UPDATE_ACTION_APPEND ){//1.13+
                //Append to existing data
                if((fm.SObjectFieldDataType__c == fm.EnquiryPropertyDataType__c) || fm.UseStaticValue__c){
                    if(fm.SObjectFieldDataType__c != 'String'){
                        enq.errorMessages.put('1010',Label.Enquiry_Validation_Error_Append_Failure_Unsupported_Data_Type+': '+fm.EnquiryPropertyName__c+' to '+fm.SObjectFieldAPIName__c);//1.7
                        return sfRecord;
                    }
                    sfRecord.put(fm.SObjectFieldAPIName__c,sfRecord.get(fm.SObjectFieldAPIName__c)+';'+(String)getStringValue(enq,fm));
                } else {
                    //Reformat and override the existing value
                    sfRecord = handleDataTypeMismatch(sfRecord, enq, fm, false);
                }
            }            

        } catch (exception ex){//1.8+
            LogHelper.logExceptions(ex, 'EnquiryRecordHelper', 'validateAndMapFields');
            enq.errorMessages.put('1015',Label.Enquiry_Technical_Error);//1.10+
            enq.isAborted=true;//1.10+
            //[Removed for release] system.debug('Error Mapping Fields: '+ex);
        }
        //[Removed for release] system.debug('validateAndMapFields Stop');
        //1.22-return null;
        return sfRecord;//1.22+ -- calling methods don't support null return.
    }

    //This method handles field that require reformatting to accomodate the different data types
    public static sObject handleDataTypeMismatch(sObject sfRecord, EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm, Boolean replace){
        try {
            
            //TO DO - Build out more scenarios as required
            //Scenario 1 - Map Array String to Multi Select Picklist for override and merge scenarios
            if(fm.SObjectFieldDataType__c == 'Multi Select' && fm.EnquiryPropertyDataType__c == 'String Array'){
                if(replace || sfRecord.get(fm.sObjectFieldAPIName__c) == null){
                    
                    if (enq.getValue(fm.EnquiryPropertyName__c) instanceof List<String>){//1.21~
                        sfRecord.put(fm.sObjectFieldAPIName__c, String.join((List<String>)enq.getValue(fm.EnquiryPropertyName__c),';'));
                    } else sfRecord.put(fm.sObjectFieldAPIName__c, (String)enq.getValue(fm.EnquiryPropertyName__c));

                }else{
                    String multiSelectValues = (String)sfRecord.get(fm.sObjectFieldAPIName__c);
                    for(String s : (List<String>)enq.getValue(fm.EnquiryPropertyName__c)){
                        if(!multiSelectValues.contains(s)){
                            //Append NEW values
                            multiSelectValues = multiSelectValues+';'+s;
                        }
                    }
                    sfRecord.put(fm.sObjectFieldAPIName__c,multiSelectValues);
                }
            }else if(fm.SObjectFieldDataType__c == 'Integer' && fm.EnquiryPropertyDataType__c == 'String'){//1.14+

                String campaignId = (String)enq.getValue(fm.EnquiryPropertyName__c);//1.20+
                if (campaignId.contains(',')){ campaignId = campaignId.split(',')[0]; }//1.20. use the first id only where a list is set.

                if((campaignId).length()>=10){//1.20~ 1.19+ 1.23~
                    sfRecord.put(fm.sObjectFieldAPIName__c,Long.valueOf(campaignId).intValue());//1.20~
                }else{
                    sfRecord.put(fm.sObjectFieldAPIName__c,Integer.valueOf(campaignId));//1.20~
                }
            }else if(fm.SObjectFieldDataType__c == 'Decimal' && fm.EnquiryPropertyDataType__c == 'String'){//1.14+
                sfRecord.put(fm.sObjectFieldAPIName__c,Decimal.valueOf((String)enq.getValue(fm.EnquiryPropertyName__c)));//1.20~
            }else{
                //Log unhandled scenario, so it can be reviewed and (if required) built into the 'mismatch logic'
                enq.errorMessages.put('1030',Label.Enquiry_Validation_Error_Unable_To_Reformat_Data_Types+': From '+fm.EnquiryPropertyName__c+' ('+fm.EnquiryPropertyDataType__c+') to '+fm.sObjectFieldAPIName__c+' ('+fm.SObjectFieldDataType__c+')');//1.7
            }
            return sfRecord;
        } catch (exception ex){
            LogHelper.logExceptions(ex, 'EnquiryRecordHelper', 'handleDataTypeMismatch');
            enq.errorMessages.put('1035',Label.Enquiry_Technical_Error);//1.10+
            enq.isAborted=true;//1.10+
        }//1.8+
        return null;
    }

    public static String getStringValue(EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        if(fm.UseStaticValue__c){
            return (fm.StaticValue__c != null)?String.valueOf(fm.StaticValue__c):null;//1.16~
        }else{
            return (String)enq.getValue(fm.EnquiryPropertyName__c);
        }
    }
    public static Decimal getDecimalValue(EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        if(fm.UseStaticValue__c){
            //1.17- return (m.StaticValue__c != null)?Decimal.valueOf(fm.StaticValue__c):null;//1.16~
            return (fm.StaticValue__c != null)?Decimal.valueOf(fm.StaticValue__c):null;//1.17+
        }else{//1.22~

            Object o = enq.getValue(fm.EnquiryPropertyName__c);
            if (o!=null && (o instanceof Integer || o instanceof Decimal)) return (Decimal)o;//1.22+ -- safe casting
            return null;
        }
    }
    public static Integer getIntegerValue(EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        if(fm.UseStaticValue__c){
            return (fm.StaticValue__c != null)?Integer.valueOf(fm.StaticValue__c):null;//1.16~
        }else{//1.22~

            Object o = enq.getValue(fm.EnquiryPropertyName__c);
            if (o!=null && o instanceof Integer) return (Integer)o;//1.22+ -- safe casting
            if (o!=null && o instanceof Decimal) return ((Decimal)o).intValue();//1.22+ -- safe casting
            return null;
        }
    }
    public static DateTime getDateTimeValue(EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        if(fm.UseStaticValue__c){
            return (fm.StaticValue__c != null)?DateTime.valueOf(fm.StaticValue__c):null;//1.16~
        }else{//1.22~

            Object o = enq.getValue(fm.EnquiryPropertyName__c);
            if (o!=null && o instanceof Datetime) return (DateTime)o;//1.22+ -- safe casting       
            return null;
        }
    }
    public static Date getDateValue(EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        if(fm.UseStaticValue__c){
            if(fm.StaticValue__c != null){//1.16+
                if(fm.StaticValue__c.equalsIgnoreCase('Today')){
                    return system.today();
                }else if(fm.StaticValue__c.equalsIgnoreCase('Tomorrow')){
                    return system.today().addDays(1);
                /*1.1 - TO DO - Time permitting it would be nice to support more complex values for Dates:
                }else if(fm.StaticValue__c.containsIgnoreCase('NEXT_N_DAYS:')){
                    etc... 
                }*/
                }else{
                    return Date.valueOf(fm.StaticValue__c);
                }
            }else{ return null;}
        }else{//1.22~

            Object o = enq.getValue(fm.EnquiryPropertyName__c);
            if (o!=null && o instanceof Date) return (Date)o;//1.22+ -- safe casting      
            return null;
        }
    }
    public static Boolean getBooleanValue(EnquiryManager.Enquiry enq, ActionTypeFieldMapping__mdt fm){
        if(fm.UseStaticValue__c){
            return (fm.StaticValue__c != null)?Boolean.valueOf(fm.StaticValue__c):null;//1.16~
        }else{//1.22~

            Object o = enq.getValue(fm.EnquiryPropertyName__c);
            if (o!=null && o instanceof Boolean) return (Boolean)o;//1.22+ -- safe casting           
            return null;
        }
    }
}