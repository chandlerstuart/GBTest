/*
Name:  FormatStringHelper.cls
Copyright © 2020  Golfbreaks
======================================================
======================================================
Purpose:
-------

Format String Helper class supports the dynamic  composition
of format strings used in paths, response and request bodies.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2020-02-05  Initial development.
1.1  J Radcliffe   2020-03-20  Bug Fix - Only add dynamic request data for winning record if DET DOT is a 'Merge'
1.2  Mark Cane&    2020-03-30  Bug fixes. W-001129:Id only formats. W-001124:Delete whitespace from format string field lists.
1.3  Mark Cane&    2020-04-15  Bug fixes. String value cast change to valueOf() to avoid type conversion exceptions.
1.4  Mark Cane&    2020-04-20  Enhancements. Added getTypeFormattedValue.
1.5  Mark Cane&    2020-05-13  Enhancements. Generic polymorphic field handling.
1.6  J Radcliffe   2020-05-13  Enhancement - Add 'DATETIME' Data Type support to getTypeFormattedValue method.
1.7  Mark Cane&    2020-06-24  Bug fixes. Multi-records per-DET issue with ID only formats.
1.8  Mark Cane&    2020-08-12  Enhancement - added getJSONSafeFormatString method to allow for nested JSON structures.
1.9  Mark Cane&    2022-11-09  Enhancement - getJSONSafeFormatString visibility change from private to public.
1.10 J Radcliffe   2023-01-26  Bug fixes. Escape } not preceded by another } e.g. in nested json object structures.
1.11 Mark Cane&    2023-08-21  Bug fixes. Class set Without Sharing to support lead conversion use cases where convertor does not have access to the converted opportunity.
1.12 J Radcliffe   2023-11-23  Enhancement. Adding support for multiple references to the same field within a dynamic request body.
*/
public without sharing class FormatStringHelper {//1.11~
    public FormatStringHelper(){}

    public static String buildDynamicStringForRecordId(String sObjectType, String idFieldName, Id recordId,  String fieldListCommaDelim, String formatString){
        try {
            if (String.isBlank(sObjectType) || String.isBlank(idFieldName) || recordId==null || String.isBlank(formatString) || String.isBlank(fieldListCommaDelim)) return '';
            
            //if invalid ObjectType or ExternalId field return ''
            if (String.isBlank(sObjectType) || !DescribeHelper.globalDescribe.containsKey(sObjectType)) return '';            
            if (String.isBlank(idFieldName) || !DescribeHelper.getObjectFieldMap(sObjectType).containsKey(idFieldName)) return '';

            Set<String> formatStringFields = new Set<String>( fieldListCommaDelim.deleteWhitespace().split(',') );//1.2~

            Boolean externalIdFieldOnly = formatStringFields.size()==1 && (new List<String>(formatStringFields)[0].equalsIgnoreCase(idFieldName)) ? true : false;

            //build query and execute
            Sobject o;
            Set<String> fieldsAdded = new Set<String>();//1.5~
            
            if(externalIdFieldOnly){
                o = DescribeHelper.globalDescribe.get(sObjectType).newSObject();
                o.put(idFieldName,recordId);

                fieldsAdded.add(idFieldName.toUpperCase());//1.5+

            } else {                

                String q='select Id';
                fieldsAdded.add('ID');            

                for (String f : formatStringFields){

                    if (f.contains('.')){//Parent relationship field reference.

                        // E.g. ParentAccount.CreatedBy.Email

                        // Start - SobjectType = e.g. Account.
                        // index 0 - get parentrelationship map for Sobject and containsKey check on index, get the next SobjectType.
                        // index n - if not last index - set SobjectType and repeat 0
                        // index n - if last index - get field map for SobjectType and containsKey check.

                        String parentRelationshipName, parentSobjectTypeName = sObjectType;
                        Boolean isPolymorphic=false;//1.5+

                        List<String> pathElements = f.split('\\.');

                        for (Integer n=0; n<pathElements.size(); n++){

                            if (n==pathElements.size()-1){//last index -- validate field name.
                                
                                //1.5-if (DescribeHelper.getObjectFieldMap(parentSobjectTypeName).containsKey(pathElements[n])){
                                //1.5-    q+=','+String.escapeSingleQuotes(f);
                                //1.5-    fieldsAdded.add(f);         
                                //1.5-}
                                if (!fieldsAdded.contains(f.toUpperCase()) && DescribeHelper.getObjectFieldMap(parentSobjectTypeName).containsKey(pathElements[n])){//1.5~
                                    
                                    if (String.isNotBlank(parentRelationshipName) && isPolymorphic){
                                        q+=',TYPEOF '+String.escapeSingleQuotes(parentRelationshipName)+' WHEN '+String.escapeSingleQuotes(parentSobjectTypeName)+' THEN '+String.escapeSingleQuotes(pathElements[n])+' END';

                                    } else q+=','+String.escapeSingleQuotes(f);                                    
                                    
                                    fieldsAdded.add(f.toUpperCase());//add the full field path.
                                }
                                
                            } else {// -- validate parent relationship name.
                                
                                //f=Owner.Id ; pathElements[n]=Owner,Id
                                //f=Owner|User.Email ; pathElements[n]=Owner|User,Email
                                //f=Owner|User.Manager.TimezoneSidKey ; pathElements[n]=Owner|User,Manager,TimezoneSidKey
                                //f=Owner|Queue.DeveloperName ; pathElements[n]=Owner|Queue,DeveloperName

                                isPolymorphic = pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2;
                                                                
                                parentRelationshipName = isPolymorphic ? pathElements[n].split('\\|')[0] : pathElements[n];//1.5+

                                if (!DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).containsKey(parentRelationshipName)) break;// -- parent relationship name doesn't exist.
                                
                                if (isPolymorphic 
                                    && DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName).size()>1
                                    && DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName).contains(pathElements[n].split('\\|')[1])){//1.5+
                                    
                                    parentSobjectTypeName = pathElements[n].split('\\|')[1];

                                } else {

                                    isPolymorphic=false;
                                    parentSobjectTypeName = DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName)[0];//1.5~
                                }
                            }
                        }
                    } else {
                        
                        if (DescribeHelper.getObjectFieldMap(sObjectType).containsKey(f) && !fieldsAdded.contains(f.toUpperCase())){
                            q+=','+String.escapeSingleQuotes(f);
                            fieldsAdded.add(f.toUpperCase()); 
                        }
                    }
                }
                q+=' from '+String.escapeSingleQuotes(sObjectType);
                q+=' where '+idFieldName+'=\''+String.escapeSingleQuotes(recordId)+'\'';
                q+=' limit 1';

                Map<Id,SObject> idToSObject = new Map<Id,SObject>(Database.query(q));
                if (idToSObject.isEmpty()) return '';

                o = idToSObject.values()[0];    
            }

            Map<String, Object> fieldsMap = o.getPopulatedFieldsAsMap();
            String fv;
            List<Object> formatParameters = new List<Object>();            

            for (String f : formatStringFields){

                fv='';//1.5+
                if (!fieldsAdded.contains(f.toUpperCase())) continue;//1.5+

                try {

                    if (String.isNotBlank(f) && f.contains('.')){

                        List<String> pathElements = f.split('\\.');
                        Sobject p = o;

                        for (Integer n=0; n<pathElements.size();n++){
                            if (n==pathElements.size()-1){
                                
                                fv = p==null ? '' : getTypeFormattedValue(DescribeHelper.getSObjectTypeName(p.getSObjectType()),pathElements[n],p);//1.4+
                                //1.4- fv = (String)p.get(pathElements[n]);

                            } else p = (pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2) ? p.getSObject(pathElements[n].split('\\|')[1]) : p.getSObject(pathElements[n]);//1.5~
                        }

                    } else fv = String.isNotBlank(f) && fieldsMap.containsKey(f) ? getTypeFormattedValue(sObjectType,f,o) : '';//1.4~

                    formatParameters.add(fv);
                        
                } catch(Exception e){ formatParameters.add(''); }
            }
        
            formatString = getJSONSafeFormatString(formatString,formatParameters);//1.8+

            //1.8- Boolean isJSON=false;

            //1.8- if (formatString.startsWith('{')){
            //1.8-     formatString = formatString.removeStart('{');
            //1.8-     formatString = formatString.removeEnd('}');
            //1.8-     isJSON = true;
            //1.8- }
        
            //1.8- formatString = String.format(formatString,formatParameters);
            //1.8- if (isJSON) formatString = '{'+formatString+'}';
        
            //[Removed for release] System.debug(LoggingLevel.ERROR,'formatString='+formatString);            
            return formatString;

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'FormatStringHelper', 'buildDynamicStringForRecordId'); }
        return '';
    }

    public static Map<Id,List<String>> buildDynamicStringsForDataEventType(DataEventType__mdt det, Set<Id> recordIds){

        Map<Id,List<String>> recordIdToDynamicStrings = new Map<Id,List<String>>();

        try {
            if (det==null || recordIds==null || recordIds.isEmpty()) return recordIdToDynamicStrings;
            

            String sObjectType = det.ObjectType__c;
            if (String.isBlank(sObjectType) || !DescribeHelper.globalDescribe.containsKey(sObjectType)) return recordIdToDynamicStrings;            

            String idFieldName = 'Id';
            
            Set<String> formatStringFields = new Set<String>();
            
            //1.12~ replacing with a list<Strings> as there could be multiple references of the same fields within a JSON request structure, so duplicates must be supported. 
            //This is safe to change because the field values are combined in the formatStringFields set to avoid duplication in the subsequent query.
            //Set<String> endPointPathFormatStringFields = new Set<String>();//1.12-
            //Set<String> requestformatStringFields = new Set<String>();//1.12-
            List<String> endPointPathFormatStringFields = new List<String>();
            List<String> requestformatStringFields = new List<String>();

            if (String.isNotBlank(det.EndpointPathFormatStringFields__c)) endPointPathFormatStringFields.addAll( det.EndpointPathFormatStringFields__c.deleteWhitespace().split(',') );//1.2~
            if (String.isNotBlank(det.RequestFormatFields__c)) requestformatStringFields.addAll( det.RequestFormatFields__c.deleteWhitespace().split(',') );//1.2~

            if (!endPointPathFormatStringFields.isEmpty()) formatStringFields.addAll(endPointPathFormatStringFields);
            if (!requestformatStringFields.isEmpty()) formatStringFields.addAll(requestformatStringFields);
            if (formatStringFields.isEmpty()) return recordIdToDynamicStrings;


            Boolean isIdFieldOnly = formatStringFields.size()==1 && (new List<String>(formatStringFields)[0].equalsIgnoreCase('Id')) ? true : false;

            //build query and execute
            Sobject o;
            Map<Id,Sobject> idToSObject;
            Set<String> fieldsAdded = new Set<String>();//1.5~
            
            if(isIdFieldOnly){
                //1.7- o = DescribeHelper.globalDescribe.get(sObjectType).newSObject();
                
                idToSObject = new Map<Id,Sobject>();

                for (Id recordId : recordIds){ 
                    o = DescribeHelper.globalDescribe.get(sObjectType).newSObject();//1.7+

                    o.put(idFieldName,recordId);
                    idToSObject.put(recordId,o);//1.2+
                }
                fieldsAdded.add(idFieldName.toUpperCase());//1.5+

            } else {

                String q='select Id';
                fieldsAdded.add('ID');            

                if(det != null && det.DataOperationType__c == Label.Picklist_Value_Data_Event_Data_Operation_Type_Merge && !formatStringFields.contains('MasterRecordId')) formatStringFields.add('MasterRecordId'); //1.1+ -- Ensure Master Record Id is queried 

                for (String f : formatStringFields){

                    if (f.contains('.')){//Parent relationship field reference.

                        // E.g. ParentAccount.CreatedBy.Email

                        // Start - SobjectType = e.g. Account.
                        // index 0 - get parentrelationship map for Sobject and containsKey check on index, get the next SobjectType.
                        // index n - if not last index - set SobjectType and repeat 0
                        // index n - if last index - get field map for SobjectType and containsKey check.

                        String parentRelationshipName, parentSobjectTypeName = sObjectType;//1.5~  
                        Boolean isPolymorphic=false;//1.5+

                        List<String> pathElements = f.split('\\.');

                        for (Integer n=0; n<pathElements.size(); n++){

                            if (n==pathElements.size()-1){//last index -- validate field name.
                                
                                if (!fieldsAdded.contains(f.toUpperCase()) && DescribeHelper.getObjectFieldMap(parentSobjectTypeName).containsKey(pathElements[n])){//1.5~
                                    
                                    if (String.isNotBlank(parentRelationshipName) && isPolymorphic){
                                        q+=',TYPEOF '+String.escapeSingleQuotes(parentRelationshipName)+' WHEN '+String.escapeSingleQuotes(parentSobjectTypeName)+' THEN '+String.escapeSingleQuotes(pathElements[n])+' END';

                                    } else q+=','+String.escapeSingleQuotes(f);                                    
                                    
                                    fieldsAdded.add(f.toUpperCase());//add the full field path.
                                }
                                
                            } else {// -- validate parent relationship name.

                                //1.5- if (!DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).containsKey(pathElements[n])) break;// -- parent relationship name doesn't exist.                                
                                //1.5- parentSobjectTypeName = DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(pathElements[n]);

                                //f=Owner.Id ; pathElements[n]=Owner,Id
                                //f=Owner|User.Email ; pathElements[n]=Owner|User,Email
                                //f=Owner|User.Manager.TimezoneSidKey ; pathElements[n]=Owner|User,Manager,TimezoneSidKey
                                //f=Owner|Queue.DeveloperName ; pathElements[n]=Owner|Queue,DeveloperName

                                isPolymorphic = pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2;
                                                                
                                parentRelationshipName = isPolymorphic ? pathElements[n].split('\\|')[0] : pathElements[n];//1.5+

                                if (!DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).containsKey(parentRelationshipName)) break;// -- parent relationship name doesn't exist.
                                
                                if (isPolymorphic 
                                    && DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName).size()>1
                                    && DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName).contains(pathElements[n].split('\\|')[1])){//1.5+
                                    
                                    parentSobjectTypeName = pathElements[n].split('\\|')[1];

                                } else {

                                    isPolymorphic=false;
                                    parentSobjectTypeName = DescribeHelper.getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName)[0];//1.5~
                                }
                            }
                        }
                    } else {
                        
                        if (DescribeHelper.getObjectFieldMap(sObjectType).containsKey(f) && !fieldsAdded.contains(f.toUpperCase())){
                            q+=','+String.escapeSingleQuotes(f);
                            fieldsAdded.add(f.toUpperCase()); 
                        }
                    }
                }
                q+=' from '+String.escapeSingleQuotes(sObjectType);
                q+=' where '+idFieldName+' in :recordIds';

                //[Removed for release] System.debug(LoggingLevel.ERROR,'q='+q);

                idToSObject = new Map<Id,SObject>(Database.query(q));                
            }
            if (idToSObject.isEmpty()) return recordIdToDynamicStrings;

            Map<String, Object> fieldsMap;

            Boolean addRequestData;//1.1+

            for (Id recordId : idToSObject.keySet()){
                
                recordIdToDynamicStrings.put(recordId,new List<String>());                
                
                o = idToSObject.get(recordId);

                //1.1+ Req Data is Required if the Operation is not a Merge or if it is a merge and the current Record is the Master Record
                addRequestData = (det != null && (det.DataOperationType__c == null || det.DataOperationType__c != Label.Picklist_Value_Data_Event_Data_Operation_Type_Merge || 
                                        (det.DataOperationType__c == Label.Picklist_Value_Data_Event_Data_Operation_Type_Merge && o.get('MasterRecordId')==null)))?true:false;

                fieldsMap = o.getPopulatedFieldsAsMap();

                if (String.isNotBlank(det.EndpointPathFormatString__c) && !endPointPathFormatStringFields.isEmpty()){
                    recordIdToDynamicStrings.get(recordId).add( formatString(fieldsAdded,endPointPathFormatStringFields,det.EndpointPathFormatString__c,fieldsMap,o,true) );
                } else recordIdToDynamicStrings.get(recordId).add('');

                if (String.isNotBlank(det.RequestFormat__c) && !requestFormatStringFields.isEmpty()){
                    if(addRequestData) recordIdToDynamicStrings.get(recordId).add( formatString(fieldsAdded,requestFormatStringFields,det.RequestFormat__c,fieldsMap,o,false) );//1.1~
                } else recordIdToDynamicStrings.get(recordId).add('');         
            
            }//recordId.

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'FormatStringHelper', 'buildDynamicStringsForDataEventType'); }
        return recordIdToDynamicStrings;
    }
    
    private static String formatString(Set<String> validFormatStringFields, /*Set<String> 1.12~*/ List<String> formatStringFields, String formatString, Map<String, Object> populatedFieldsMap, Sobject o, Boolean isUrlEncode){//1.5~
        if (validFormatStringFields.isEmpty()) return '';//1.5+

        String formattedString='';
        Boolean isJSON=false;
        List<Object> formatParameters = new List<Object>();

        try {
    
            List<String> pathElements;
            String fv;

            for (String f : formatStringFields){

                if (!validFormatStringFields.contains(f.toUpperCase())) continue;//1.5+

                try {
                    if (String.isNotBlank(f) && f.contains('.')){

                        pathElements = f.split('\\.');
                        Sobject p = o;

                        for (Integer n=0; n<pathElements.size();n++){
                            //1.5- if (n==pathElements.size()-1){
                            //1.5-     
                            //1.5-     fv = p==null ? '' :  getTypeFormattedValue(DescribeHelper.getSObjectTypeName(p.getSObjectType()),pathElements[n],p);//1.4+
                            //1.5-     //1.4- fv = (String)p.get(pathElements[n]);                                
                            //1.5- } else p = p.getSObject(pathElements[n]);

                            if (n==pathElements.size()-1){
                                
                                fv = p==null ? '' : getTypeFormattedValue(DescribeHelper.getSObjectTypeName(p.getSObjectType()),pathElements[n],p);//1.4+
                                //1.4- fv = (String)p.get(pathElements[n]);

                            } else p = (pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2) ? p.getSObject(pathElements[n].split('\\|')[0]) : p.getSObject(pathElements[n]);//1.5~
                        }

                    //1.3- } else fv = String.isNotBlank(f) && populatedFieldsMap.containsKey(f) ? (String)o.get(f) : '';
                    } else fv = String.isNotBlank(f) && populatedFieldsMap.containsKey(f) ? getTypeFormattedValue(DescribeHelper.getSObjectTypeName(o.getSObjectType()),f,o) : '';//1.3+

                    if(isUrlEncode) fv = EncodingUtil.urlEncode(fv, 'UTF-8');
                    formatParameters.add(fv);
                        
                } catch(Exception e){ formatParameters.add(''); }
            }

            formattedString = getJSONSafeFormatString(formatString,formatParameters);//1.8+

            //1.8- isJSON=false;

            //1.8- if (formatString.startsWith('{')){
            //1.8-     formatString = formatString.removeStart('{');
            //1.8-     formatString = formatString.removeEnd('}');
            //1.8-     isJSON = true;
            //1.8- }
        
            //1.8- formattedString = String.format(formatString,formatParameters);
            //1.8- if (isJSON) formattedString = '{'+formattedString+'}';

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'FormatStringHelper', 'formatString'); }
        return formattedString;
    }

    @TestVisible
    public static String getJSONSafeFormatString(String formatString, List<Object> formatParameters){//1.8+ 1.9~

        String formattedString='',jsonSafeFormatString='';

        try {

            for (Integer i=0; i<formatString.length(); i++){// escape { not succeeded by a numeric char, or } not preceded by a numeric char.
                if (formatString.substring(i,i+1)=='{'){
            
                    if (i==formatString.length()-1 || !formatString.substring(i+1,i+2).isNumeric()){
                        jsonSafeFormatString+='\'{\'';
                    } else {
                        jsonSafeFormatString+='{';
                    }
                } else if (formatString.substring(i,i+1)=='}'){
            
                    if (i==0 || !formatString.substring(i-1,i).isNumeric() && formatString.substring(i-1,i)!='}'){//1.10~
                        jsonSafeFormatString+='\'}\'';
                    } else {
                        jsonSafeFormatString+='}';
                    }
                } else {
                    jsonSafeFormatString+=formatString.substring(i,i+1); 
                }
            }
            
            formattedString = String.format(jsonSafeFormatString,formatParameters);


        } catch(Exception ex){ LogHelper.logExceptions(ex, 'FormatStringHelper', 'getJSONSafeFormatString'); }
        return formattedString;
    }

    private static String getTypeFormattedValue(String sot, String f, SObject o){//1.4+
        
        if (!o.getPopulatedFieldsAsMap().containsKey(f)) return '';

        Schema.DisplayType dt = DescribeHelper.getFieldDisplayType(sot, f);
        if (dt==null ) return '';
        else {
            
            switch on dt {
                when INTEGER {
                    Decimal d = (Decimal)o.get(f);
                    return String.valueOf(d.intValue());//1.0 => 1.
                }
                when DATE {
                    Date d = Date.valueOf(o.get(f));
                    Datetime convertedDt = Datetime.newInstance(d.year(), d.month(), d.day());
                    return convertedDt.format('yyyy-MM-dd');//<-- ISO format output.
                }
                when DATETIME {//1.6+
                    DateTime valDT = DateTime.valueOf(o.get(f)); //Expected Format = 'yyyy-mm-dd hh:mm:ss'
                    return valDT.formatGMT('yyyy-MM-dd\'T\'HH:mm:ssXXX');//<-- ISO GMT format output.
                }
                when else {
                    return String.valueOf(o.get(f));
                }
            }
        }
    }   
}