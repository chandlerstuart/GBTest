/**
* Class Name: Flow_DupeHandlerController
* @author: James Radcliffe
* @date: 02.04.2016
* @description: Controller for Flow_DupeHandler Component
* 

History

Version   Author        Date        Detail
***************************************************
1.0       J Radcliffe   12-06-19    Initial Developement
*/
public with sharing class Flow_DupeHandlerController {
    
    public class ObjectWrapper{
        @AuraEnabled
        public List<FieldWrapper> displayFields;
        @AuraEnabled
        public List<FieldWrapper> compareFields;
        @AuraEnabled
        public String recordName;
        @AuraEnabled
        public String recordId;
    }
   
    public class FieldWrapper{
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public Object fieldValue;
        @AuraEnabled
        public String fieldType; 
    }
    
    @AuraEnabled 
    public static List<ObjectWrapper> getRecordData(String sObjectType, List<String> displayFields, List<String> compareFields, String nameField, List<Id> recordIds){
        
        try{
            List<String> queryFields = new List<String>();
            for(String df : displayFields){
                system.debug('displayField:'+df);
                if(df != null && df != '' && !queryFields.contains(df)) queryFields.add(df);
            }
            if(!queryFields.contains(nameField) && nameField != null && nameField != '') queryFields.add(nameField);
            for(String cf : compareFields){
                system.debug('compareField:'+cf);
                if(cf != null && cf != '' && !queryFields.contains(cf)) queryFields.add(cf);
            }
            
            List<ObjectWrapper> wrapperList = new List<ObjectWrapper>();
            
            //Retrieve Field Definitions
            //https://salesforce.stackexchange.com/questions/218982/why-is-schema-describesobjectstypes-slower-than-schema-getglobaldescribe
            SObjectType sType = ((SObject)(Type.forName('Schema.'+sObjectType).newInstance())).getSObjectType();
            DescribeSObjectResult dr = sType.getDescribe();
            if(!dr.isAccessible()) throw new AuraHandledException('You do not have access to the '+sObjectType+' Object. Please contact your System Administrator if you require assistance');
            Map<String,Schema.SObjectField> fieldMap = dr.fields.getMap();
            
            //Build Query String
            String query = 'SELECT ';
            for(String qField : queryFields){
                if(qField != null && qField != '')query= query+qField+',';
            }
            query = query.trim();
            query = query.removeEnd(',');
            query=query+' FROM '+sObjectType+' Where Id In:recordIds';
            
            system.debug('Object Query: '+query);
            
            //Query, loop through records and build response wrapper
            for(sObject record : database.query(query)){
                ObjectWrapper ow = new ObjectWrapper();
                ow.recordName = (String)record.get(nameField);
                ow.displayFields = new List<FieldWrapper>();
                ow.compareFields = new List<FieldWrapper>();
                ow.recordId = record.Id;
                for(String field : queryFields){
                    if(fieldMap.containsKey(field)){
                        FieldWrapper fw = new FieldWrapper();
                        fw.fieldLabel = fieldMap.get(field).getDescribe().getLabel();
                        fw.fieldName = fieldMap.get(field).getDescribe().getName();
                        fw.fieldValue = record.get(field);
                        fw.fieldType = String.valueOf(fieldMap.get(field).getDescribe().getType());
                        if(displayFields.contains(field)) ow.displayFields.add(fw);
                        if(compareFields.contains(field)) ow.compareFields.add(fw);
                    }
                }
                wrapperList.add(ow);
            }
            
            return wrapperList;
            
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'Flow_DupeHandlerController', 'getData');
            throw new AuraHandledException('There has been an error: '+e.getMessage());
        }
    }
    
}