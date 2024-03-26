/*
Class:  AutoReplyMessageActionTest.cls
Copyright © 2024  Golfbreaks
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) code behaviour related to the action AutoReplyMessageAction.

Coverage for classes below (target 85%):
AutoReplyMessageAction.cls : 89%

======================================================
======================================================
Revision History
---------------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2024-02-14  Initial development.
1.1  Mark Cane&    2024-02-16  Added singleTestCase1-5.
*/
@isTest 
public class AutoReplyMessageActionTest {

    List<AutoReplyConfiguration__mdt> autoReplyConfigurations;

    /*
    Test cases:
        singleTestCase1 - Business Logic. Channel+BU+Work Item Type (Opportunity). Agent Unavailable.
        singleTestCase2 - Business Logic. Channel+Work Item Type. Outside Business Hours.
        singleTestCase3 - Business Logic. Channel+BU. High Volume. New Conversation.
        singleTestCase4 - Business Logic. Channel. Unrecognised Customer.
        singleTestCase5 - Business Logic. MessagingTemplateId set.
    */

    @testSetup static void setup(){ }

    /* **/    
    static testMethod void singleTestCase1() {
        // Test Case 1 : Business Logic. Channel+BU+Work Item Type (Opportunity). Agent Unavailable.

        Golfbreaks_Business_Unit__c businessUnit = new Golfbreaks_Business_Unit__c();
        businessUnit.Name = 'Test Business Unit 1';
        businessUnit.DeveloperName__c = 'TBU1';
        insert businessUnit;

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_NEW, client)[0];
        insert opp;

        Conversation__c conv = new Conversation__c();
        conv.Channel__c='SMS';
        conv.Account__c = client.Id;
        conv.Opportunity__c = opp.Id;
        conv.Status__c = 'New';//default, but set explicitly for clarity.
        conv.GolfbreaksBusinessUnit__c = businessUnit.Id;
        insert conv;

        String messageFormat = 'Agent {0} is unavailable until {1}, thank you for enquiry {2}.';
        String messageFormatFields = 'Owner|User.Name,[agentReturnDate],Opportunity__r.Name';

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();
        MessagingTemplate__mdt messagingTemplate = buildMessagingTemplate(messagingChannel,messageFormat,messageFormatFields);
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,messagingTemplate,businessUnit.DeveloperName__c,'Opportunity');

        AutoReplyMessageAction2.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        AutoReplyMessageAction2.messagingTemplates = new List<MessagingTemplate__mdt>{ messagingTemplate };
        AutoReplyMessageAction2.autoReplyConfigurations = autoReplyConfigurations;

        AutoReplyMessageAction2.ActionRequest request;
        List<AutoReplyMessageAction2.ActionRequest> requests = new List<AutoReplyMessageAction2.ActionRequest>();
        
        request = new AutoReplyMessageAction2.ActionRequest();
        request.conversationId = conv.Id;
        //conversationRecord;
        //messagingTemplateId;
        //request.isUnrecognisedCustomer;
        //request.isHighVolume;
        request.isAgentUnavailable = true;
        //request.isOutsideBusinessHours;
        request.messagingChannel = messagingChannel.DeveloperName;
        request.businessUnitDeveloperName = businessUnit.DeveloperName__c;
        //businessUnitId;
        //caseId;
        //bookingId;
        request.opportunityId = opp.Id;
        //isNew;
        request.customParameters = new List<CustomParameter>{ new CustomParameter('agentReturnDate','November 2nd') };
        requests.add(request);

        List<AutoReplyMessageAction2.ActionResult> results = AutoReplyMessageAction2.getAutoReplyMessage(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isNotNull(results[0].autoReplyMessage);
        Assert.areEqual('Agent '+UserInfo.getName()+' is unavailable until November 2nd, thank you for enquiry '+opp.Name+'.', results[0].autoReplyMessage);// -- Agent {0} is unavailable until {1}, thank you for enquiry {2}.
        Assert.areEqual(messagingTemplate.UID__c,results[0].messagingTemplateId);
    }/* */

    /* **/    
    static testMethod void singleTestCase2() {
        // Test Case 2 : Channel+Work Item Type. Outside Business Hours.

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_NEW, client)[0];
        insert opp;

        Conversation__c conv = new Conversation__c();
        conv.Account__c = client.Id;
        conv.Opportunity__c = opp.Id;
        conv.Status__c = 'New';//default, but set explicitly for clarity.
        conv.Channel__c='SMS';
        insert conv;

        String messageFormat = 'Thank you for the message about {0}. An agent will reply when our contact centre opens at {1} on {2}.';
        String messageFormatFields = 'Opportunity__r.Name,[contactCentreOpenTime],[contactCentreOpenDate]';

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();
        MessagingTemplate__mdt messagingTemplate = buildMessagingTemplate(messagingChannel,messageFormat,messageFormatFields);
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,messagingTemplate,null,'Opportunity');

        AutoReplyMessageAction2.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        AutoReplyMessageAction2.messagingTemplates = new List<MessagingTemplate__mdt>{ messagingTemplate };
        AutoReplyMessageAction2.autoReplyConfigurations = autoReplyConfigurations;

        AutoReplyMessageAction2.ActionRequest request;
        List<AutoReplyMessageAction2.ActionRequest> requests = new List<AutoReplyMessageAction2.ActionRequest>();
        
        request = new AutoReplyMessageAction2.ActionRequest();
        request.conversationId = conv.Id;
        //conversationRecord;
        //messagingTemplateId;
        //request.isUnrecognisedCustomer;
        //request.isHighVolume;
        //request.isAgentUnavailable = true;
        request.isOutsideBusinessHours = true;
        request.messagingChannel = messagingChannel.DeveloperName;
        //businessUnitDeveloperName;
        //businessUnitId;
        //caseId;
        //bookingId;
        request.opportunityId = opp.Id;
        //isNew;
        request.customParameters = new List<CustomParameter>{ new CustomParameter('contactCentreOpenTime','9am'),new CustomParameter('contactCentreOpenDate','2nd November') };
        requests.add(request);

        List<AutoReplyMessageAction2.ActionResult> results = AutoReplyMessageAction2.getAutoReplyMessage(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isNotNull(results[0].autoReplyMessage);
        Assert.areEqual('Thank you for the message about '+opp.Name+'. An agent will reply when our contact centre opens at 9am on 2nd November.', results[0].autoReplyMessage);
        Assert.areEqual(messagingTemplate.UID__c,results[0].messagingTemplateId);
    }/* */
    
    /* **/    
    static testMethod void singleTestCase3() {
        // Test Case 3 : Business Logic. Channel+BU. High Volume. New Conversation.

        Golfbreaks_Business_Unit__c businessUnit = new Golfbreaks_Business_Unit__c();
        businessUnit.Name = 'Test Business Unit 1';
        businessUnit.DeveloperName__c = 'TBU1';
        insert businessUnit;

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;        

        Conversation__c conv = new Conversation__c();
        conv.Account__c = client.Id;
        conv.Status__c = 'New';//default, but set explicitly for clarity.
        conv.GolfbreaksBusinessUnit__c = businessUnit.Id;
        conv.Channel__c='SMS';
        insert conv;

        Formula.recalculateFormulas( new List<Conversation__c>{ conv } );

        String messageFormat = 'Thank you {0} for the message. We\'re experiencing high message volumes.';
        String messageFormatFields = 'AccountName__c';

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();
        MessagingTemplate__mdt messagingTemplate = buildMessagingTemplate(messagingChannel,messageFormat,messageFormatFields);
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,messagingTemplate,businessUnit.DeveloperName__c,null);

        AutoReplyMessageAction2.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        AutoReplyMessageAction2.messagingTemplates = new List<MessagingTemplate__mdt>{ messagingTemplate };
        AutoReplyMessageAction2.autoReplyConfigurations = autoReplyConfigurations;

        AutoReplyMessageAction2.ActionRequest request;
        List<AutoReplyMessageAction2.ActionRequest> requests = new List<AutoReplyMessageAction2.ActionRequest>();
        
        request = new AutoReplyMessageAction2.ActionRequest();
        request.conversationId = conv.Id;
        //conversationRecord;
        //messagingTemplateId;
        //request.isUnrecognisedCustomer;
        request.isHighVolume = true;
        //request.isAgentUnavailable;
        //request.isOutsideBusinessHours;
        request.messagingChannel = messagingChannel.DeveloperName;
        request.businessUnitDeveloperName = businessUnit.DeveloperName__c;
        //businessUnitId;
        //caseId;
        //bookingId;
        //opportunityId;
        request.isNew = true;
        //request.customParameters;
        requests.add(request);

        List<AutoReplyMessageAction2.ActionResult> results = AutoReplyMessageAction2.getAutoReplyMessage(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isNotNull(results[0].autoReplyMessage);
        Assert.areEqual('Thank you '+conv.AccountName__c+' for the message. We\'re experiencing high message volumes.', results[0].autoReplyMessage);
        Assert.areEqual(messagingTemplate.UID__c,results[0].messagingTemplateId);
    }/* */

    /* **/    
    static testMethod void singleTestCase4() {
        // Test Case 4 : Business Logic. Channel. Unrecognised Customer.

        Conversation__c conv = new Conversation__c();
        conv.Status__c = 'New';//default, but set explicitly for clarity.
        conv.Channel__c='SMS';
        insert conv;

        String messageFormat = 'Thank you for the message at {0}. An Agent will be in touch.';
        String messageFormatFields = '[convCreatedDate]';

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();
        MessagingTemplate__mdt messagingTemplate = buildMessagingTemplate(messagingChannel,messageFormat,messageFormatFields);
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,messagingTemplate,null,null);

        AutoReplyMessageAction2.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        AutoReplyMessageAction2.messagingTemplates = new List<MessagingTemplate__mdt>{ messagingTemplate };
        AutoReplyMessageAction2.autoReplyConfigurations = autoReplyConfigurations;

        AutoReplyMessageAction2.ActionRequest request;
        List<AutoReplyMessageAction2.ActionRequest> requests = new List<AutoReplyMessageAction2.ActionRequest>();
        
        request = new AutoReplyMessageAction2.ActionRequest();
        request.conversationId = conv.Id;
        //conversationRecord;
        //messagingTemplateId;
        request.isUnrecognisedCustomer = true;
        //request.isHighVolume;
        //request.isAgentUnavailable;
        //request.isOutsideBusinessHours;
        request.messagingChannel = messagingChannel.DeveloperName;
        //request.businessUnitDeveloperName;
        //businessUnitId;
        //caseId;
        //bookingId;
        //opportunityId;
        request.isNew = true;
        request.customParameters = new List<CustomParameter>{ new CustomParameter('convCreatedDate','9am, November 2nd') };
        requests.add(request);

        List<AutoReplyMessageAction2.ActionResult> results = AutoReplyMessageAction2.getAutoReplyMessage(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isNotNull(results[0].autoReplyMessage);
        Assert.areEqual('Thank you for the message at 9am, November 2nd. An Agent will be in touch.', results[0].autoReplyMessage);
        Assert.areEqual(messagingTemplate.UID__c,results[0].messagingTemplateId);
    }/* */  
    
    /* **/    
    static testMethod void singleTestCase5() {
        // Test Case 5 : Business Logic. MessagingTemplateId set.

        Conversation__c conv = new Conversation__c();
        conv.Status__c = 'New';//default, but set explicitly for clarity.
        conv.Channel__c='SMS';
        insert conv;

        String messageFormat = 'Thank you for the message at {0}. An Agent will be in touch.';
        String messageFormatFields = '[convCreatedDate]';

        MessagingChannel__mdt messagingChannel = buildMessagingChannel();
        MessagingTemplate__mdt messagingTemplate = buildMessagingTemplate(messagingChannel,messageFormat,messageFormatFields);
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = buildAutoReplyConfigurations(messagingChannel,messagingTemplate,null,null);

        AutoReplyMessageAction2.messagingChannels = new List<MessagingChannel__mdt>{ messagingChannel };
        AutoReplyMessageAction2.messagingTemplates = new List<MessagingTemplate__mdt>{ messagingTemplate };
        AutoReplyMessageAction2.autoReplyConfigurations = autoReplyConfigurations;

        AutoReplyMessageAction2.ActionRequest request;
        List<AutoReplyMessageAction2.ActionRequest> requests = new List<AutoReplyMessageAction2.ActionRequest>();
        
        request = new AutoReplyMessageAction2.ActionRequest();
        request.conversationId = conv.Id;
        //conversationRecord;
        request.messagingTemplateId = messagingTemplate.UID__c;
        //request.isUnrecognisedCustomer;
        //request.isHighVolume;
        //request.isAgentUnavailable;
        //request.isOutsideBusinessHours;
        request.messagingChannel = messagingChannel.DeveloperName;// -- mandatory input.
        //request.businessUnitDeveloperName;
        //businessUnitId;
        //caseId;
        //bookingId;
        //opportunityId;
        //request.isNew = true;
        request.customParameters = new List<CustomParameter>{ new CustomParameter('convCreatedDate','9am, November 2nd') };
        requests.add(request);

        List<AutoReplyMessageAction2.ActionResult> results = AutoReplyMessageAction2.getAutoReplyMessage(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isNotNull(results[0].autoReplyMessage);
        Assert.areEqual('Thank you for the message at 9am, November 2nd. An Agent will be in touch.', results[0].autoReplyMessage);
        Assert.areEqual(messagingTemplate.UID__c,results[0].messagingTemplateId);
    }/* */      


    // Helper methods/

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

    private static MessagingTemplate__mdt buildMessagingTemplate(MessagingChannel__mdt messagingChannel, String messageFormat, String messageFormatFields){        
        String idBase = '000000000001';    
        String keyPrefix = MessagingTemplate__mdt.SObjectType.getDescribe().getKeyPrefix();
        Id fakeMessagingTemplateId = Id.valueOf(keyPrefix+idBase);
        
        MessagingTemplate__mdt messagingTemplate = new MessagingTemplate__mdt();

        Map<String,Object> fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(messagingTemplate));
        fields.put(MessagingTemplate__mdt.MessageFormat__c.getDescribe().getName(),messageFormat);// -- 'Hello {0} from {1} thank you for enquiry {2}.'
        fields.put(MessagingTemplate__mdt.MessageFormatFields__c.getDescribe().getName(),messageFormatFields);// -- 'AccountName__c,[cityName],Opportunity__r.Name'
        fields.put(MessagingTemplate__mdt.MessagingChannel__c.getDescribe().getName(),messagingChannel.Id);
        fields.put(MessagingTemplate__mdt.IsActive__c.getDescribe().getName(),true);
        fields.put(MessagingTemplate__mdt.UID__c.getDescribe().getName(),'12345');
        fields.put(MessagingTemplate__mdt.DataEventTypeName__c.getDescribe().getName(),'Fake');
        fields.put(MessagingTemplate__mdt.Label.getDescribe().getName(),'Unit Test Template');
        fields.put(MessagingTemplate__mdt.DeveloperName.getDescribe().getName(),'Unit_Test_Template');
        fields.put(MessagingTemplate__mdt.Id.getDescribe().getName(),fakeMessagingTemplateId);
        messagingTemplate = (MessagingTemplate__mdt) JSON.deserialize(JSON.serialize(fields), MessagingTemplate__mdt.class);
        
        return messagingTemplate;
    }    
    
    private static List<AutoReplyConfiguration__mdt> buildAutoReplyConfigurations(MessagingChannel__mdt messagingChannel, MessagingTemplate__mdt messagingTemplate, String businessUnitDeveloperName, String workItemType){        
        AutoReplyConfiguration__mdt autoReplyConfig = new AutoReplyConfiguration__mdt();
        List<AutoReplyConfiguration__mdt> autoReplyConfigurations = new List<AutoReplyConfiguration__mdt>();

        Map<String,Object> fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(autoReplyConfig));
        fields.put(AutoReplyConfiguration__mdt.Label.getDescribe().getName(),'ARC1');
        fields.put(AutoReplyConfiguration__mdt.DeveloperName.getDescribe().getName(),'ARC1');
        if (String.isNotBlank(businessUnitDeveloperName)) fields.put(AutoReplyConfiguration__mdt.BusinessUnitDeveloperName__c.getDescribe().getName(),businessUnitDeveloperName);
        if (String.isNotBlank(workItemType)) fields.put(AutoReplyConfiguration__mdt.WorkItemType__c.getDescribe().getName(),workItemType);
        fields.put(AutoReplyConfiguration__mdt.MessagingChannel__c.getDescribe().getName(),messagingChannel.Id);
        fields.put(AutoReplyConfiguration__mdt.UnrecognisedCustomerTemplate__c.getDescribe().getName(),messagingTemplate.Id);
        fields.put(AutoReplyConfiguration__mdt.AgentUnavailableTemplate__c.getDescribe().getName(),messagingTemplate.Id);
        fields.put(AutoReplyConfiguration__mdt.OutsideBusinessHoursTemplate__c.getDescribe().getName(),messagingTemplate.Id);
        fields.put(AutoReplyConfiguration__mdt.HighVolumeTemplate__c.getDescribe().getName(),messagingTemplate.Id);
        fields.put(AutoReplyConfiguration__mdt.HighVolumeAutoRepliesForNew__c.getDescribe().getName(),true);
        fields.put(AutoReplyConfiguration__mdt.HighVolumeAutoRepliesForUpdates__c.getDescribe().getName(),false);
        autoReplyConfig = (AutoReplyConfiguration__mdt) JSON.deserialize(JSON.serialize(fields), AutoReplyConfiguration__mdt.class);        
        autoReplyConfigurations.add(autoReplyConfig);
        
        return autoReplyConfigurations;
    }
}