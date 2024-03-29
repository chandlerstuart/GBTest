/*
Name:  RedirectHelper.cls
Copyright © 2014  Kaptio ehf.
Based on code from Frank Neezen
http://www.frankneezen.com/2013/04/salesforce-url-hacking-prepopulating-fields/
======================================================
======================================================
Purpose:
-------
Helper class for RedirectController.cls
======================================================
======================================================
History
------- 
Ver.    Author         Date         Detail
1.0     Halldór Örn    2014-05-27   Class creation.
1.1     Halldór Örn    2014-08-03   Name changed from staticFunctions.cls 
1.2     J Radcliffe    2020-01-31   Bug Fix - Temporary fix for issue where Employee Leave Year is not defaulted correctly. Long term fix = Lightning Transformation of Smart Calendar

*/
public with sharing class RedirectHelper {
    // Variables used in getLabel function to store object and it's fields metadata
    public static Map<String, Schema.SObjectType> mSchema = new Map<String,Schema.SObjectType>();
    public static Schema.SObjectType oSchema = null;
    public static Map<String, Schema.SObjectField> mFields = null;

    /*
     *  Method name:    createLabelParameters
     *  @description    Creates a set of parameters given an sobject. If the label is mentioned in the URL Get Parameter
     *                  and has a value, this label is translated to the ID and linked to the value
     *  @param          List<Medical_Event_vod__c> lEvents  List of medical events
     *  @return         void
     */
    public static Map<String, String> createLabelParameters(PageReference pReference, sObject oGeneric){        
        
        //store the html from the page reference
        String html = '';

        //Dummy data for testing if we do tests                
        if (System.Test.isRunningTest()){
            html = '<label for="CF00NK0000000Yt1b"><span class="requiredMark">*</span>Name</label><label for="CF00NK0000000Yt1b">Account</label>';
        }
        else{
            
            //get the HTML contents
            html = pReference.getContent().toString();      
        }

        system.debug('HTML: '+html);
        
        // Capture the accountId of the case
        String def_account_id= System.currentPageReference().getParameters().get('def_account_id');
        
        //Create the map that stores the label to label ID
        Map<String, String> mLabelToID = new Map<String, String>();
        
        //Create the regular expression to fetch all labels
        Matcher m = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?(.*?)</label>').matcher(html);
        
        //While there are labels
        while (m.find()) {
            //Label is stored in the 4th column 
            String label = m.group(3);
            label = label.contains('</span>')?label.substringAfter('</span>'):label;//1.2+
            //Id is stored in the second column
            String id = m.group(1);
            
            //Add it to the map (split on _, on occasion we have a _top somewhere)
            mLabelToID.put(label, id.split('_')[0]);                  
        }
        
        // Create new parameter set
        Map<String, String> params = new Map<String, String>();
        
        //for each field in our object
        for (SObjectField field : oGeneric.getSObjectType().getDescribe().fields.getMap().values()) {
            
            //Get the field description object
            DescribeFieldResult f = field.getDescribe();
            
            String label = f.getLabel();        //Get label name
            String apiName = f.getName();       //Get API name
            System.debug('=== apiName: ' + label + ' ' + apiName);
            //Get the parameter from GET
            Object value = ApexPages.currentPage().getParameters().get(apiName);

            system.debug('value: '+value);
                    
            //If we have a value
            if (value != null) {
                
                //If there is a label              
                if (mLabelToID.containsKey(label)) {

                    // Format the given value as required
                    String valueAsString;
                    if (f.getType() == DisplayType.Date) {
                        valueAsString = String.valueOf(value); // ((Date) value).format();
                    } else if (f.getType() == DisplayType.Datetime) {
                        valueAsString = String.valueOf(value); // ((Datetime) value).format();
                    } else if (f.getType() == DisplayType.Boolean) {
                        valueAsString = ((Boolean) value) ? '1' : '0';
                    } else {
                        valueAsString = String.valueOf(value);
                    }
                     
                    //If it is a lookup field, we expect to add the ID as well
                    if(f.getReferenceTo().size()>0){
                        
                        //We assume that the variable will contain ID_ for a lookup parameter
                        String strIDLookup = ApexPages.currentPage().getParameters().get('ID_' + apiName).trim();
                                                                                            
                        //If not null, add the parameter (use _lkid to reference the ID field)
                        if(strIDLookup!=null)
                             params.put(mLabelToID.get(label) + '_lkid', strIDLookup);
                    }
                    
                                                          
                    //Set the ID to the value
                    params.put(mLabelToID.get(label), valueAsString);
                  
                }
            }
        }
        
        //Check if we also have to set the Record Type
        String strRecordType = ApexPages.currentPage().getParameters().get('RecordType');
        
        //If we have a record type
        if(strRecordType != null){
            
            //Lets find the ID
            List<RecordType> lTypes = [ Select  Id
                                        From    RecordType
                                        Where   Name =: strRecordType
                                        And     SObjectType =: oGeneric.getSObjectType().getDescribe().getName() ];
            
            //If we can find the record type, add it as a parameter
            if(lTypes.size() > 0)
                 params.put('RecordType', lTypes[0].Id);
                        
        }
        
        //Populate the accountId if its alreday present
        if(def_account_id!=null)
            params.put('def_account_id',def_account_id);
        
        //Return the set of label ID's to values
        return params;
            
    }

    /*
     *  Method name:    getLabel
     *  @description    Gets the label name given an API 
     *  @param          String  The API name of object from which the field lable is required
     *  @return         String  The Label name for the given API Name of a Field
     */
    public static String getLabel(String objectName,String strFieldName){
        
        //Get global schema
        if(mSchema.size() == 0){
            mSchema = Schema.getGlobalDescribe();
            
            //Get field schema for medical event
            oSchema = mSchema.get(objectName);
            
            //Get mapping of fields 
            mFields = oSchema.getDescribe().fields.getMap();    
                
        }
        
        //check if it exists, else return null
        if(mFields.containsKey(strFieldName.toLowerCase()))     
            return mFields.get(strFieldName).getDescribe().getLabel();  //return field label
        
        return strFieldName;
    }
}