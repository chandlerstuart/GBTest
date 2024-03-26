/*
Name: SendEmailOverrideTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Class for SendEmailOverride.cls

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-17  Initial development.
*/
@isTest
public with sharing class SendEmailOverrideTest {
    
    @TestSetup static void setupData(){
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';
        cont.Email = 'mytestemail@example.com';
        insert cont;
        
        Case c = new Case();
        c.Subject = 'TestCase';
        c.ContactId = cont.Id;
        insert c;

        system.assertEquals(cont.Email,[Select ContactEmail From Case Where Id =:c.Id LIMIT 1].ContactEmail);
    }

    @isTest static void testSetDefaults(){

        Case cse = [Select Id, ContactEmail From Case Limit 1][0];
        Id caseId = cse.Id;
        //Note struggling to set the actionName when creating the new defaults with the test method. Opting for an untyped object alternative
        //QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = 
        //Test.newSendEmailQuickActionDefaults(caseId, null);
        //sendEmailDefaults.actionName = 'Case.Send_Email';

        List<Map<String, Object>> defaultSettingAsUntypedObject = new List<Map<String, Object>>
        {
        new Map<String, Object>
        {
                'targetSObject' => new EmailMessage(),
                'contextId' => caseId,
                'actionType' => 'SendEmail',
                'actionName' => 'Case.Send_Email',
                'fromAddressList' => new List<String>()
        }
        };

        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
        (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsUntypedObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
        
        List<QuickAction.QuickActionDefaults> defaults = new List<QuickAction.QuickActionDefaults>();
        //defaults.add(sendEmailDefaults);
        defaults.add(defaultsSettings[0]);

        Test.startTest();
            SendEmailOverride seo = new SendEmailOverride();
            seo.onInitDefaults(defaults);
        Test.stopTest();
    
        EmailMessage emailMessage = (EmailMessage)defaults[0].getTargetSObject();
        system.assertEquals(true, emailMessage.ValidatedFromAddress.contains('customerservice@golfbreaks.com'));
        system.assertEquals('', emailMessage.BccAddress);
        system.assertEquals(cse.ContactEmail, emailMessage.ToAddress);
        system.assertEquals(cse.Id,emailMessage.ParentId);
        system.assertEquals('', emailMessage.FromAddress);
        System.assertNotEquals(null, emailMessage);
    }
    
}