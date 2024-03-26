@isTest(seealldata = False)
public class AP53_CaseScoringQueryBuilder_Test{
    @testSetup static void createRules(){
        LeadScoringRule__c ld = AP23_TestDataFactory.createScoringRules(true, ApplicationConstant.SERVICE_CASE, 'Description', ApplicationConstant.CASE_SOBJECTTYPE, ApplicationConstant.SCORING_STARTSWITH, 'c', 10);
        insert ld;
        
        LeadScoringRule__c ld2 = AP23_TestDataFactory.createScoringRules(true, ApplicationConstant.CASE_TYPE_AMENDMENT, 'Origin', ApplicationConstant.CASE_SOBJECTTYPE, ApplicationConstant.SCORING_CONTAINS, ApplicationConstant.CASE_ORIGIN_WEB, 19);
        insert ld2;
        
        LeadScoringRule__c ld3 = AP23_TestDataFactory.createScoringRules(true, ApplicationConstant.CASETYPE_ADMIN, 'id', ApplicationConstant.CASE_SOBJECTTYPE, ApplicationConstant.SCORING_CONTAINS, '0', 1);
        insert ld3;
        
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        insert accList;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(2, ApplicationConstant.RecommendationStage, accList[0]);
        insert oppList;      
        
        List<Booking__c> bkList = AP23_TestDataFactory.createBooking(200, accList[0], oppList[0].Id);
        insert bkList;             
        
        List<Case> csList = AP23_TestDataFactory.createCase(2, accList[0]);
        csList[0].Description = 'c'; //10 points
        csList[0].Type = ApplicationConstant.SERVICE_CASE;
        csList[0].Booking__c = bkList[0].Id;
        csList[1].Origin = ApplicationConstant.CASE_ORIGIN_WEB; //19 points;
        csList[1].Type = ApplicationConstant.CASE_TYPE_AMENDMENT;
        csList[1].Booking__c = bkList[1].Id;
        insert csList;
    }
    
    @isTest static void testScoringBuilder(){
        List<Case> csList = [SELECT Id, Description, Origin, Type, Points__c, Priority FROM CASE ORDER BY CREATEDDATE LIMIT 2];
        System.assertEquals(2, csList.size());
        
        List<LeadScoringRule__c> ldquery = [SELECT Id, FieldLabel__c, Name FROM LeadScoringRule__c ORDER BY CreatedDate LIMIT 3];
        System.assertEquals(3, ldquery.size());
        
        test.starttest();
        AP53_CaseScoringQueryBuilder.buildCaseScoringQuery();   
        test.stopTest();
        
        List<Case> csListUpdated = [SELECT Id, Description, Origin, Type, Points__c, Priority FROM CASE ORDER BY CREATEDDATE LIMIT 2];
        System.assertEquals(2, csListUpdated.size());        
    }
    
    @isTest static void tstNegative(){
        List<LeadScoringRule__c> ldquery = [SELECT Id, FieldLabel__c, Name FROM LeadScoringRule__c ORDER BY CreatedDate LIMIT 4];
        System.assertEquals(3, ldquery.size());
        
        //Create error
        LeadScoringRule__c ld4 = AP23_TestDataFactory.createScoringRules(true, ApplicationConstant.CASE_TYPE_AMENDMENT, 'x123', ApplicationConstant.CASE_SOBJECTTYPE, ApplicationConstant.SCORING_CONTAINS, ApplicationConstant.CASE_ORIGIN_WEB, 2147483647);
        insert ld4;
  
        List<LeadScoringRule__c> ldquery2 = [SELECT Id, FieldLabel__c, Name FROM LeadScoringRule__c ORDER BY CreatedDate LIMIT 4];
        System.assertEquals(4, ldquery2.size());
        
        test.starttest();
        try{
            List<Case> csList = [SELECT Id, OwnerId, Status, Points__c FROM CASE LIMIT 20];
            Group gp = [SELECT Id FROM GROUP LIMIT 1];
            for(Case cs : csList){
                cs.OwnerId = gp.Id;
                cs.Status = ApplicationConstant.CASE_STATUS_CLOSED;
            }
            AP53_CaseScoringQueryBuilder.buildCaseScoringQuery(); 
        }catch(Exception e){
            //System.assertEquals('blah', e.getMessage());
        }  
        test.stopTest();
    }
    
}