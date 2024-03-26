/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 17/08/2016
@description - Test class for OppQuoteManagementController
***************************************************************/
@isTest
private class OppQuoteManagementControllerTest {
    public static final String OPP_STAGE_RECOMMENDATIONS = '1. Recommendations';
    @testSetup
    public static void setup() {
    	List<Account> accList = new List<Account>();
        List<Quote__c> quoteList = new List<Quote__c>();
    	RecordType clientRT = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Client' LIMIT 1];
    	RecordType venueRT = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Venue' LIMIT 1];
        RecordType salesOppRT = [select Id from RecordType where SObjectType = 'Opportunity' and DeveloperName = 'NewSalesOpportunity' LIMIT 1];

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        Account client = new Account(FirstName = 'Test', LastName = 'Client');
        client.RecordTypeId = clientRT.Id;
        
        accList.add(client);

        insert accList;

        Opportunity opp = new Opportunity();
        opp.RecordTypeId = salesOppRT.Id;
        opp.Name = 'Test Opp';
        opp.StageName = OPP_STAGE_RECOMMENDATIONS;
        opp.CloseDate = Date.today();
        opp.DiaryDate__c = Date.today();
        //opp.ExpiryDate__c = Date.today().addDays(7);
        opp.AccountId = accList[0].Id;
        //opp.Status__c = OppQuoteManagementController.OPP_STATUS_LIVE;
        insert opp;

        for (integer i = 1 ; i < 4 ; i++){
            Quote__c quote = new Quote__c();
            quote.Name = 'Quote ' + i;
            quote.Opportunity__c = opp.Id;
            quote.SalePriceGross__c = i * 1000;
            quote.DisplayOrder__c = i;    
            quoteList.add(quote);
        }

        quoteList[0].Portal_Status__c = OppQuoteManagementController.QUOTE_STATUS_ON_PORTAL;

        insert quoteList;

        List<GuestGroup__c> ggList = new List<GuestGroup__c>();
        for (Quote__c q : quoteList){
            GuestGroup__c gg = new GuestGroup__c();
            gg.Description__c = 'This is a guest group for ' + q.Name;
            gg.Quote__c = q.Id;
            gg.GroupSize__c = 3;
            ggList.add(gg);
        }

        insert ggList;

    }

    static testMethod void testController() {
        Opportunity opp = [select Id, ExpiryDate__c, Name, StageName, Status__c from Opportunity LIMIT 1];
        String oppId = opp.Id;
        String oppName = 'Test Opp Name Change';
        Date expDate = Date.today().addDays(7);
        //String yr = (expDate.year().format()).replace(',','');
        String oppExpiryDate = '2016-08-18';

        List<Quote__c> quoteList = [select Id, Name, DisplayOrder__c, ExpirationDate__c, Portal_Status__c, Description__c, 
                                    SalePriceGross__c, Sale_Price_Per_Person__c, GrossProfit__c, Gross_Profit_Per_Person__c
                                    from Quote__c];

        String jsonString = '[{"isSelected":true,"quoteRecord":{"Opportunity__c":"' + oppId + '","Id":"' + quoteList[0].Id + '","Name":"' + quoteList[0].Name + '","DisplayOrder__c":' + quoteList[0].DisplayOrder__c + ',"Portal_Status__c":"' + OppQuoteManagementController.QUOTE_STATUS_ON_PORTAL + '","ExpirationDate__c":"' + opp.ExpiryDate__c + '","SalePriceGross__c":' + quoteList[0].SalePriceGross__c + ',"Sale_Price_Per_Person__c":' + quoteList[0].Sale_Price_Per_Person__c + ',"Gross_profit_per_person__c":' + quoteList[0].Gross_profit_per_person__c + '},"showMoveDown":true,"showMoveUp":false},';
        jsonString += '{"isSelected":false,"quoteRecord":{"Opportunity__c":"' + oppId + '","Id":"' + quoteList[1].Id + '","Name":"' + quoteList[1].Name + '","DisplayOrder__c":' + quoteList[1].DisplayOrder__c + ',"ExpirationDate__c":"' + opp.ExpiryDate__c + '","SalePriceGross__c":' + quoteList[1].SalePriceGross__c + ',"Sale_Price_Per_Person__c":' + quoteList[1].Sale_Price_Per_Person__c + ',"Gross_profit_per_person__c":' + quoteList[1].Gross_profit_per_person__c + '},"showMoveDown":true,"showMoveUp":true},';
        jsonString += '{"isSelected":false,"quoteRecord":{"Opportunity__c":"' + oppId + '","Id":"' + quoteList[2].Id + '","Name":"' + quoteList[2].Name + '","DisplayOrder__c":' + quoteList[2].DisplayOrder__c + ',"ExpirationDate__c":"' + opp.ExpiryDate__c + '","SalePriceGross__c":' + quoteList[2].SalePriceGross__c + ',"Sale_Price_Per_Person__c":' + quoteList[2].Sale_Price_Per_Person__c + ',"Gross_profit_per_person__c":' + quoteList[2].Gross_profit_per_person__c + '},"showMoveDown":false,"showMoveUp":true}]';            

        List<OppQuoteManagementController.QuoteWrapper> qwList = OppQuoteManagementController.getQuoteWrapperList();
        system.assertEquals(true, qwList.isEmpty());

        OppQuoteManagementController.OppWrapper testWrapper = OppQuoteManagementController.getOpportunityById(oppId);
        system.assertNotEquals(null, testWrapper);

        qwList = OppQuoteManagementController.getQuoteWrapperList();
        system.assertNotEquals(true, qwList.isEmpty());

        for (OppQuoteManagementController.QuoteWrapper qw : qwList){
            boolean showMoveUp = qw.showMoveUp;
            boolean showMoveDown = qw.showMoveDown;
        }

        OppQuoteManagementController.saveRecords(jsonString, oppId, oppName, oppExpiryDate);


    }

}