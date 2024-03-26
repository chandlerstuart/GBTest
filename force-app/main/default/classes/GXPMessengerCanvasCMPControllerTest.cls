/*
Name:  GXPMessengerCanvasCMPControllerTest
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test suite for GXPMessengerCanvasCMPController.cls

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-12-05  Initial development.
*/
@isTest
public with sharing class GXPMessengerCanvasCMPControllerTest {

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
            
            //Create a conversation record
            Conversation__c conversation = new Conversation__c();
            conversation.OwnerId = users[1].Id;
            conversation.Status__c = 'New';
            conversation.ConversationId__c = '123456789101112';
            insert conversation;

            //Activate triggers
            insert new OrgSettings__c(TriggersActive__c=true);
        }
    }

    @isTest static void getCanvasAppDataTest(){

        //run as standard user
        User standardUser = [Select Id From User Where LastName = 'standard0'];

        Conversation__c conversation = [Select Id, ConversationId__c From Conversation__c];

        System.runAs(standardUser){
            test.startTest();
                Map<String,Object> data = GXPMessengerCanvasCMPController.getCanvasAppData(conversation.Id);
            test.stopTest();

            system.assertNotEquals(null, data);
            system.assertEquals('{"conversationId":"'+conversation.ConversationId__c+'","salesforceId":"'+conversation.Id+'"}', JSON.serialize(data));
        }
    }

    @isTest static void getCanvasAppDataFailTest(){
        //run as standard user
        User standardUser = [Select Id From User Where LastName = 'standard0'];

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        Conversation__c conversation = [Select Id, ConversationId__c From Conversation__c];

        System.runAs(standardUser){
            Map<String,Object> data;
            test.startTest();
                try{
                    GXPMessengerCanvasCMPController.throwException = true;//Force an error
                    data = GXPMessengerCanvasCMPController.getCanvasAppData(conversation.Id);
                }catch(Exception e){}
            test.stopTest();

            system.assertEquals(null, data);
            
            system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);

        }
    }
}