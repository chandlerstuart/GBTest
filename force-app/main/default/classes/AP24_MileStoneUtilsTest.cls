/**
* Class Name: AP24_MileStoneUtilsTest
* @description: Test class for AP24_MileStoneUtils
*/
@isTest(seealldata=false)
public class AP24_MileStoneUtilsTest{
    /*@testSetUp static void setUpData(){
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        database.insert(accList);
        
        List<Opportunity> opptyList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        database.insert(opptyList);

        List<Booking__c> bkList = AP23_TestDataFactory.createBooking(20, accList[0].Id , opptyList[0].Id);
        database.insert(bkList);
        
        BusinessHours businesshrs = [Select ID,Name from BusinessHours Where Name = 'Default'];

        List<case> caseList = AP23_TestDataFactory.createCase(20, accList[0]);
        for(Integer i=0; i<20; i++){
            caseList[i].BusinessHoursId = businesshrs.id;
            caseList[i].Status = ApplicationConstant.CASE_STATUS_INPROGRESS;
            caseList[i].Type = ApplicationConstant.COMPLAINT;
            caseList[i].Origin = ApplicationConstant.CASE_ORIGIN;
            caseList[i].SubCategory__c =   ApplicationConstant.COMPLAINT_SUBCATEGORY_ONSITE;  
            caseList[i].Category__c = ApplicationConstant.COMPLAINT_CATEGORY_ONSITE;
        }
        database.insert(caseList);
        
        Case casRec = AP23_TestDataFactory.createCase(1,accList[0])[0];
        casRec.Department__c = 'Product';
        database.insert(casRec);
        
    }*/
    
    static testmethod void test() {
        List<String> mstoneTypeList = new List<String>();
        mstoneTypeList.add(ApplicationConstant.MILESTONE_RESOLUTION_TIME);
        mstoneTypeList.add(ApplicationConstant.MILESTONE_ABTA_RESOLUTION);
        mstoneTypeList.add(ApplicationConstant.MILESTONE_FIRST_RESPONSE);
        mstoneTypeList.add(ApplicationConstant.MILESTONE_INITIAL_RESPONSE_ABTA);
        
        List<MilestoneType> stoneList = [SELECT Id FROM MileStoneType WHERE NAME IN: mstoneTypeList];
       
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        database.insert(accList);
        
        List<Opportunity> opptyList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        database.insert(opptyList);

        List<Booking__c> bkList = AP23_TestDataFactory.createBooking(20, accList[0].Id , opptyList[0].Id);
        database.insert(bkList);
       // System.assertEquals(20, [SELECT Count() FROM Case]);
        
        BusinessHours businesshrs = [Select ID,Name from BusinessHours Where Name = 'Default'];

        List<case> caseList = AP23_TestDataFactory.createCase(20, accList[0]);
        for(Integer i=0; i<20; i++){
            caseList[i].BusinessHoursId = businesshrs.id;
            caseList[i].Status = ApplicationConstant.CASE_STATUS_INPROGRESS;
            caseList[i].Type = ApplicationConstant.COMPLAINT;
            caseList[i].Origin = ApplicationConstant.CASE_ORIGIN;
            caseList[i].SubCategory__c =   ApplicationConstant.COMPLAINT_SUBCATEGORY_ONSITE;  
            caseList[i].Category__c = ApplicationConstant.COMPLAINT_CATEGORY_ONSITE;
            caseList[i].Opportunity__c = opptyList[0].Id;
        }
        database.insert(caseList);
        //System.assertEquals(20, [SELECT Count() FROM Case]);
       
       Set<Id> mtype = new Set<Id>();
       for(MileStoneType mt : stoneList){
           mtype.add(mt.Id);
       }

            
       test.startTest();
       List<Case> csList = [SELECT ID, CaseNumber, Status, Type, Origin, SubCategory__c, Category__c, Booking__c, Entitlement.Name, MilestoneStatus FROM CASE WHERE TYPE =: ApplicationConstant.COMPLAINT LIMIT 20];
       Set<Id> csId = new Set<Id>();
       for(Case cas : csList){
           csId.add(cas.Id);
       }
       System.assertEquals(20, csList.size());
 
       AP24_MileStoneUtils.CompleteCaseMileStone(mtype, csList);
       test.stopTest();
    }
}