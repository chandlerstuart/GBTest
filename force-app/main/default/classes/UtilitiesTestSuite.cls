/*
Name:  UtilitiesTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) Utilities class

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-31    Initial development.
*/
@isTest
private class UtilitiesTestSuite {

    @isTest static void testIsNullOrEmpty() {
        System.assertEquals(Utilities.isNullOrEmpty(''), true);
        System.assertEquals(Utilities.isNullOrEmpty('null'), true);
        System.assertEquals(Utilities.isNullOrEmpty('.'), false);
        System.assertEquals(Utilities.isNullOrEmpty(0.0), true);
        System.assertEquals(Utilities.isNullOrEmpty(1.0), false);
        System.assertEquals(Utilities.isNullOrEmpty(new List<Account>()), true);
        Account a = new Account();
        a.Name='Test';
        insert a;
        List<Account> accountList = new List<Account>();
        accountList.add(a);
        System.assertEquals(Utilities.isNullOrEmpty(accountList), false);
    }

    @isTest static void testGrabParameters() {
        Utilities.grabParameter('Name');
    }

    @isTest static void testGenerateHash() {
        //Can't assert something that is random so just call the function
        Utilities.generateHash();
    }

    @isTest static void testGenerateMD5() {
        //Can't assert something that is random so just call the function
        Utilities.generateMD5('randval');
    }

    @isTest static void testAddZero() {
        System.assertEquals(Utilities.addZero('9'), '09');
        System.assertEquals(Utilities.addZero('10'), '10');
        System.assertEquals(Utilities.addZero(9), '09');
        System.assertEquals(Utilities.addZero(10), '10');
    }

    @isTest static void testIsSandbox() {
        Utilities.isSandbox();
    }

    @isTest static void testIsDeveloperEdition() {
        Utilities.isDeveloperEdition();
    }

    @isTest static void testGetCurrentPageName() {
        //Utilities.getCurrentPageName();
    }
}