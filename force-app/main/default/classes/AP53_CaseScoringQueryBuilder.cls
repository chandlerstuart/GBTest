/**
   @Author: Recuerdo Bregente
   @name: AP53_CaseScoringQueryBuilder
   @CreateDate: 05.17.2016
   @Description: Creates the query for AP11_CaseScoringBatch.
   @Version <1.0>
*/
public with sharing class AP53_CaseScoringQueryBuilder{
    
    // Used for logging --- Added by Dee 5/17
    public static final String CLASS_NAME = 'AP53_CaseScoringQueryBuilder';
    
    public static void buildCaseScoringQuery(){
        List<Error_Log__c> logs = new List<Error_Log__c>();
    
    
        try{
            Set<Id> rtIds = new Set<Id>();
            Set<String> fieldNames = new Set<String>();
            Set<String> fieldApis = new Set<String>{'casenumber', 'accountid', 'type', 'status', 'origin', 'businessHoursId', 'recordtypeid', 'priority', 'points__c',
                                                    'casescoreapplieddate__c', 'description', 'subcategory__c', 'booking__c', 'category__c'};
            
            for(RecordType rt : [SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType = 'Case']){
                rtIds.add(rt.Id);
            }
            
            for(LeadScoringRule__c lsr : [SELECT Id, FieldLabel__c, Name FROM LeadScoringRule__c WHERE RecordType__c IN :rtIds]){
                fieldNames.add(lsr.FieldLabel__c);
            }
            
            Map<String, Schema.SObjectField> ObjectFieldMap =
                Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
            
            for(String key : ObjectFieldMap.KeySet()){
                
                if(fieldNames.contains(ObjectFieldMap.get(key).getDescribe().getLabel())){
                    fieldApis.add(key);
                }
            }
            
            if(fieldApis.contains('id')){
               fieldApis.remove('id'); 
            }
            
            String query = 'SELECT ';
            
            for(String fieldApi : fieldApis){
                query += fieldApi + ', ';
            }
            
            query += 'Id FROM CASE WHERE Status != \'Closed\'' +
                            ' AND (RecordType.Name = \'Amendment\' OR RecordType.Name = \'Complaint\' OR RecordType.Name = \'Service Case\')';
                           //' AND (RecordType.Name = \'Amendment\' OR RecordType.Name = \'Complaint\' OR RecordType.Name = \'Service Case\' OR RecordType.Name = \'Admin\')';
            
            System.debug('Query: ' + query);
            
            
            
            Database.executeBatch(new AP11_CaseScoringBatch(query), 200);
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'buildCaseScoringQuery()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
}