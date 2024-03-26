/*
Name:  FindDuplicateAccountsActionTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test Suite for FindDuplicateAccountsAction (Apex Action Class)

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-09-03  Initial development.
*/
@isTest
public with sharing class FindDuplicateAccountsActionTest {
    
    @isTest static void testFindDuplicateAccounts(){
        List<FindDuplicateAccountsAction.DuplicateSearchInput> inputList = new List<FindDuplicateAccountsAction.DuplicateSearchInput>();
        FindDuplicateAccountsAction.DuplicateSearchInput searchInput = new FindDuplicateAccountsAction.DuplicateSearchInput();
        searchInput.FirstName = 'Test';
        searchInput.LastName = 'Account';
        searchInput.Email = 'testAccount@example.com';
        searchInput.actionTypeName = 'TestCaseAction';
        searchInput.RecordTypeDeveloperName = 'RTDevName';
        searchInput.MobilePhone = '+447944444444';
        searchInput.HomePhone = null;
        searchInput.WorkPhone = null;
        searchInput.MailingStreet = '72 FakeStreet';
        searchInput.MailingCity = 'Madeupville';
        searchInput.MailingPostalCode = 'RT12 7UY';
        searchInput.MailingCountry = 'United Kingdom';
        inputList.add(searchInput);

        test.startTest();
        List<FindDuplicateAccountsAction.DuplicateSearchOutput> outputList = FindDuplicateAccountsAction.findDuplicates(inputList);
        test.stopTest();

        system.assertNotEquals(null, outputList);
        system.assertEquals(1, outputList.size());
        system.assertEquals('123456789101112', outputList[0].dupeAccountIdsList[0]);
        system.assertEquals('123456789101112', outputList[0].dupeAccountIdsString);

    }
}