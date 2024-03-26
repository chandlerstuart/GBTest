/*
Name:  EmpCommunity_UsefulLinkControllerTest.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test class for EmpCommunity_UsefulLinkController
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2016-10-25  Initial development.
*/
@isTest
private class EmpCommunity_UsefulLinkControllerTest {
    
    @testSetup
    static void testSetup(){
        List<Useful_Link__c> linkList = new List<Useful_Link__c>();
        for (integer i = 0 ; i < 5 ; i++){
            linkList.add(new Useful_Link__c(Label__c = 'Link ' + i, Description__c = 'Description ' + i,
                                            URL__c = 'http://test.salesforce.com',Server_Path__c = ''));
                                            
        }
        
        insert linkList;
        
        List<Attachment> attList = new List<Attachment>();
        for (Useful_Link__c l : linkList){
            String stringToBlob = 'ThisIsATestStringToMakeIntoABlob';
            Blob testBlob = Blob.valueOf(stringToBlob);
            
            Attachment a = new Attachment();
            a.Name = l.Label__c + ' Attachment';
            a.Body = testBlob;
            a.ParentId = l.Id;
            attList.add(a);
        }
        
        insert attList;
    }
    
    @IsTest
    static void testGetLinks() {
        List<Useful_Link__c> linkList;
        test.startTest();
            linkList = EmpCommunity_UsefulLinkController.getUsefulLinks();
        test.stopTest();
        
        system.assertNotEquals(null, linkList);
       
    }
    
    @IsTest
    static void testGetLinkWrappers() {
        List<EmpCommunity_UsefulLinkController.UsefulLinkWrapper> linkList;
        test.startTest();
            linkList = EmpCommunity_UsefulLinkController.getUsefulLinkWrappers();
        test.stopTest();
        
        system.assertNotEquals(null, linkList);
       
    }
    
}