@isTest
private class VFC02_LeadHighlightsPanelCtrlTest {

    @isTest
    public static void TestgetAccount() {
    
    Lead L = new Lead();
    L.Firstname = 'Sample';
    L.Lastname = 'Sample X';
    L.Diarydate__c = date.newInstance(2016, 10, 21);
    L.Status='New';
    L.LeadSource='Event';
    L.Email = 'Sampleemail005@gamil.com';
    
    Insert L;
    
    
    Test.startTest();
        ApexPages.StandardController sc = new ApexPages.standardController(L);
        VFC02_LeadHighlightsPanelCtrl TSController = new VFC02_LeadHighlightsPanelCtrl(sc);
        TSController.getAccount();
        System.assert(L.id != null);
    Test.stopTest();
    
    }
    @isTest    
    public static void TestgetBooking() {
    
    //Create Lead
    
    Lead L = new Lead();
    L.Firstname = 'Sample';
    L.Lastname = 'Sample X';
    L.Diarydate__c = date.newInstance(2016, 10, 21);
    L.Status='New';
    L.LeadSource='Event';
    L.Email = 'Sampleemail005@gamil.com';
    
    Insert L;
    
    Test.startTest();
        ApexPages.StandardController sc1 = new ApexPages.standardController(L);
        VFC02_LeadHighlightsPanelCtrl TSController1 = new VFC02_LeadHighlightsPanelCtrl(sc1);
        List<Booking__c> bookList = TSController1.getBooking();
        System.assert(L.id != null);
    Test.stopTest();  
    }  
    
    @isTest    
    public static void Testsave() {
    
    //Create Lead
    
    Lead L = new Lead();
    L.Firstname = 'Sample';
    L.Lastname = 'Sample X';
    L.Diarydate__c = date.newInstance(2016, 10, 21);
    L.Status='New';
    L.LeadSource='Event';
    L.Email = 'Sampleemail005@gamil.com';
    
    Insert L;
    
    Lead Ld = [SELECT Id FROM Lead Limit 1];

    Test.startTest();
    Ld.Email = 'Sampleemail005@gmail.com';
    update Ld;
    
    ApexPages.StandardController sc1 = new ApexPages.standardController(L);
    VFC02_LeadHighlightsPanelCtrl TSController1 = new VFC02_LeadHighlightsPanelCtrl(sc1);
    TSController1.save();
    System.assert(L.id != null);
    Test.stopTest();  
    
    }

}