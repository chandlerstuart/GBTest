/*
Name:  LC02_MappingLightningController.cls
Copyright © 2016  Golf Breaks Offshore Team
======================================================
======================================================
Purpose:
-------
Lightning Component Controller
======================================================
======================================================
History
------- 
Ver. Author         Date        Detail
1.0  Recuerdo Bregente       2016-02-17  Initial development.
2.0  Majoy Maliñana          2016-03-22  Updated
*/
public class LC02_MappingLightningController{
    public class ReturnItem{
        @AuraEnabled
        public Object returnObj {get; set;}
        @AuraEnabled
        public String message {get; set;}
        @AuraEnabled
        public Integer statusCode {get; set;}
    }
        
    @AuraEnabled
    public static ReturnItem saveScoreMapping(LeadScoreMapping__c lsrObject){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = System.label.CL00003;
       Boolean errorExists = false;
       try{
           List<LeadScoreMapping__c> lsmToCheck = [SELECT Id FROM LeadScoreMapping__c WHERE
                                                   Name =:lsrObject.Name AND RuleType__c =:lsrObject.RuleType__c LIMIT 1];
           if(!lsmToCheck.isEmpty()){
               retItem.statusCode = 400;
               retItem.message = System.label.CL00001;
               errorExists = true;
           }
           
           String fieldType;
           if(!errorExists && lsrObject.RuleType__c.equals('Lead')){
               lsmToCheck = [SELECT Id FROM LeadScoreMapping__c WHERE
                        LeadRating__c =:lsrObject.LeadRating__c AND RuleType__c =:lsrObject.RuleType__c LIMIT 1];
               
               fieldType = 'Lead Rating('+lsrObject.LeadRating__c+')';
               
           }
           else{
               if(!errorExists){
                   lsmToCheck = [SELECT Id FROM LeadScoreMapping__c WHERE
                            CasePriority__c =:lsrObject.CasePriority__c AND RuleType__c =:lsrObject.RuleType__c LIMIT 1];
                            
                   fieldType = 'Case Priority('+lsrObject.CasePriority__c+')';
               }
           }
           
           if(!errorExists && !lsmToCheck.isEmpty()){
               retItem.statusCode = 400;
               retItem.message = fieldType + ' ' + System.label.CL00005;
               errorExists = true;
           }
           
           if(!errorExists){
               lsmToCheck = [SELECT Id, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c FROM LeadScoreMapping__c WHERE
                               RuleType__c =:lsrObject.RuleType__c];
           }
           
           if(!errorExists && !lsmToCheck.isEmpty()){
               for(LeadScoreMapping__c lsmRecord : lsmToCheck){
                   if(lsrObject.LeadScoreMinimumValue__c  <= lsmRecord.LeadScoreMaximumValue__c &&
                       lsmRecord.LeadScoreMinimumValue__c <= lsrObject.LeadScoreMaximumValue__c){
                       retItem.statusCode = 400;
                       retItem.message = System.label.CL00006;
                       errorExists = true;
                       break;
                   }
               }
           }
           
           if(!errorExists){
               Database.insert(lsrObject);
           }
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = System.label.CL00002 + '\n' + e.getMessage();
       }
       return retItem;
    }
    
    @AuraEnabled
    public static ReturnItem getScoreMappings(String objName){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       
       try{
           List<LeadScoreMapping__c> lsmList = [SELECT Id, Name, RuleType__c, LeadRating__c, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c, CasePriority__c
                   FROM LeadScoreMapping__c WHERE RuleType__c = :objName LIMIT 50000];
           retItem.returnObj = lsmList;
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = System.label.CL00002 + '\n' + e.getMessage();
       }
       
       return retItem;
    }
    
    @AuraEnabled
    public static ReturnItem deleteLeadScoreMapping(Id lsmId){
       ReturnItem retItem = new ReturnItem();
       retItem.statusCode = 200;
       retItem.message = System.label.CL00004;
       
       try{
           LeadScoreMapping__c lsm = [SELECT Id, Name FROM LeadScoreMapping__c WHERE Id = :lsmId LIMIT 1];
           Database.delete(lsm);
       }
       catch(Exception e){
           retItem.statusCode = 400;
           retItem.message = System.label.CL00002 + '\n' + e.getMessage();
       }
       
       return retItem;
    }
}