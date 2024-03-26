/*
Name:  OppQuoteManagementController.cls
GolfBreaks Salesforce Team
======================================================
======================================================
Purpose:
-------
Ligtning Component Controller of OppQuoteInformation
======================================================
======================================================
History
------- 
Ver. Author         Date        Detail
1.0  Simon M.       2016-08-12  Initial development.
1.1  Simon M.       2017-07-24  getOpportunityById now accepts Lead or Opp ID (for CCU Project)
1.2  Simon M.       2017-08-09  changed Parent_Lead__c to Lead_Source__c
*/
public with sharing class OppQuoteManagementController {
    public static final String CLASS_NAME = 'OppQuoteManagementController'; 
    public static final String OPP_STAGE_QUOTE_SENT = '2. Quote Sent';
    public static final String QUOTE_STATUS_ON_PORTAL = 'Visible in Portal';
    public static final String OPP_STATUS_LIVE = 'Live';

    //@AuraEnabled
    //public static Date quoteExpiryDate {get; set;}

    public static Opportunity theOpportunity {get; set;}

    @AuraEnabled  
    public static List<OppQuoteManagementController.QuoteWrapper> quoteWrapperList {get; set;}

    @AuraEnabled
    public static List<OppQuoteManagementController.QuoteWrapper> getQuoteWrapperList(){
        if (null != quoteWrapperList && !quoteWrapperList.isEmpty()){
            return quoteWrapperList;
        }else {
            return new List<OppQuoteManagementController.QuoteWrapper>();
        }

    }
    
    @AuraEnabled
    public static OppQuoteManagementController.OppWrapper oppRecord {get; set;}

    @AuraEnabled
    public static OppWrapper getOpportunityById(String oppId){
        //2017-07-24 : SM : We can now pass in either an Opportunity ID or a Lead ID so we check that before running the code
        //2017-07-24 : SM : And run the appropriate SOQL statement
        List<Opportunity> oppList;
        if (oppId.startsWith('00Q')){
            oppList = [select Id, Name, Status__c, StageName, ExpiryDate__c, 
                        (select Id, Name, DisplayOrder__c, ExpirationDate__c, Portal_Status__c, Description__c, 
                        SalePriceGross__c, Sale_Price_Per_Person__c, GrossProfit__c, Gross_Profit_Per_Person__c,
                        TravelDate__c, CreatedDate
                        from Quotes__r ORDER BY DisplayOrder__c ASC) from Opportunity where Source_Lead__c = :oppId];
                        
        }else {
            oppList = [select Id, Name, Status__c, StageName, ExpiryDate__c, 
                        (select Id, Name, DisplayOrder__c, ExpirationDate__c, Portal_Status__c, Description__c, 
                        SalePriceGross__c, Sale_Price_Per_Person__c, GrossProfit__c, Gross_Profit_Per_Person__c,
                        TravelDate__c, CreatedDate
                        from Quotes__r ORDER BY DisplayOrder__c ASC) from Opportunity where Id = :oppId];    
        }        

        if (!oppList.isEmpty()){
            theOpportunity = oppList[0];
            oppRecord = new OppWrapper(oppList[0]); 
        }

        Set<Id> quoteIds = new Set<Id>();
        for (Quote__c q : oppList[0].Quotes__r){
            quoteIds.add(q.Id);
        }

        Map<Id, List<GuestGroup__c>> guestGroupMap = new Map<Id, List<GuestGroup__c>>();
        for (GuestGroup__c gg : [select Id, Quote__c, Description__c from GuestGroup__c where Quote__c in :quoteIds Order By CreatedDate ASC]){
            List<GuestGroup__c> ggList;
            if (!guestGroupMap.containsKey(gg.Quote__c)){
                ggList = new List<GuestGroup__c>();
                ggList.add(gg);
                guestGroupMap.put(gg.Quote__c, ggList);
            }else {
                ggList = guestGroupMap.get(gg.Quote__c);
                ggList.add(gg);
                guestGroupMap.put(gg.Quote__c, ggList);
            }
        }

        for (QuoteWrapper qw : oppRecord.qwList){
            if (null != guestGroupMap.get(qw.quoteRecord.Id)){
                qw.noOfGuestGroups = guestGroupMap.get(qw.quoteRecord.Id).size();
                qw.packageDescription = guestGroupMap.get(qw.quoteRecord.Id)[0].Description__c;    
            }
        }

        return oppRecord;

    }

    @AuraEnabled
    public static OppWrapper saveRecords(String inQuotes, String inOppId, String inOppName, String inOppExpiryDate){
        system.debug('*** -- inQuotes -- ***');
        system.debug(inQuotes);
        system.debug('*** -- inOppName -- ***');
        system.debug(inOppName);
        system.debug('*** -- inOppExpiryDate -- ***');
        system.debug(inOppExpiryDate);

        List<Opportunity> theOpp = [select Id, Name, ExpiryDate__c, Status__c, StageName from Opportunity where Id = :inOppId LIMIT 1];
        
        if (!theOpp.isEmpty()){
            boolean doOppSave = false;
            if (inOppName != theOpp[0].Name){
                theOpp[0].Name = inOppName;
                doOppSave = true;
            }

            if (!OPP_STATUS_LIVE.equalsIgnoreCase(theOpp[0].Status__c)){
                theOpp[0].Status__c = OPP_STATUS_LIVE;
                doOppSave = true;
            }

            if (!OPP_STAGE_QUOTE_SENT.equalsIgnoreCase(theOpp[0].StageName)){
                theOpp[0].StageName = OPP_STAGE_QUOTE_SENT;
                doOppSave = true;
            }

            if (inOppExpiryDate != null && !String.isBlank(inOppExpiryDate)){
                String[] inOppExpiryDateSplit = inOppExpiryDate.split('-');
                Date oppExpiryDate = Date.newInstance(integer.valueOf(inOppExpiryDateSplit[0]), integer.valueOf(inOppExpiryDateSplit[1]), integer.valueOf(inOppExpiryDateSplit[2]));

                if (theOpp[0].ExpiryDate__c != oppExpiryDate){
                    theOpp[0].ExpiryDate__c = oppExpiryDate;
                    doOppSave = true;
                }
            }else {
                if (theOpp[0].ExpiryDate__c != null){
                    theOpp[0].ExpiryDate__c = theOpp[0].ExpiryDate__c.addDays(7);
                }else {
                    theOpp[0].ExpiryDate__c = Date.today().addDays(7);
                }    
                doOppSave = true;
            }

            if (doOppSave){
                update theOpp[0];
            }   
        }

        List<Quote__c> saveList = new List<Quote__c>();
        List<QuoteWrapper> processList = parseJSON(inQuotes);

        for (QuoteWrapper qw : processList){
            if (qw.isSelected){
                qw.quoteRecord.Portal_Status__c = QUOTE_STATUS_ON_PORTAL;
            }else if(!qw.isSelected) {
                qw.quoteRecord.Portal_Status__c = null;
            }

            saveList.add(qw.quoteRecord);
        }

        //CALL SAVE
        update saveList;
        
        return getOpportunityById(inOppId);


    }   

    //We have to call this method to deserialize the incoming JSON string
    //Due to the current problems with passing a list of object from the 
    //Lighting Framework into Apex
    private static List<QuoteWrapper> parseJSON(String jsonString){
        system.debug('*** -- into parseJSON with ' + jsonString + ' -- ***');
        JSONParser parser = JSON.createParser(jsonString);
        List<QuoteWrapper> inList = new List<QuoteWrapper>();

        QuoteWrapper qw;
        Quote__c q;

        while (parser.nextToken() != null){
            //system.debug('*** -- Processing ' + parser.getText() + ' -- ***');
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                String whichField = parser.getText();
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'ISSELECTED'.equalsIgnoreCase(whichField)){
                    qw = new QuoteWrapper();
                    parser.nextToken();
                    qw.isSelected = parser.getBooleanValue();
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'QUOTERECORD'.equalsIgnoreCase(whichField)){
                    q = new Quote__c();
                    parser.nextToken();
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'OPPORTUNITY__C'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    
                    q.Opportunity__c = parser.getText();
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'ID'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    
                    q.Id = parser.getText();
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'DISPLAYORDER__C'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    
                    q.DisplayOrder__c = parser.getIntegerValue();
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'PORTAL_STATUS__C'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    
                    q.Portal_Status__c = parser.getText();
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && 'SHOWMOVEUP'.equalsIgnoreCase(whichField)){
                    qw.quoteRecord = q;
                    inList.add(qw);
                }

            }
        }

        return inList;

    }

    public class OppWrapper {
        @AuraEnabled
        public Opportunity opportunity {get; set;}
        @AuraEnabled
        public List<OppQuoteManagementController.QuoteWrapper> qwList {get; set;}
        @AuraEnabled
        public String oppId {get; set;}

        public oppWrapper(Opportunity inOpp){
            this.opportunity = inOpp;
            this.oppId = inOpp.Id;
            if (!inOpp.Quotes__r.isEmpty()){
                qwList = new List<OppQuoteManagementController.QuoteWrapper>();
                integer i = 1; //Counter if Display Order on a Quote = null
                for (Quote__c q : inOpp.Quotes__r){
                    if (q.DisplayOrder__c == null) q.DisplayOrder__c = i;
                    system.debug('*** -- Status = ' + q.Portal_Status__c + ' -- ***');
                    QuoteWrapper qw = new QuoteWrapper(q);
                    qw.isSelected = (QUOTE_STATUS_ON_PORTAL.equalsIgnoreCase(q.Portal_Status__c) ? TRUE : FALSE);
                    qw.showMoveUp = (q.DisplayOrder__c == 1 ? FALSE : TRUE);
                    qw.showMoveDown = (q.DisplayOrder__c == inOpp.Quotes__r.size() ? FALSE : TRUE);
                    system.debug('*** -- Is Selected = ' + qw.isSelected + ' -- ***');
                    qwList.add(qw);
                    i++;
                }
            }

            OppQuoteManagementController.quoteWrapperList = qwList;

            system.debug('*** -- qwList = ' + qwList + ' -- ***');
        }
    }

    public class QuoteWrapper {
        @AuraEnabled
        public Quote__c quoteRecord {get; set;}
        @AuraEnabled
        public String packageDescription {get; set;}
        @AuraEnabled
        public integer noOfGuestGroups {get; set;}
        @AuraEnabled
        public boolean isSelected {
            get {
                if (null == isSelected) isSelected = false;
                return isSelected;
            }
            set;
        }
        @AuraEnabled
        public boolean showMoveUp {
            get {
                if (null == showMoveUp) showMoveUp = true;
                return showMoveUp;
            }
            set;
        }
        @AuraEnabled
        public boolean showMoveDown {
            get {
                if (null == showMoveDown) showMoveDown = true;
                return showMoveDown;
            }
            set;
        }

        public QuoteWrapper(Quote__c inQuote){
            this.quoteRecord = inQuote;
        }

        public QuoteWrapper(){

        }
    }
}