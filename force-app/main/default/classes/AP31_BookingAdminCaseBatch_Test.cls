@isTest
public class AP31_BookingAdminCaseBatch_Test{
    
    @testSetUp static void setUpData(){
        User apiUser = [SELECT Id FROM User where Name=: ApplicationConstant.USER_NAME_API_USER LIMIT 1];
        Integer count = [SELECT count() FROM User where Name=: ApplicationConstant.USER_NAME_API_USER LIMIT 1];
        System.assertEquals(1, count);
        QueueId__c que = new QueueId__c(User_Id__c = String.valueOf(apiUser.Id)  );
        insert que;
        
        List<Account> acc = AP23_TestDataFactory.createAccount(1);
        insert acc;
        
        List<Opportunity> opp = AP23_TestDataFactory.createOpportunity(200, ApplicationConstant.RECOMMENDATIONSTAGE, acc.get(0));
        for(Opportunity op : opp){
            op.OwnerId = UserInfo.getUserId();
        }
        insert opp;
        
        List<booking__c> testbooking = AP23_TestDataFactory.createBooking(200,acc[0], opp[0].ID);
            for(Integer i=0; i<200; i++){
                testbooking[i].AgentTaskName__c = 'Create Admin Case '+i;
                testbooking[i].AgentAttentionRequired__c = true;   
                testbooking[i].TECH_Opportunity__c = opp[i].Id;
                testbooking[i].AgentTaskDueDate__c = Date.today();
                testbooking[i].Travel_Date__c = Date.today().addDays(7);
                testBooking[i].Nights__c = 7;
            }
        insert testbooking; 
    }
    

    
    @isTest static void testBkWithCase() {
        Account acc = [SELECT Id FROM ACCOUNT LIMIT 1];    
        String cancelled = 'Cancellation';
        Date todayMin1 = System.Today().addDays(-1);
        String query = 'SELECT AgentTaskName__c, AgentTaskDueDate__c, AgentAttentionRequired__c, Account__c, Account__r.PersonContactId, TECH_Opportunity__r.StageName, TECH_Opportunity__r.OwnerId FROM Booking__c'+
                        ' WHERE'+
                        ' AgentTaskName__c <> \'\' AND AgentAttentionRequired__c = true AND AgentTaskDueDate__c <= Today AND Status__c !=:cancelled AND TravelReturnDate__c >=: todayMin1';
                        //' AgentTaskName__c <> \'\' AND AgentAttentionRequired__c = true AND AgentTaskDueDate__c <= Today AND Status__c !=:cancelled';
        
        List<Booking__c> checkList = Database.query(query);

        system.assertNotEquals(true, checkList.isEmpty());


        List<Booking__c> bkList = [SELECT AgentTaskName__c, AgentTaskDueDate__c, AgentAttentionRequired__c, Account__c, Account__r.PersonContactId, TECH_Opportunity__r.StageName, TECH_Opportunity__r.OwnerId FROM Booking__c ORDER BY CreatedDate LIMIT 200];       
        List<Case> csList = AP23_TestDataFactory.createCase(200, acc.Id, bkList[0].Id);
        for(Integer i = 0; i<200; i++){
            csList[i].Type = ApplicationConstant.CASETYPE_ADMIN;
            csList[i].Booking__c = bkList[i].Id;
            csList[i].TaskType__c = ApplicationConstant.CASETASKTYPE_CUSTOMER;
            csList[i].OwnerId = UserInfo.getUserId();
        }
        insert csList;

        Test.startTest();
        AP31_BookingAdminCaseBatch BookingAdminCase= new AP31_BookingAdminCaseBatch();
        Database.executeBatch(BookingAdminCase);
        Test.stopTest();
        
        Integer caseCount = [SELECT COUNT() FROM CASE WHERE TYPE =: ApplicationConstant.CASETYPE_ADMIN AND Booking__c IN: bkList];
        System.assertEquals(200, caseCount);
    }
    
    @isTest static void testBkWithCaseTaskNull() {
        Account acc = [SELECT Id FROM ACCOUNT LIMIT 1];        
        List<Booking__c> bkList = [SELECT AgentTaskName__c, AgentTaskDueDate__c, AgentAttentionRequired__c, Account__c, Account__r.PersonContactId, TECH_Opportunity__r.StageName, TECH_Opportunity__r.OwnerId FROM Booking__c ORDER BY CreatedDate LIMIT 200];       
        List<Case> csList = AP23_TestDataFactory.createCase(200, acc.Id, bkList[0].Id);
        for(Integer i = 0; i<200; i++){
            csList[i].Type = ApplicationConstant.CASETYPE_ADMIN;
            csList[i].Booking__c = bkList[i].Id;
            csList[i].TaskType__c = null;
            csList[i].OwnerId = UserInfo.getUserId();
        }
        insert csList;

        Test.startTest();
        AP31_BookingAdminCaseBatch BookingAdminCase= new AP31_BookingAdminCaseBatch();
        Database.executeBatch(BookingAdminCase);
        Test.stopTest();
        
        Integer caseCount = [SELECT COUNT() FROM CASE WHERE TYPE =: ApplicationConstant.CASETYPE_ADMIN AND Booking__c IN: bkList];
        System.assertEquals(200, caseCount);
    }
}