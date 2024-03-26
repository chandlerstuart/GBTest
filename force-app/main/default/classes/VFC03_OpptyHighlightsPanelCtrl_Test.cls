/**
* Class Name: VFC03_OpportunityHighlightsPanelCtrl_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test VFC03_OpportunityHighlightsPanelCtrl
*/

@isTest(seeAllData=false)

public class VFC03_OpptyHighlightsPanelCtrl_Test{
       
    static testMethod void testGetMethods(){
    
        //Create List of Booking
        List<Booking__c> bookList = new List<Booking__c>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        database.insert(acc);
        
        //Create Lead
        Lead leadRec = AP23_TestDataFactory.createLead(1)[0];
        database.insert(leadRec);
        
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'1. Recommendations',acc)[0];
        opp.ServiceAgentAssigned__c = 'Test Agent';
        database.insert(opp);
        
        //Create Booking
        Booking__c booking = AP23_TestDataFactory.createBooking(1,acc,opp.Id)[0];
        database.insert(booking);
        
        bookList.add(booking);
        
        test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            VFC03_OpportunityHighlightsPanelCtrl oppHighlightPanelCtrl = new VFC03_OpportunityHighlightsPanelCtrl(sc);
            
            PageReference pageRef = Page.VFP04_OpportunityHighlightsPanel;
            pageRef.getParameters().put('id', opp.Id);
            Test.setCurrentPage(pageRef);
        
            //VFC03_OpportunityHighlightsPanelCtrl oppHighlightPanelCtrl = new VFC03_OpportunityHighlightsPanelCtrl();
            oppHighlightPanelCtrl.getAccountDetails();
            oppHighlightPanelCtrl.getLeadDetails();
            oppHighlightPanelCtrl.getBooking();
            oppHighlightPanelCtrl.save();
            
            oppHighlightPanelCtrl.name = 'test';
            oppHighlightPanelCtrl.opportunityRec = opp;
            oppHighlightPanelCtrl.checkAlertForCase = true;
        test.stopTest();  
    }
}