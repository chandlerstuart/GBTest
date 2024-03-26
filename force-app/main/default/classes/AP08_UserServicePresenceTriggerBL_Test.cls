@isTest
private class AP08_UserServicePresenceTriggerBL_Test {
		
	//2017-03-16 : MC : Test code setup() and fullHandlerTest().	
	@testSetup static void setup(){
		
		User agent1,agent2,agent3; 
		Group group1;
		Group queue1;

		System.runAs(new User(Id=UserInfo.getUserId())){
        	Profile salesProfile = [SELECT Id FROM Profile WHERE Name='Golfbreaks Sales User'];
                
	        agent1 = new User(Alias = 'standt1', Email='gbtest1@test.com',
	                        EmailEncodingKey='UTF-8', LastName='Breaks', LanguageLocaleKey='en_US',
	                        LocaleSidKey='en_US', ProfileId = salesProfile.Id, TimeZoneSidKey='America/Los_Angeles', 
	                        UserName='gbtest1@test.com');
	        insert agent1;
	        
	        agent2 = new User(Alias = 'standt2', Email='gbtest2@test.com',
	                        EmailEncodingKey='UTF-8', LastName='Breaks', LanguageLocaleKey='en_US',
	                        LocaleSidKey='en_US', ProfileId = salesProfile.Id, TimeZoneSidKey='America/Los_Angeles', 
	                        UserName='gbtest21@test.com');
	        insert agent2;
	        
	        agent3 = new User(Alias = 'standt3', Email='gbtest3@test.com',
	                        EmailEncodingKey='UTF-8', LastName='Breaks', LanguageLocaleKey='en_US',
	                        LocaleSidKey='en_US', ProfileId = salesProfile.Id, TimeZoneSidKey='America/Los_Angeles', 
	                        UserName='gbtest32@test.com');
	        insert agent3;	        	        
	        	        
	        queue1 = [select Id from Group where Name = 'S- EU 0-7 Sales Team' and Type='Queue' LIMIT 1];	
			insert new GroupMember(UserOrGroupId=agent1.Id,GroupId=queue1.Id);
			
			group1 = new Group(Name='Indirect Queue Membership Group');
			insert group1;
			insert new GroupMember(UserOrGroupId=agent3.Id,GroupId=group1.Id);
			
			insert new GroupMember(UserOrGroupId=group1.Id,GroupId=queue1.Id);// group is a member of the queue.
		}
		
        Id queuePresenceRecordTypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get(ApplicationConstant.USP_QUEUE_PRESENCE).getRecordTypeId();
        Id salesAgentRecordTypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get(ApplicationConstant.USP_SALES_AGENT).getRecordTypeId();

		System.runAs(new User(Id=UserInfo.getUserId())){
	        List<Sales_Agent_Attributes__c> saaList = new List<Sales_Agent_Attributes__c>();
	        //Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(RecordTypeId = queuePresenceRecordTypeId, Sales_Rep__c = UserInfo.getUserId(), Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
	        Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(RecordTypeId = queuePresenceRecordTypeId, Sales_Rep__c = agent2.Id, Queue__c = ApplicationConstant.EUROPE_0_7_TEAM, Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
	        Sales_Agent_Attributes__c saa1 = new Sales_Agent_Attributes__c(RecordTypeId = salesAgentRecordTypeId, Sales_Rep__c = agent1.Id, Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
	        Sales_Agent_Attributes__c saa2 = new Sales_Agent_Attributes__c(RecordTypeId = salesAgentRecordTypeId, Sales_Rep__c = agent3.Id, Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
	        saaList.add(saa);
	        saaList.add(saa1);
	        saaList.add(saa2);
	        insert saaList;
		}
	}
	
	/*	
    @testSetup static void setUp(){
        Group grp = [select Id from Group where Name = 'S- EU 0-7 Sales Team' LIMIT 1];
        Set<Id> idSet = new Set<Id>();
        for (GroupMember gm : [select UserOrGroupId from GroupMember where GroupId = :grp.Id]){
            idSet.add(gm.UserOrGroupId);
        }
        Profile salesProfile = [select Id from Profile where Name = 'Golfbreaks Sales User' LIMIT 1];
        List<User> salesUsers = [select Id, Name from User where ProfileId = :salesProfile.Id and IsActive = TRUE AND Id in :idSet];

        Id queuePresenceRecordTypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get(ApplicationConstant.USP_QUEUE_PRESENCE).getRecordTypeId();
        Id salesAgentRecordTypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get(ApplicationConstant.USP_SALES_AGENT).getRecordTypeId();
        List<Sales_Agent_Attributes__c> saaList = new List<Sales_Agent_Attributes__c>();
        //Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(RecordTypeId = queuePresenceRecordTypeId, Sales_Rep__c = UserInfo.getUserId(), Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
        Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(RecordTypeId = queuePresenceRecordTypeId, Sales_Rep__c = salesUsers[0].Id, Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
        Sales_Agent_Attributes__c saa1 = new Sales_Agent_Attributes__c(RecordTypeId = salesAgentRecordTypeId, Sales_Rep__c = salesUsers[1].Id, Team__c = ApplicationConstant.EUROPE_0_7_TEAM, Online__c = TRUE);
        saaList.add(saa);
        saaList.add(saa1);
        insert saaList;
    }
    */

    //UserServicePresence
    @isTest static void testValueSetters() {     
            AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeUpdateTriggerCalled);
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeUpdateTriggerCalled);
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeDeleteTriggerCalled);
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeInsertTriggerCalled);
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isAfterUpdateTriggerCalled);
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isAfterDeleteTriggerCalled);
            System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isAfterInsertTriggerCalled);
    }

	//2017-03-16 : MC : Test code setup() and fullHandlerTest().
    @isTest static void fullHandlerTest() {
		Id salesAgentRecordTypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get(ApplicationConstant.USP_SALES_AGENT).getRecordTypeId();	
        
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();
        
        List<Sales_Agent_Attributes__c> saaList = [SELECT Id, Sales_Rep__c, Online__c, RecordTypeId, Queue__c, NumberOfOnlineUser__c, Name FROM Sales_Agent_Attributes__c]; 
        system.assertNotEquals(true, saaList.isEmpty());
        
        Set<Id> userIds = new Set<Id>();
        Id userId;
        
        for (Sales_Agent_Attributes__c s : saaList){
            userIds.add(s.Sales_Rep__c);
            
            if (s.RecordTypeId==salesAgentRecordTypeId && userId==null) userId=s.Sales_Rep__c;            	
        }
        
        UserServicePresence sc = new UserServicePresence(UserId = userId);
        
		bl.userIdSet = userIds;        
        bl.bulkBefore();
        bl.bulkAfter();
        
        // test data summary.
        
        // 1 agent with direct assignment to the queue
        // 1 agent with indirect assignment to the queue via public group
        // 1 agent record articifically crafted to ensure queue presence related code is run.
    	System.assertEquals(1,bl.queueToPublicGroup.keySet().size());
    	System.assertEquals(4,bl.queueToPublicGroup.get(new List<Id>(bl.queueToPublicGroup.keySet())[0]).size());
        	
    	System.assertEquals(1,bl.publicToUsers.keySet().size());
    	System.assertEquals(1,bl.publicToUsers.get(new List<Id>(bl.publicToUsers.keySet())[0]).size());
    	    
    	System.assertEquals(1,bl.queueToUsers.keySet().size());
    	System.assertEquals(3,bl.queueToUsers.get(new List<Id>(bl.queueToUsers.keySet())[0]).size());
    	    	
    	System.assertEquals(3,bl.userIdToQueueIdsMap.keySet().size());
        
        bl.andFinally();    
        bl.beforeUpdate(sc, sc);
        bl.beforeInsert(sc);
        bl.afterInsert(sc);
        bl.afterUpdate(sc, sc);
        bl.afterUpdate(sc, sc);
        bl.beforeDelete(sc);
        bl.afterDelete(sc);
    }
    
    @isTest static void testRunBeforeInsertTrigger() {      
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();

        System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeInsertTriggerCalled);
        System.assertEquals(true, bl.runBeforeInsertTrigger());
        System.assertEquals(true, AP08_UserServicePresenceTriggerBL.isBeforeInsertTriggerCalled);
    }

    @isTest static void testRunBeforeUpdateTrigger() {      
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();
        
        System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeUpdateTriggerCalled);
        System.assertEquals(true, bl.runBeforeUpdateTrigger());
        System.assertEquals(true, AP08_UserServicePresenceTriggerBL.isBeforeUpdateTriggerCalled);
    }

    @isTest static void testRunBeforeDeleteTrigger() {      
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();

        System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isBeforeDeleteTriggerCalled);
        System.assertEquals(true, bl.runBeforeDeleteTrigger());
        System.assertEquals(true, AP08_UserServicePresenceTriggerBL.isBeforeDeleteTriggerCalled);
    }

    @isTest static void testRunAfterInsertTrigger() {       
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();

        System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isAfterInsertTriggerCalled);
        System.assertEquals(true, bl.runAfterInsertTrigger());
        System.assertEquals(true, AP08_UserServicePresenceTriggerBL.isAfterInsertTriggerCalled);
    }

    @isTest static void testRunAfterUpdateTrigger() {       
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();

        System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isAfterUpdateTriggerCalled);
        System.assertEquals(true, bl.runAfterUpdateTrigger());
        System.assertEquals(true, AP08_UserServicePresenceTriggerBL.isAfterUpdateTriggerCalled);
    }

    @isTest static void testRunAfterDeleteTrigger() {       
        AP08_UserServicePresenceTriggerBL bl = new AP08_UserServicePresenceTriggerBL();

        System.assertEquals(false, AP08_UserServicePresenceTriggerBL.isAfterDeleteTriggerCalled);
        System.assertEquals(true, bl.runAfterDeleteTrigger());
        System.assertEquals(true, AP08_UserServicePresenceTriggerBL.isAfterDeleteTriggerCalled);
    }
}