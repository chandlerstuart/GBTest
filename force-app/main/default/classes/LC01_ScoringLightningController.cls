/*
Name:  LC01_ScoringPrioritisationLightningController.cls
Copyright © 2016  Golf Breaks Offshore Team
======================================================
======================================================
Purpose: Server-side controller of Lead Scoring Rule
-------
Lightning Component Controller
======================================================
======================================================
History
------- 
Ver. Author         Date        Detail
1.0  Recuerdo Bregente       2016-02-17  Initial development.
2.0  Majoy Maliñana          2016-03-22  Updated
3.0  Merari Cebrian          2016-05-02  Updated getLeadScoringRules() - lsrList query to Order By RecordType__c, FieldLabel__c, Points__c
*/
public with sharing class LC01_ScoringLightningController{
    public class ReturnItem{
        @AuraEnabled
        public Object returnObj {get; set;}
        @AuraEnabled
        public String message {get; set;}
        @AuraEnabled
        public Integer statusCode {get; set;}
    }
    
    @AuraEnabled
    public static ReturnItem getfieldInformation(String objName){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = 'Fields retrieved successfully!';
       
       List<String> fieldList = new List<String>();
       
       try{
           Schema.SObjectType t = Schema.getGlobalDescribe().get(objName);
           Map<String,Schema.SObjectField> mfields = t.getDescribe().fields.getMap();
        
           for(String key:mfields.keyset()){
               if(mfields.get(key).getDescribe().isCreateable() || mfields.get(key).getDescribe().isUpdateable() || mfields.get(key).getDescribe().isAccessible()){
                   fieldList.add(mfields.get(key).getDescribe().getLabel());
               }
           }
           
           fieldList.sort();
       
           retItem.returnObj = fieldList;
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = 'Internal Error occurred. Please contact Administrator. \n' + e.getMessage();
       }
       
       return retItem;
    }
    
    @AuraEnabled
    public static ReturnItem getRecordTypeInformation(String objName){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = 'Record Types retrieved successfully!';
       
       try{
           Schema.DescribeSObjectResult objSchema = Lead.SObjectType.getDescribe();
           if(objName.equals('Case')){
               objSchema = Case.SObjectType.getDescribe();
           }
           
           Map<Id,Schema.RecordTypeInfo> recordTypeInfos = objSchema.getRecordTypeInfosByID();
           
           List<String> recordNames = new List<String>();
           for(RecordType recType : [SELECT Id,Name FROM RecordType WHERE SobjectType=:objName AND IsActive = TRUE]){
               if (recordTypeInfos.get(recType.Id).isAvailable()){
                   recordNames.add(recType.Name);
               }
           }
           
           retItem.returnObj = recordNames;
           
           if(recordNames.isEmpty()){
               retItem.statusCode = 400;
               retItem.message = 'Sorry! You were not assigned of any Record Type for '+objName;
           }
           
       }catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = 'Internal Error occurred. Please contact Administrator. \n' + e.getMessage();
       }
       
       return retItem;
    }
    
    @AuraEnabled
    public static ReturnItem updateScoringRule(LeadScoringRule__c lsrObject){
       
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = 'Successfully Updated!';
       
       try{
           List<RecordType> objRT = [SELECT Id,Name FROM RecordType WHERE IsActive = TRUE AND Name = :lsrObject.RecordType__c LIMIT 1];
           
           lsrObject.Record_Type_Name__c = lsrObject.RecordType__c;
           if(!objRT.isEmpty()){
               lsrObject.RecordType__c = objRT[0].Id;
           }
           
           retItem = validateScoringRule(lsrObject, retItem);
           
           if(retItem.statusCode == 200){
               
               Database.update(lsrObject);
           }
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = 'Internal Error occurred. Please contact Administrator. \n' + e.getMessage();
       }
       
       return retItem;
       
    }
    
    @AuraEnabled
    public static ReturnItem saveScoringRule(LeadScoringRule__c lsrObject, String ruleType){
       
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = 'Successfully Saved!';
       
       try{
           String recordName = 'Scoring Rules for ' + ruleType;
           
           if(ruleType.equals('Case')){
               recordName += 's';
           }
           List<RecordType> rt = [SELECT Id,Name FROM RecordType WHERE SobjectType='LeadScoringRule__c' AND Name = :recordName LIMIT 1];
           lsrObject.RecordTypeId = rt[0].Id;
           lsrObject.Id = null;
           
           List<RecordType> objRT = [SELECT Id,Name FROM RecordType WHERE SobjectType=:ruleType AND IsActive = TRUE AND Name = :lsrObject.RecordType__c LIMIT 1];
           
           lsrObject.Record_Type_Name__c = lsrObject.RecordType__c;
           if(!objRT.isEmpty()){
               lsrObject.RecordType__c = objRT[0].Id;
           }
           
           retItem = validateScoringRule(lsrObject, retItem);
           
           if(retItem.statusCode == 200){
               Database.insert(lsrObject);
           }
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = 'Internal Error occurred. Please contact Administrator. \n' + e.getMessage();
       }
       
       return retItem;
       
    }
    
    @AuraEnabled
    public static ReturnItem getLeadScoringRules(String objName){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = 'Scoring rules retrieved successfully!';
       
       try{
           String recordName = 'Scoring Rules for ' + objName;
           
           if(objName.equals('Case')){
               recordName += 's';
           }
           
           List<RecordType> rts = [SELECT Id,Name FROM RecordType WHERE SobjectType='LeadScoringRule__c' AND Name = :recordName LIMIT 1];
           System.debug('getLeadScoringRules --- rts[0].Id: ' + rts[0].Id);
           
           Map<Id, RecordType> objRT = new Map<Id, RecordType>([SELECT Id,Name FROM RecordType WHERE SobjectType=:objName AND IsActive = TRUE]);
           System.debug('getLeadScoringRules --- objRT.keySet(): ' + objRT.keySet());
           
           List<LeadScoringRule__c> lsrList = new List<LeadScoringRule__c>();
           
           if(!rts.isEmpty()){
               for(LeadScoringRule__c lsr : [SELECT Id,Name,Active__c,FieldLabel__c,Operator__c,RecordTypeId,RecordType__c,Value__c,Points__c,MinimumValue__c,MaximumValue__c 
                                               FROM LeadScoringRule__c WHERE RecordTypeId = :rts[0].Id AND RecordType__c IN :objRT.keySet() 
                                               Order By RecordType__c, FieldLabel__c, Points__c]){
                   
                   lsr.RecordType__c = objRT.get(lsr.RecordType__c).Name;
                   lsrList.add(lsr);
               }
                
           }
           
           retItem.returnObj = lsrList;
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = 'Internal Error occurred. Please contact Administrator. \n' + e.getMessage();
       }
       
       return retItem;
    }
    
    @AuraEnabled
    public static ReturnItem deleteLeadScoringRules(Id lsrId){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = 'Delete Successful!';
       
       try{
           List<LeadScoringRule__c> lsr = [SELECT Id FROM LeadScoringRule__c WHERE Id = :lsrId LIMIT 1];
           Database.delete(lsr);
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = 'Internal Error occurred. Please contact Administrator. \n' + e.getMessage();
       }
       
       return retItem;
    }
    
    public static ReturnItem validateScoringRule(LeadScoringRule__c lsrObject, ReturnItem retItem){
           System.debug('validateScoringRule --- Start');
           Map<Id, RecordType> objRT = new Map<Id, RecordType>([SELECT Id,Name FROM RecordType WHERE IsActive = TRUE AND 
                                                                   (SobjectType = 'Lead' OR SobjectType = 'Case')]);
           
           Map<Id, LeadScoringRule__c> lsrToCheck = new Map<Id, LeadScoringRule__c>([SELECT Id, Name FROM LeadScoringRule__c WHERE 
                                                   RecordTypeId = :lsrObject.RecordTypeId AND Name = :lsrObject.Name AND 
                                                   RecordType__c = :lsrObject.RecordType__c AND RecordType__c IN :objRT.keySet()]);
                                                   
           System.debug('lsrToCheck: ' + lsrToCheck);
           if(lsrObject.Id != null && lsrToCheck.containsKey(lsrObject.Id)){
              lsrToCheck.remove(lsrObject.Id);
           }                             
                                                 
           if(!lsrToCheck.isEmpty()){
               retItem.statusCode = 400;
               retItem.message = 'Scoring Rule with the same Rule Type, Name, and Record Type already exists.';
           }
           else{
               lsrToCheck = new Map<Id, LeadScoringRule__c>([SELECT Id FROM LeadScoringRule__c WHERE RecordType__c = :lsrObject.RecordType__c AND
                               FieldLabel__c = :lsrObject.FieldLabel__c AND Operator__c = :lsrObject.Operator__c AND 
                               ((Operator__c != 'less than/greater than' AND Value__c = :lsrObject.Value__c) OR 
                               (Operator__c = 'less than/greater than' AND MinimumValue__c = :lsrObject.MinimumValue__c AND
                               MaximumValue__c = :lsrObject.MaximumValue__c)) AND RecordType__c IN :objRT.keySet()]);
                                      
               if(lsrObject.Id != null && lsrToCheck.containsKey(lsrObject.Id)){
                  lsrToCheck.remove(lsrObject.Id);
               }
               
               
               if(!lsrToCheck.isEmpty()){
                   retItem.statusCode = 400;
                   retItem.message = 'Scoring Rule with the same Record Type, Field, Operator, and Value already exists.';
               }
           }
           
           System.debug('validateScoringRule --- End, return = ' + retItem);
           return retItem;
    }
}