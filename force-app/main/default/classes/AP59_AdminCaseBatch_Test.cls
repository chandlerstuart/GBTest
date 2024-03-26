@isTest
public class AP59_AdminCaseBatch_Test{
    
    @testSetUp static void setUpData(){
        User apiUser = [SELECT Id FROM User where Name=: ApplicationConstant.USER_NAME_API_USER LIMIT 1];
        Integer count = [SELECT count() FROM User where Name=: ApplicationConstant.USER_NAME_API_USER LIMIT 1];
        System.assertEquals(1, count);
        QueueId__c que = new QueueId__c(User_Id__c = String.valueOf(apiUser.Id)  );
        insert que;
        
        List<Account> acc = AP23_TestDataFactory.createAccount(200);
        insert acc;
        
        List<Opportunity> opp = AP23_TestDataFactory.createOpportunity(200, ApplicationConstant.RECOMMENDATIONSTAGE, acc.get(0));
        Integer itr = 0;
        for(Opportunity op : opp){
            op.AccountId = acc[itr].Id;
            op.OwnerId = UserInfo.getUserId();
            itr++;
        }
        insert opp;
        

        List<booking__c> testbooking = AP23_TestDataFactory.createBooking(200, acc[0], opp[0].ID);
            for(Integer i=0; i<200; i++){
                testbooking[i].Account__c = acc[i].Id;
                testbooking[i].AgentTaskName__c = 'Create Admin Case '+i;
                testbooking[i].AgentAttentionRequired__c = true;   
                testbooking[i].TECH_Opportunity__c = opp[i].Id;
                testbooking[i].AgentTaskDueDate__c = Date.today();
                testbooking[i].Has_Admin_Case_To_Close__c = TRUE;
            }
        insert testbooking; 

        List<Case> csList = AP23_TestDataFactory.createCase(200, acc[0].Id, testbooking[0].Id);
        for(Integer iz=0; iz<200; iz++){
            csList[iz].Type = ApplicationConstant.CASETYPE_ADMIN;
            csList[iz].AccountId = acc[iz].Id;
            csList[iz].Booking__c = testbooking[iz].Id;      
        }           
        Database.Insert(csList, FALSE);
        
        List<Task> tskList = AP23_TestDataFactory.createTask(200, csList[0]);
        List<Expected_Payment__c> expList = AP23_TestDataFactory.createExpectedPayment(200, testBooking[0], ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, 0);
        for(Integer ix=0; ix<200; ix++){
            tskList[ix].WhatId = csList[ix].Id;
            expList[ix].Booking__c = testBooking[ix].Id;
            if(Math.mod(ix,2)==0){
                expList[ix].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT;
                tskList[ix].Subject = ApplicationConstant.GETINITIALDEPOSIT;
            }else if((Math.mod(ix,3)==0)){
                expList[ix].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT;  
                tskList[ix].Subject = ApplicationConstant.GETDEPOSITBALANCE;
            }else{
                expList[ix].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLBALANCE;
				tskList[ix].Subject = ApplicationConstant.GETFINALBALANCE;                
            }
        }
        Database.Insert(expList, FALSE);        
        Database.Insert(tskList, FALSE);             
    }
    

    
    @isTest static void testBkWithCase() {
        Test.startTest();
        AP59_AdminCaseBatch BookingAdminCase= new AP59_AdminCaseBatch();
        Database.executeBatch(BookingAdminCase);
        Test.stopTest();
        
        Integer tskCount = [SELECT COUNT() FROM TASK WHERE Status NOT IN ('Completed','Closed')];
        System.assertEquals(0, tskCount);
    }
}