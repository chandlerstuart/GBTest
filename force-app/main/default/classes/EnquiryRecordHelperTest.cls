/*
Name: EnquiryRecordHelperTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for EnquiryRecordHelper functions.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-05  Initial development.
1.1  Mark Cane&    2019-06-20  Added test method testMapEnquiryToSObjectCaseActionWithOverride.
1.2  J Radcliffe   2019-08-19  Added 'ClientFieldMappingGroup__c' and 'WorkItemFieldMappingGroup__c' to Action Type Query
*/
@isTest
public with sharing class EnquiryRecordHelperTest {

    @TestSetup static void createTestData(){
        Case c = new Case();
        c.Subject = 'Add appended data here:'; //<-- Field mapping should append data
        c.Description = 'Text to override'; //<-- Field mapping should override data
        c.Type = null; //<-- Field mapping should set Type (static value)
        c.Status = 'On Hold';//<-- Field mapping should leave this data as is
        c.SuppliedCompany = 'value1';//<-- Field mapping should convert array string to multi select 'friendly' format AND merge new values with existing
        c.IsEscalated = false; //Field mapping should handle the conversion of static boolean value ('true') to boolean
        insert c;
    }
    
    //Primary test method to run a series of checks on the mapping behaviour incl.
    // Static values vs dynamic (retrieved from the Enquiry)
    // Omit vs Append vs Override
    // Verifying the successful reformatting of data types i.e. String Array >>> Multi Select and 'true' String >>> Boolean
    @isTest static void testMapEnquiryToSObjectCaseAction(){
        
        Case c = [Select Id, Subject, Description, Type, Status, SuppliedCompany, IsEscalated From Case Limit 1][0];
        //Verify case details are as expected
        system.assertEquals('Add appended data here:', c.subject);
        system.assertEquals('Text to override', c.Description);
        system.assertEquals(null, c.Type);
        system.assertEquals('On Hold', c.Status);
        system.assertEquals('value1', c.SuppliedCompany);
        system.assertEquals(false, c.IsEscalated);

        //Verify Action Type details are as expected
        ActionType__mdt actionType = [Select Id, DeveloperName, BusinessUnit__c, 
                                      DupeMatchAction__c, RecordStageStatus__c, RecordTypeId__c, 
                                      RouteOnCreate__c, SObjectType__c ,WorkItemFieldMappingGroup__c, ClientFieldMappingGroup__c,ToAddress__c//1.2+
                                      From ActionType__mdt Where IsTest__c = true and DeveloperName = 'TestCaseAction' LIMIT 1][0];
        system.assertEquals('TestBU', actionType.BusinessUnit__c);
        system.assertEquals('New', actionType.RecordStageStatus__c);
        system.assertEquals('Update', actionType.DupeMatchAction__c);

        //Create Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.duplicateEnquiryId = c.Id;
        enq.taskDetails.subject = 'Appended Data';
        enq.tripDetails.countries = new List<String>{'value2,value3,value4'};
        enq.propertyCache.putAll(enq.taskDetails.propertyCache);
        enq.propertyCache.putAll(enq.tripDetails.propertyCache);
        //Add Action Type details to enq property cache
        ActionTypeHelper.addActionTypeSettingsToEnquiryPropertyCache(enq, actionType);
        
        //Confirm the property cache has been set as expected
        system.assertEquals(true, enq.propertyCache.containsKey('ActionType.status'));
        system.assertEquals(true, enq.propertyCache.containsKey('TaskDetails.subject'));
        system.assertEquals(true, enq.propertyCache.containsKey('ActionType.businessUnitId'));

        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        test.startTest();
            EnquiryRecordHelper.mapEnquiryToSObject(enquiries);
            //upsert the record generated in the sObject mapping
            upsert(enq.sfRecord);
        test.stopTest();

        //Query updated Case for assertions
        Case c2 = [Select Id, Subject, Description, Status, Type, SuppliedCompany, IsEscalated From Case Where Id = :c.Id][0];
        system.debug('c2: '+c2);
        ///APPEND - Confirm the Subject contains both the original text and appended details from the Enquiry task subject
        system.assertEquals(true, c2.Subject.contains('Add appended data here:'));
        system.assertEquals(true, c2.Subject.contains(enq.taskDetails.subject));
        //OVERRIDE - Confirm the Description has been replaced with the new value from the Enquiry
        system.assertEquals(enq.propertyCache.get('ActionType.businessUnitId'), c2.Description);
        //OMIT - Confirm status has not been overwritten
        system.assertEquals(c.Status, c2.Status);
        //STATIC VALUE - Confirm the Type has been set with the static value
        system.assertEquals('Question',c2.Type);
        //MULTI SELECT CONVER - Confirm the Countries Array has been converted to Multi Select friendly import format (semi-colon separated string of values)
        system.assertEquals('value1;'+String.join(enq.tripDetails.countries,';'), c2.SuppliedCompany);
        //STATIC BOOLEAN VALUE - Confirm the 'true' string has correctly been converted into a boolean value (isEscalated)
        system.assertEquals(true, c2.IsEscalated);
    }

    // Enquiry level override for business unit id.
    @isTest static void testMapEnquiryToSObjectCaseActionWithOverride(){
        
        Case c = [Select Id, Subject, Description, Type, Status, SuppliedCompany, IsEscalated From Case Limit 1][0];
        //Verify case details are as expected
        system.assertEquals('Add appended data here:', c.subject);
        system.assertEquals('Text to override', c.Description);
        system.assertEquals(null, c.Type);
        system.assertEquals('On Hold', c.Status);
        system.assertEquals('value1', c.SuppliedCompany);

        //Verify Action Type details are as expected
        ActionType__mdt actionType = [Select Id, DeveloperName, BusinessUnit__c, 
                                      DupeMatchAction__c, RecordStageStatus__c, RecordTypeId__c, 
                                      RouteOnCreate__c, SObjectType__c, WorkItemFieldMappingGroup__c, ClientFieldMappingGroup__c,ToAddress__c//1.2+
                                      From ActionType__mdt Where IsTest__c = true and DeveloperName = 'TestCaseAction' LIMIT 1][0];
        system.assertEquals('TestBU', actionType.BusinessUnit__c);
        system.assertEquals('New', actionType.RecordStageStatus__c);
        system.assertEquals('Update', actionType.DupeMatchAction__c);

        //Create Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.businessUnitId = 'NOTTestBU';//<--- overridden.
        enq.actionType = actionType;
        enq.duplicateEnquiryId = c.Id;
        enq.taskDetails.subject = 'Appended Data';
        enq.tripDetails.countries = new List<String>{'value2,value3,value4'};
        enq.propertyCache.putAll(enq.taskDetails.propertyCache);
        enq.propertyCache.putAll(enq.tripDetails.propertyCache);
        //Add Action Type details to enq property cache
        ActionTypeHelper.addActionTypeSettingsToEnquiryPropertyCache(enq, actionType);
        
        //Confirm the property cache has been set as expected
        system.assertEquals(true, enq.propertyCache.containsKey('ActionType.status'));
        system.assertEquals(true, enq.propertyCache.containsKey('TaskDetails.subject'));
        system.assertEquals(true, enq.propertyCache.containsKey('ActionType.businessUnitId'));
        system.assertEquals('NOTTestBU',enq.propertyCache.get('ActionType.businessUnitId'));//correct value is cached.

        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        test.startTest();
            EnquiryRecordHelper.mapEnquiryToSObject(enquiries);
            //upsert the record generated in the sObject mapping
            upsert(enq.sfRecord);
        test.stopTest();

        //Query updated Case for assertions
        Case c2 = [Select Id, Subject, Description, Status, Type, SuppliedCompany, IsEscalated From Case Where Id = :c.Id][0];
        system.debug('c2: '+c2);
        ///APPEND - Confirm the Subject contains both the original text and appended details from the Enquiry task subject
        system.assertEquals(true, c2.Subject.contains('Add appended data here:'));
        system.assertEquals(true, c2.Subject.contains(enq.taskDetails.subject));
        //OVERRIDE - Confirm the Description has been replaced with the new value from the Enquiry
        system.assertEquals('NOTTestBU', c2.Description);
        //OMIT - Confirm status has not been overwritten
        system.assertEquals(c.Status, c2.Status);
        //STATIC VALUE - Confirm the Type has been set with the static value
        system.assertEquals('Question',c2.Type);
        //MULTI SELECT CONVER - Confirm the Countries Array has been converted to Multi Select friendly import format (semi-colon separated string of values)
        system.assertEquals('value1;'+String.join(enq.tripDetails.countries,';'), c2.SuppliedCompany);
        //STATIC BOOLEAN VALUE - Confirm the 'true' string has correctly been converted into a boolean value (isEscalated)
        system.assertEquals(true, c2.IsEscalated);
    }    

    //Condensed test method mirrored on the testMapEnquiryToSObjectCaseAction to handle any outstanding tests that cannot be tested on the Case Object (due to lack of standard field of corresponding types)
    @isTest static void testMapEnquiryToSObjectOpportunityAction(){
        
        //Verify Action Type details are as expected
        ActionType__mdt actionType = [Select Id, DeveloperName, BusinessUnit__c, 
                                      DupeMatchAction__c, RecordStageStatus__c, RecordTypeId__c, 
                                      RouteOnCreate__c, SObjectType__c, WorkItemFieldMappingGroup__c, ClientFieldMappingGroup__c,ToAddress__c//1.2+ 
                                      From ActionType__mdt Where IsTest__c = true and DeveloperName = 'TestOppAction' LIMIT 1][0];
        system.assertEquals('TestBU', actionType.BusinessUnit__c);
        system.assertEquals('New', actionType.RecordStageStatus__c);
        system.assertEquals('Create', actionType.DupeMatchAction__c);

        //Create Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.duplicateEnquiryId = null;
        enq.tripDetails.nights = 9;
        enq.propertyCache.putAll(enq.tripDetails.propertyCache);
        //Add Action Type details to enq property cache
        ActionTypeHelper.addActionTypeSettingsToEnquiryPropertyCache(enq, actionType);
        
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        test.startTest();
            EnquiryRecordHelper.mapEnquiryToSObject(enquiries);
            //upsert the record generated in the sObject mapping
            upsert(enq.sfRecord);
        test.stopTest();

        //Query inserted Opportunity for assertions
        Opportunity opp = [Select Id, StageName, CloseDate, Amount, TotalOpportunityQuantity From Opportunity LIMIT 1][0];
        system.assertNotEquals(null, opp);
        system.debug('opp: '+opp);
        //STATIC DATE TIME TEST - Confirm the static 'Today' string was successfully converted and set in the closedate
        system.assertEquals(system.today(), opp.CloseDate);
        //STATIC DECIMAL TEST
        system.assertEquals(10.10, opp.Amount);
        //DYNAMIC INTEGER TEST
        system.assertEquals(enq.tripDetails.nights, opp.TotalOpportunityQuantity);

    }

}