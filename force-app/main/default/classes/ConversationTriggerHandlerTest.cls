/*
Name:  ConversationTriggerHandlerTest.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Test class for Conversation__c trigger activity
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-22  Initial development.
*/
@isTest
public with sharing class ConversationTriggerHandlerTest {

    public static final String standardUserPermissionSet = 'Messaging_Channels_User';
    public static final String adminUserPermissionSet = 'Messaging_Channels_Admin';

    @TestSetup static void createTestData(){

        //Create a standard user and admin user
        List<User> users = new List<User>();
        users.add(AP23_TestDataFactory.createStandardUsers(1,'admin',false)[0]);
        users.add(AP23_TestDataFactory.createStandardUsers(1,'standard',false)[0]);
        insert users;

        //Assign corresponding messaging permission sets
        List<PermissionSet> permissionSets = [Select Id, Name From PermissionSet Where Name = :standardUserPermissionSet or Name = :adminUserPermissionSet];
        system.assertEquals(2, permissionSets.size());
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for(PermissionSet ps : permissionSets){
            Id assigneeId = (ps.Name == standardUserPermissionSet)?users[1].Id:users[0].Id;
            psas.add(new PermissionSetAssignment(AssigneeId=assigneeId,PermissionSetId=ps.Id));
        }
        insert psas;

        User systemAdmin = AP23_TestDataFactory.createAdminUsers(1, 'SystemAdmin', true)[0];
        system.runAs(systemAdmin){
            //Activate triggers
            insert new OrgSettings__c(TriggersActive__c=true);
        }
    }
    
    //NOTE - 22nd Nov '22 There's no business logic specific to Conversations. 
    //The triggers plugin packaged triggers (Omni and Integration Framework).
    //This method serves to achieve code coverage and verify no unexpected are thrown on insert or update
    @isTest static void testAfterInsertAndUpdate(){

        //Retrieve users
        List<User> users = [Select Id, FirstName, LastName From User Where LastName = 'admin0' or LastName LIKE 'standard0'];
        User adminUser = users[0].LastName.startsWith('admin')?users[0]:users[1];
        User standardUser = users[0].LastName.startsWith('standard')?users[0]:users[1];

        system.assertEquals(2, users.size());

        System.runAs(adminUser){//Run as admin user (to create the conversation)
            
            test.startTest();

                //Create new conversation (test after insert)
                Conversation__c conversation = new Conversation__c();
                conversation.Status__c = 'New';
                conversation.ConversationId__c = '123456789101112';
                insert conversation;

                system.assertEquals(adminUser.Id, [Select OwnerId From Conversation__c].OwnerId);

                WorkItemWIREActionIdentifier.isWIRECodeBlocked = false;//Reset WIRE trigger activity (in prep for the update)

                //Reassign to standard user (test after update)
                conversation.OwnerId = standardUser.Id;
                update conversation;

            test.stopTest();
        }

    }

}