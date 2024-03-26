/*
Name: Flow_DynamicSearchController.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Controller class for Flow_DynamicSearch Component
======================================================
======================================================

Tests:

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-06-17  Initial development.
1.1  J Radcliffe   2019-09-09  Bug Fix - substring is case sensitive
1.2  J Radcliffe   2019-09-09  Bug Fix - sort in the order they are specified
*/
public with sharing class Flow_DynamicSearchController {
    
    @AuraEnabled
    public static Flow_DynamicSearchController.SearchResults startSearch(String sObjectType, Integer limitCount, String searchString, String soqlString, Boolean getFieldNames){
        
        try{

            List<Flow_DynamicSearchController.Column> columns = new List<Flow_DynamicSearchController.Column>();
            if(getFieldNames){
                columns = getDataColumns(sObjectType,soqlString);
            }
            
            List<sObject> data = searchData(soqlString,sObjectType,limitCount,searchString);
            return new Flow_DynamicSearchController.SearchResults(data,columns);        
        }catch(exception e){
            system.debug('Error Loading Component: '+e);
            PlatformLogManager.logExceptions(e, 'Flow_DynamicSearchController', 'startSearch');
            throw new AuraHandledException('Whoops! Something went wrong: '+ e.getMessage());
        }
        
    }

    public static List<sObject> searchData(String soqlString, String sObjectType, Integer limitCount, String searchString){
        
        //Cache the Where Clause before adjusting Soql String casing - Assuming the 'Where' will be 'Where', 'WHERE' or 'where'
        soqlString = soqlString.replace('Where', 'where');
        soqlString = soqlString.replace('WHERE', 'where');

        String whereClause = 'where '+soqlString.substringAfter('where');

        soqlString = soqlString.toLowerCase();
        String fieldNames = soqlString.substringBetween('select','from');
        
        if(whereClause == 'where ') whereClause = null;
        if(limitCount == null) limitCount = 50;

        List<List<sObject>> results = new List<List<sObject>>();
        String query;
        query = 'FIND \''+searchString+'\' IN ALL FIELDS RETURNING '+sObjectType+' ('+fieldNames+' ';
        if(whereClause != null){
            if(!whereClause.contains('Limit')){
                query = query +whereClause+' '+'Limit '+limitCount+')'; 
            }else{
                query = query +whereClause+')'; 
            }       
        }else{
            query = query + ' Limit '+limitCount+')';
        } 
        system.debug('SOSL Query: '+query);
        results = search.query(query);
        system.debug(results);
        return results[0];
    }

    public static List<Flow_DynamicSearchController.Column> getDataColumns(String sObjectType, String soqlString){

        String soqlUpper = soqlString.toUpperCase();//1.1+
        
        List<String> fieldNames = new List<String>();
        List<String> trimmedFields = new List<String>();
        fieldNames = soqlUpper.substringBetween('SELECT','FROM').split(',');//1.1~
        for(String fn : fieldNames){
            trimmedFields.add(fn.trim());
        }

        List<Flow_DynamicSearchController.Column> columns = new List<Flow_DynamicSearchController.Column>();
        
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectType).getDescribe().fields.getMap();
        
        Integer count = 0;
        Map<String,schema.describefieldresult> fieldNamesWithResults = new Map<String,schema.describefieldresult>();//1.3+
        for(Schema.SObjectField sfield : fieldMap.Values()){
            schema.describefieldresult dfield = sfield.getDescribe();
            fieldNamesWithResults.put(dfield.getName().toUpperCase().trim(),dfield);
            /*if(trimmedFields.contains(dfield.getName().toUpperCase().trim())){//1.1~//1.3-
                columns.add(new Column(String.valueOf(dfield.getType()),dfield.getLabel(),dfield.getName()));
                count = count+1;
                if(count>=fieldNames.size()) break;
            } */
        }
        for(String field : trimmedFields){//1.3+
            if(!fieldNamesWithResults.containsKey(field)) continue;
            schema.describefieldresult dfield = fieldNamesWithResults.get(field);
            columns.add(new Column(String.valueOf(dfield.getType()),dfield.getLabel(),dfield.getName()));
        }
        return columns;
    }

    public class SearchResults{
        @AuraEnabled
        public List<Column> columns;
        @AuraEnabled
        public List<sObject> data;

        public SearchResults(List<sObject> data, List<Flow_DynamicSearchController.Column> columns){
            this.columns = columns;
            this.data = data;
        }
    }

    public class Column{
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String label;

        //@AuraEnabled
        //public Boolean sortable;

        public Column(String type, String label, String name){
            this.fieldName = name;
            this.type = type;
            this.label = label;
            //this.sortable = true;
        }
    }

}