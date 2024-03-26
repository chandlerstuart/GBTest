/*
Class:  HighVolumeAutoReplyActionTest.cls
Copyright © 2024  Golfbreaks
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) code behaviour related to the action HighVolumeAutoReplyAction.

Coverage for classes below (target 85%):
HighVolumeAutoReplyAction.cls : 79%

======================================================
======================================================
Revision History
---------------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2024-02-05  Initial development.
*/
@isTest 
public class HighVolumeAutoReplyActionTest {

    List<AutoReplyConfiguration__mdt> autoReplyConfigurations;

    /*
    Test cases:
        singleTestCase1 - Business Logic. Channel+BU+Work Item Type (Opportunity).
        singleTestCase2 - Business Logic. Channel.
    */

    @testSetup static void setup(){ }

    /* **/    
    static testMethod void singleTestCase1() {
        // Test Case 1 : Business Logic. Channel+BU+Work Item Type (Opportunity).

        Golfbreaks_Business_Unit__c businessUnit = new Golfbreaks_Business_Unit__c();
        businessUnit.Name = 'Test Business Unit 1';
        businessUnit.DeveloperName__c = 'TBU1';
        insert businessUnit;

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_NEW, client)[0];
        insert opp;

        Conversation__c conv = new Conversation__c();
        conv.Account__c = client.Id;
        conv.Opportunity__c = opp.Id;
        conv.Status__c = 'New';//default, but set explicit;y for clarity.
        conv.GolfbreaksBusinessUnit__c = businessUnit.Id;
        insert conv;

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();

        String idBase = '000000000001';        
        String keyPrefix = MessagingTemplate__mdt.SObjectType.getDescribe().getKeyPrefix();
        Id fakeMessagingTemplateId = Id.valueOf(keyPrefix+idBase);

        keyPrefix = Case.SObjectType.getDescribe().getKeyPrefix();
        Id fakeCaseId = Id.valueOf(keyPrefix+idBase);

        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,fakeMessagingTemplateId,businessUnit.DeveloperName__c,'Opportunity');

        HighVolumeAutoReplyAction.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        HighVolumeAutoReplyAction.autoReplyConfigurations = autoReplyConfigurations;


        HighVolumeAutoReplyAction.ActionRequest request;
        List<HighVolumeAutoReplyAction.ActionRequest> requests = new List<HighVolumeAutoReplyAction.ActionRequest>();
        
        request = new HighVolumeAutoReplyAction.ActionRequest();
        request.conversationId = conv.Id;
        request.messagingChannel = messagingChannel.DeveloperName;
        request.businessUnitDeveloperName = businessUnit.DeveloperName__c;
        request.opportunityId = opp.Id;
        request.isNew = true;
        requests.add(request);

        request = new HighVolumeAutoReplyAction.ActionRequest();
        request.conversationId = conv.Id;
        request.messagingChannel = messagingChannel.DeveloperName;
        request.businessUnitDeveloperName = businessUnit.DeveloperName__c;
        request.caseId = fakeCaseId;
        request.isNew = true;
        requests.add(request);

        List<HighVolumeAutoReplyAction.ActionResult> results = HighVolumeAutoReplyAction.checkHighVolumeAutoReply(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isTrue(results[0].isHighVolumeAutoReply);
        Assert.areEqual(fakeMessagingTemplateId,results[0].messagingTemplateId);

        Assert.isTrue(results[1].isSuccess);
        Assert.isFalse(results[1].isHighVolumeAutoReply);
    }

    /* **/    
    static testMethod void singleTestCase2() {
        // Test Case 2 : Business Logic. Channel.

        Golfbreaks_Business_Unit__c businessUnit = new Golfbreaks_Business_Unit__c();
        businessUnit.Name = 'Test Business Unit 1';
        businessUnit.DeveloperName__c = 'TBU1';
        insert businessUnit;

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_NEW, client)[0];
        insert opp;

        Conversation__c conv = new Conversation__c();
        conv.Account__c = client.Id;
        conv.Opportunity__c = opp.Id;
        conv.Status__c = 'New';//default, but set explicit;y for clarity.
        conv.GolfbreaksBusinessUnit__c = businessUnit.Id;
        insert conv;

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();

        String idBase = '000000000001';        
        String keyPrefix = MessagingTemplate__mdt.SObjectType.getDescribe().getKeyPrefix();
        Id fakeMessagingTemplateId = Id.valueOf(keyPrefix+idBase);

        keyPrefix = Case.SObjectType.getDescribe().getKeyPrefix();
        Id fakeCaseId = Id.valueOf(keyPrefix+idBase);

        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,fakeMessagingTemplateId,null,null);

        HighVolumeAutoReplyAction.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        HighVolumeAutoReplyAction.autoReplyConfigurations = autoReplyConfigurations;


        HighVolumeAutoReplyAction.ActionRequest request;
        List<HighVolumeAutoReplyAction.ActionRequest> requests = new List<HighVolumeAutoReplyAction.ActionRequest>();
        
        request = new HighVolumeAutoReplyAction.ActionRequest();
        request.conversationId = conv.Id;
        request.messagingChannel = messagingChannel.DeveloperName;
        request.businessUnitDeveloperName = businessUnit.DeveloperName__c;
        request.opportunityId = opp.Id;
        request.isNew = true;
        requests.add(request);

        request = new HighVolumeAutoReplyAction.ActionRequest();
        request.conversationId = conv.Id;
        request.messagingChannel = messagingChannel.DeveloperName;
        request.businessUnitDeveloperName = businessUnit.DeveloperName__c;
        request.caseId = fakeCaseId;
        request.isNew = true;
        requests.add(request);

        List<HighVolumeAutoReplyAction.ActionResult> results = HighVolumeAutoReplyAction.checkHighVolumeAutoReply(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isTrue(results[0].isHighVolumeAutoReply);
        Assert.areEqual(fakeMessagingTemplateId,results[0].messagingTemplateId);

        Assert.isTrue(results[1].isSuccess);
        Assert.isTrue(results[1].isHighVolumeAutoReply);
    }    

    private static MessagingChannel__mdt buildMessagingChannel(){
        
        String idBase = '000000000001';    
        String keyPrefix = MessagingChannel__mdt.SObjectType.getDescribe().getKeyPrefix();
        Id fakeMessagingChannelId = Id.valueOf(keyPrefix+idBase);
        
        MessagingChannel__mdt messagingChannel = new MessagingChannel__mdt();

        Map<String,Object> fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(messagingChannel));
        fields.put(MessagingChannel__mdt.Label.getDescribe().getName(),'SMS');
        fields.put(MessagingChannel__mdt.DeveloperName.getDescribe().getName(),'SMS');
        fields.put(MessagingChannel__mdt.Id.getDescribe().getName(),fakeMessagingChannelId);
        messagingChannel = (MessagingChannel__mdt) JSON.deserialize(JSON.serialize(fields), MessagingChannel__mdt.class);
        return messagingChannel;
    }
    
    private static List<AutoReplyConfiguration__mdt> buildAutoReplyConfigurations(MessagingChannel__mdt messagingChannel, Id fakeMessagingTemplateId, String businessUnitDeveloperName, String workItemType){
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = new List<AutoReplyConfiguration__mdt>();

        MessagingTemplate__mdt messagingTemplate = new MessagingTemplate__mdt();

        Map<String,Object> fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(messagingTemplate));
        fields.put(MessagingTemplate__mdt.Label.getDescribe().getName(),'High Volume Messaging Template');
        fields.put(MessagingTemplate__mdt.DeveloperName.getDescribe().getName(),'High_Volume_Messaging_Template');
        fields.put(MessagingTemplate__mdt.MessageFormat__c.getDescribe().getName(),'Test {0}{1}');
        fields.put(MessagingTemplate__mdt.MessageFormatFields__c.getDescribe().getName(),'Id,Account__r.Name');
        fields.put(MessagingTemplate__mdt.Id.getDescribe().getName(),fakeMessagingTemplateId);
        messagingTemplate = (MessagingTemplate__mdt) JSON.deserialize(JSON.serialize(fields), MessagingTemplate__mdt.class);        
        
        AutoReplyConfiguration__mdt autoReplyConfig = new AutoReplyConfiguration__mdt();

        fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(autoReplyConfig));
        fields.put(AutoReplyConfiguration__mdt.Label.getDescribe().getName(),'ARC1');
        fields.put(AutoReplyConfiguration__mdt.DeveloperName.getDescribe().getName(),'ARC1');
        if (String.isNotBlank(businessUnitDeveloperName)) fields.put(AutoReplyConfiguration__mdt.BusinessUnitDeveloperName__c.getDescribe().getName(),businessUnitDeveloperName);
        if (String.isNotBlank(workItemType)) fields.put(AutoReplyConfiguration__mdt.WorkItemType__c.getDescribe().getName(),workItemType);
        fields.put(AutoReplyConfiguration__mdt.MessagingChannel__c.getDescribe().getName(),messagingChannel.Id);
        fields.put(AutoReplyConfiguration__mdt.HighVolumeAutoRepliesForNew__c.getDescribe().getName(),true);
        fields.put(AutoReplyConfiguration__mdt.HighVolumeAutoRepliesForUpdates__c.getDescribe().getName(),false);
        fields.put(AutoReplyConfiguration__mdt.HighVolumeTemplate__c.getDescribe().getName(),fakeMessagingTemplateId);
        autoReplyConfig = (AutoReplyConfiguration__mdt) JSON.deserialize(JSON.serialize(fields), AutoReplyConfiguration__mdt.class);
        
        autoReplyConfigurations.add(autoReplyConfig);

        return autoReplyConfigurations;
    }
}