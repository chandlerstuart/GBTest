/***************************************************************************************************************************
 * Author: Simon M
 * Description: Used for SalesAgentDesktopCalendar Component. Uses List View custom setting to retrieve records for
 * Leads, Opportunities, Cases & Tasks
 * Date Created: Nov 29, 2016 
 * History:
 * <Author> <Date> <Desc>
****************************************************************************************************************************/ 

public with sharing class LC07_SalesAgentDesktopController {

    public static final String RECORD_STATUS_NEW = 'New';
    public static final String SHOW_RED_CLASS = 'showRed';
    public static final String SHOW_BLACK_CLASS = 'showBlack';
    public static final String MY_NEW_LEADS_LABEL = 'My New Leads';
    public static final String MY_NEW_LEADS_VIEW = 'My New Leads';
    public static final String MY_DIARISED_LEADS_LABEL = 'My Diarised Leads';
    public static final String MY_DIARISED_LEADS_VIEW = 'My Diarised Leads Today';
    public static final String DIARISED_RECOMMENDATIONS_LABEL = 'Diarised Recommendations';
    public static final String DIARISED_RECOMMENDATIONS_VIEW = 'My Opportunities Recommendation Today';
    public static final String DIARISED_QUOTE_SENT_LABEL = 'Diarised Quote Sent';
    public static final String DIARISED_QUOTE_SENT_VIEW = 'My Opportunities(Quote Sent) Today';
    public static final String DIARISED_CLOSED_SALE_LABEL = 'Diarised Closed Sale';
    public static final String DIARISED_CLOSED_SALE_VIEW = 'My Opportunities(Close Sale) Today';
    public static final String DIARISED_CUSTOMER_ACCEPTED_LABEL = 'Diarised Customer Accepted';
    public static final String DIARISED_CUSTOMER_ACCEPTED_VIEW = 'Customer Accepted Today';
    public static final String MY_OPPORTUNITY_CASES_LABEL = 'My Opportunity Cases';
    public static final String MY_OPPORTUNITY_CASES_VIEW = 'My Opportunity Cases';
    


    public static  Map<String, String> viewLabelToNameMap {
        get {
            if (null == viewLabelToNameMap){
                viewLabelToNameMap = new Map<String, String>();
                viewLabelToNameMap.put(MY_NEW_LEADS_LABEL,MY_NEW_LEADS_VIEW);
                viewLabelToNameMap.put(MY_DIARISED_LEADS_LABEL,MY_DIARISED_LEADS_VIEW);
                viewLabelToNameMap.put(DIARISED_RECOMMENDATIONS_LABEL,DIARISED_RECOMMENDATIONS_VIEW);
                viewLabelToNameMap.put(DIARISED_QUOTE_SENT_LABEL,DIARISED_QUOTE_SENT_VIEW);
                viewLabelToNameMap.put(DIARISED_CLOSED_SALE_LABEL,DIARISED_CLOSED_SALE_VIEW);
                viewLabelToNameMap.put(DIARISED_CUSTOMER_ACCEPTED_LABEL,DIARISED_CUSTOMER_ACCEPTED_VIEW);
                viewLabelToNameMap.put(MY_OPPORTUNITY_CASES_LABEL,MY_OPPORTUNITY_CASES_VIEW);
                //viewLabelToNameMap.put('My New Cases (Bookings)','My New Cases (Bookings)');
                //viewLabelToNameMap.put('My Open Cases (Bookings)',' My Open Cases (Today)');
                //viewLabelToNameMap.put('My Open Cases','My Open Cases (Today)');
            }
            return viewLabelToNameMap;
        }
        set;
    }

    public static List<String> leadStatusExcludeList {
        get {
            if (null == leadStatusExcludeList){
                leadStatusExcludeList = new List<String>();
                leadStatusExcludeList.add(ApplicationConstant.LEAD_NO_SALE);
                leadStatusExcludeList.add(ApplicationConstant.LEAD_CLOSED_CONVERTED);
                leadStatusExcludeList.add(ApplicationConstant.LEAD_STATUS_DUPLICATE);
            }

            return leadStatusExcludeList;
        }
        set;
    }

    public static List<String> oppIncludeList {
        get {
            if (null == oppIncludeList){
                oppIncludeList = new List<String>();
                oppIncludeList.add(ApplicationConstant.RECOMMENDATIONSTAGE);
                oppIncludeList.add(ApplicationConstant.QUOTESENTSTAGE);
                oppIncludeList.add(ApplicationConstant.CLOSESALESTAGE);
                oppIncludeList.add(ApplicationConstant.CUSTOMERACCEPTEDSTAGE);
            }
            return oppIncludeList;
        }
        set;
    }

    
    public static List<String> caseRTIncludeList {
        get {
            if (null == caseRTIncludeList){
                caseRTIncludeList = new List<String>();
                //TODO : Update ApplicationConstant class with this RT Type
                caseRTIncludeList.add('Sales Case');
                //caseRTIncludeList.add(ApplicationConstant.SERVICE_CASE);
                //caseRTIncludeList.add(ApplicationConstant.AMENDMENT);
                //caseRTIncludeList.add(ApplicationConstant.COMPLAINT);
                //caseRTIncludeList.add(ApplicationConstant.ADMIN);
            }
            return caseRTIncludeList;
        }
        set;
    }

    public static Schema.Fieldset getFieldSet(String objectName){
        //Get describe information
        List<String> sobjList = new List<String>();
        sobjList.add(objectName);
        List<Schema.DescribeSObjectResult> describeList = Schema.describeSObjects(sobjList);
        Schema.SObjectType theObject = describeList[0].getSObjectType();
        String fieldSetName = objectName + 'SalesAgentDesktop';
        Map<String, Schema.FieldSet> fsMap = theObject.getDescribe().fieldsets.getMap();
        Schema.FieldSet fs = fsMap.get(fieldSetName);    
        
        return fs;  
    }

    
    public static Date buildFilterDate(String inFilter){
        system.debug('*** -- inFilterDate = ' + inFilter + ' -- ***');
        String[] filterSplit = inFilter.split('-');
        integer yr = integer.valueOf(filterSplit[0]);
        integer mth = integer.valueOf(filterSplit[1]);
        integer d = integer.valueOf(filterSplit[2]);

        Date filterDate = Date.newInstance(yr, mth, d);

        system.debug('*** -- outFilterDate = ' + filterDate + ' -- ***');

        return filterDate;
    }

    
    public static String buildStringFromList(List<String> stringList){
        system.debug('*** -- stringList = ' + stringList + ' -- ***');
        String retString = '';
        for (String s : stringList){
            String sWithQuotes = '\'' + s + '\'';
            retString += sWithQuotes + ',';
        }

        retString = retString.substring(0, retString.length()-1);

        system.debug('*** -- returning ' + retString + ' -- ***');

        return retString;
    }

    public static boolean isCurrentDate(Date whichDate){
        return (whichDate == Date.today());
    }

    //Main Methods to retrieve records
    public static ApexPages.StandardSetController getLeadRecords(String inFilterDate){
        Schema.FieldSet fs = getFieldSet('Lead');
        Date filterDate;
        if (null == inFilterDate){
            filterDate = Date.today();
        }else {
            filterDate = buildFilterDate(inFilterDate);
        }

        String excludeList = buildStringFromList(leadStatusExcludeList);
        String dateComparison = (isCurrentDate(filterDate) ? '<=' : '=');

        String q = 'SELECT ';
        if (fs != null){
            for(Schema.FieldSetMember f : fs.getFields()) {
                q += f.getFieldPath() + ', ';
            }
            
            q += 'GolfbreaksEnquiryId__c, Status, ';

        }

        q += 'Id FROM Lead ';
        q += ' WHERE OwnerId = \'' + UserInfo.getUserId() + '\' AND ';
        q += ' IsConverted = FALSE AND ';
        q += ' Status NOT IN (' + excludeList + ') AND ';
        q += ' Diarydate__c ' + dateComparison + ' ' + inFilterDate;
        q += ' ORDER BY CallBackDateTime__c ASC NULLS LAST, Diarydate__c ASC NULLS LAST';
        
        system.debug('*** -- RUNNING LEAD ' + q + ' -- ***');

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        ssc.setPageSize(100);
        return ssc;

    }

    public static ApexPages.StandardSetController getOpportuntityRecords(String inFilterDate){
        Id salesOppRTId = ApplicationConstant.getRecordTypeId('Opportunity','NewSalesOpportunity');
        Schema.FieldSet fs = getFieldSet('Opportunity');
        Date filterDate;
        if (null == inFilterDate){
            filterDate = Date.today();
        }else {
            filterDate = buildFilterDate(inFilterDate);
        }

        String includeList = buildStringFromList(oppIncludeList);
        String dateComparison = (isCurrentDate(filterDate) ? '<=' : '=');

        String q = 'SELECT ';
        if (fs != null){
            for(Schema.FieldSetMember f : fs.getFields()) {
                q += f.getFieldPath() + ', ';
            }
            
            q += 'Account.Name, AccountId, GolfbreaksEnquiryId__c, High_Priority__c, ';

        }

        q += 'Id FROM Opportunity ';
        q += ' WHERE RecordTypeId = \'' + salesOppRTId + '\' AND ';
        q += ' OwnerId = \'' + UserInfo.getUserId() + '\' AND ';
        q += ' IsClosed = FALSE AND ';
        q += ' StageName IN (' + includeList + ') AND ';
        q += ' DiaryDate__c ' + dateComparison + ' ' + inFilterDate;
        q += ' ORDER BY High_Priority__c DESC, RequestedCallbacktimedate__c ASC NULLS LAST, DiaryDate__c ASC NULLS LAST';
        
        system.debug('*** -- RUNNING OPPORTUNITY ' + q + ' -- ***');

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        ssc.setPageSize(100);
        return ssc;

    }

    public static ApexPages.StandardSetController getCaseRecords(String inFilterDate){
        Schema.FieldSet fs = getFieldSet('Case');
        Date filterDate;
        if (null == inFilterDate){
            filterDate = Date.today();
        }else {
            filterDate = buildFilterDate(inFilterDate);
        }

        String includeList = buildStringFromList(caseRTIncludeList);
        String dateComparison = (isCurrentDate(filterDate) ? '<=' : '=');

        String q = 'SELECT ';
        if (fs != null){
            for(Schema.FieldSetMember f : fs.getFields()) {
                q += f.getFieldPath() + ', ';
            }
            
            q += ' Account.Name, AccountId, Type, Category__c, Opportunity__r.PreferredTravelDate__c, ';
            q += ' DiaryDate__c, Booking__c, Description, ';

        }

        q += 'RecordType.Name, Id FROM Case ';
        q += ' WHERE OwnerId = \'' + UserInfo.getUserId() + '\' AND ';
        q += ' IsClosed = FALSE AND ';
        q += ' RecordType.Name IN (' + includeList + ') ';
        //q += ' DiaryDate__c ' + dateComparison + ' ' + inFilterDate;
        //q += ' OR CreatedDate ' + dateComparison + ' '  + inFilterDate;
        q += ' ORDER BY Travel_Date__c ASC NULLS LAST, DiaryDate__c ASC NULLS LAST';
        //q += ' ORDER BY Travel_Date__c ASC NULLS LAST';
        
        system.debug('*** -- RUNNING CASE ' + q + ' -- ***');

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        ssc.setPageSize(100);
        return ssc;

    }

    @AuraEnabled
    public static List<ListViewWrapper> returnLeadRecords(String inFilterDate){
        String objectName = 'Lead';
        List<ListViewWrapper> mainList = new List<ListViewWrapper>();
        ApexPages.StandardSetController ssc = getLeadRecords(inFilterDate);
        List<Lead> soqlList = ssc.getRecords();
        List<SelectOption> listViews = ssc.getListViewOptions();

        if (null != soqlList && !soqlList.isEmpty()){

            List<RecordWrapper> myNewLeads = new List<RecordWrapper>();
            List<RecordWrapper> myDiarisedLeads = new List<RecordWrapper>();

            for (Lead l : soqlList){
                if (RECORD_STATUS_NEW.equalsIgnoreCase(l.Status)){
                    myNewLeads.add(new RecordWrapper(l, 'Lead'));
                }else {
                    myDiarisedLeads.add(new RecordWrapper(l, 'Lead'));
                }
            }

            ListViewWrapper myNewLeadsWrapper = new ListViewWrapper();
            myNewLeadsWrapper.label = MY_NEW_LEADS_LABEL;
            //myNewLeadsWrapper.records = myNewLeads;
            myNewLeadsWrapper.recordWrappers = myNewLeads;    
            myNewLeadsWrapper.recordCount = myNewLeads.size();
            for(SelectOption listView : listViews ){
                if (listView.getLabel() == viewLabelToNameMap.get(MY_NEW_LEADS_LABEL)){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    myNewLeadsWrapper.url = ref.getUrl();
                    myNewLeadsWrapper.isMarked = false;
                    break;
                }
            }

            ListViewWrapper myDiarisedLeadsWrapper = new ListViewWrapper();
            myDiarisedLeadsWrapper.label = MY_DIARISED_LEADS_LABEL;
            //myDiarisedLeadsWrapper.records = myDiarisedLeads;
            myDiarisedLeadsWrapper.recordWrappers = myDiarisedLeads;
            myDiarisedLeadsWrapper.recordCount = myDiarisedLeads.size();
            for(SelectOption listView : listViews ){
                if (listView.getLabel() == viewLabelToNameMap.get(MY_DIARISED_LEADS_LABEL)){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    myDiarisedLeadsWrapper.url = ref.getUrl();
                    myDiarisedLeadsWrapper.isMarked = false;
                    break;
                }
            }

            mainList.add(myNewLeadsWrapper);
            mainList.add(myDiarisedLeadsWrapper);
        }

        return mainList;

    }

    @AuraEnabled
    public static List<ListViewWrapper>  returnOppRecords(String inFilterDate){
        String objectName = 'Opportunity';
        List<ListViewWrapper> mainList = new List<ListViewWrapper>();
        ApexPages.StandardSetController ssc = getOpportuntityRecords(inFilterDate);
        List<SelectOption> listViews = ssc.getListViewOptions();
        List<Opportunity> soqlList = ssc.getRecords();
        if (null != soqlList && !soqlList.isEmpty()){

            List<RecordWrapper> diarisedRecommendations = new List<RecordWrapper>();
            List<RecordWrapper> diarisedQuoteSent = new List<RecordWrapper>();
            List<RecordWrapper> diarisedCloseSale = new List<RecordWrapper>();
            List<RecordWrapper> diarisedCustomerAccepted = new List<RecordWrapper>();

            for (Opportunity o : soqlList){
                if (ApplicationConstant.RECOMMENDATIONSTAGE.equalsIgnoreCase(o.StageName)){
                    diarisedRecommendations.add(new RecordWrapper(o, 'Opportunity'));
                }else if (ApplicationConstant.QUOTESENTSTAGE.equalsIgnoreCase(o.StageName)){
                    diarisedQuoteSent.add(new RecordWrapper(o, 'Opportunity'));
                }else if (ApplicationConstant.CLOSESALESTAGE.equalsIgnoreCase(o.StageName)){
                    diarisedCloseSale.add(new RecordWrapper(o, 'Opportunity'));
                }else if (ApplicationConstant.CUSTOMERACCEPTEDSTAGE.equalsIgnoreCase(o.StageName)){
                    diarisedCustomerAccepted.add(new RecordWrapper(o, 'Opportunity'));
                }
            }

            ListViewWrapper diarisedRecommendationsWrapper = new ListViewWrapper();
            diarisedRecommendationsWrapper.label = DIARISED_RECOMMENDATIONS_LABEL;
            //diarisedRecommendationsWrapper.records = diarisedRecommendations;
            diarisedRecommendationsWrapper.recordWrappers = diarisedRecommendations;
            diarisedRecommendationsWrapper.recordCount = diarisedRecommendations.size();
            for(SelectOption listView : listViews ){
                if (listView.getLabel() == viewLabelToNameMap.get(DIARISED_RECOMMENDATIONS_LABEL)){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    diarisedRecommendationsWrapper.url = ref.getUrl();
                    diarisedRecommendationsWrapper.isMarked = false;
                    break;
                }
            }

            ListViewWrapper diarisedQuoteSentWrapper = new ListViewWrapper();
            diarisedQuoteSentWrapper.label = DIARISED_QUOTE_SENT_LABEL;
            //diarisedQuoteSentWrapper.records = diarisedQuoteSent;
            diarisedQuoteSentWrapper.recordWrappers = diarisedQuoteSent;
            diarisedQuoteSentWrapper.recordCount = diarisedQuoteSent.size();
            for(SelectOption listView : listViews ){
                if (listView.getLabel() == viewLabelToNameMap.get(DIARISED_QUOTE_SENT_LABEL)){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    diarisedQuoteSentWrapper.url = ref.getUrl();
                    diarisedQuoteSentWrapper.isMarked = false;
                    break;
                }
            }

            ListViewWrapper diarisedCloseSaleWrapper = new ListViewWrapper();
            diarisedCloseSaleWrapper.label = DIARISED_CLOSED_SALE_LABEL;
            //diarisedCloseSaleWrapper.records = diarisedCloseSale;
            diarisedCloseSaleWrapper.recordWrappers = diarisedCloseSale;
            diarisedCloseSaleWrapper.recordCount = diarisedCloseSale.size();
            for(SelectOption listView : listViews ){
                if (listView.getLabel() == viewLabelToNameMap.get(DIARISED_CLOSED_SALE_LABEL)){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    diarisedCloseSaleWrapper.url = ref.getUrl();
                    diarisedCloseSaleWrapper.isMarked = false;
                    break;
                }
            }

            ListViewWrapper diarisedCustomerAcceptedWrapper = new ListViewWrapper();
            diarisedCustomerAcceptedWrapper.label = DIARISED_CUSTOMER_ACCEPTED_LABEL;
            //diarisedCustomerAcceptedWrapper.records = diarisedCustomerAccepted;
            diarisedCustomerAcceptedWrapper.recordWrappers = diarisedCustomerAccepted;
            diarisedCustomerAcceptedWrapper.recordCount = diarisedCustomerAccepted.size();
            for(SelectOption listView : listViews ){
                if (listView.getLabel() == viewLabelToNameMap.get(DIARISED_CUSTOMER_ACCEPTED_LABEL)){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    diarisedCustomerAcceptedWrapper.url = ref.getUrl();
                    diarisedCustomerAcceptedWrapper.isMarked = false;
                    break;
                }
            }

            mainList.add(diarisedRecommendationsWrapper);
            mainList.add(diarisedQuoteSentWrapper);
            mainList.add(diarisedCloseSaleWrapper);
            mainList.add(diarisedCustomerAcceptedWrapper);
        }

        return mainList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> returnCaseRecords(String inFilterDate){
        system.debug('*** -- returnCaseRecords -- ***');
        String objectName = 'Case';
        List<ListViewWrapper> mainList = new List<ListViewWrapper>();
        ApexPages.StandardSetController ssc = getCaseRecords(inFilterDate);
        List<SelectOption> listViews = ssc.getListViewOptions();

        List<Case> soqlList = ssc.getRecords();
        if (null != soqlList && !soqlList.isEmpty()){

            //List<RecordWrapper> myNewCasesBookings = new List<RecordWrapper>();
            //List<RecordWrapper> myOpenCasesBookings = new List<RecordWrapper>();
            //List<RecordWrapper> myOpenCases = new List<RecordWrapper>();
            List<RecordWrapper> leadOppCases = new List<RecordWrapper>();
            List<RecordWrapper> bookingCases = new List<RecordWrapper>();


            for (Case c : soqlList){
                if ('SALES CASE'.equalsIgnoreCase(c.RecordType.Name)){
                    leadOppCases.add(new RecordWrapper(c, 'Case'));
                }else {
                    bookingCases.add(new RecordWrapper(c, 'Case'));
                }

                /*
                if (RECORD_STATUS_NEW.equalsIgnoreCase(c.Status) && null != c.Booking__c){
                    myNewCasesBookings.add(new RecordWrapper(c, 'Case'));
                }else if (!RECORD_STATUS_NEW.equalsIgnoreCase(c.Status) && null != c.Booking__c){
                    myOpenCasesBookings.add(new RecordWrapper(c, 'Case'));
                }else if(!RECORD_STATUS_NEW.equalsIgnoreCase(c.Status)) {
                    myOpenCases.add(new RecordWrapper(c, 'Case'));
                }
                */
            }

            ListViewWrapper leadOppCasesWrapper = new ListViewWrapper();
            leadOppCasesWrapper.label = 'Lead / Opportunity Cases';
            //myNewCasesBookingsWrapper.records = myNewCasesBookings;
            leadOppCasesWrapper.recordWrappers = leadOppCases;
            leadOppCasesWrapper.recordCount = leadOppCases.size();
            
            for(SelectOption listView : listViews ){
                system.debug('*** -- list view label = ' + listView.getLabel() + ' -- ***');
                if (listView.getLabel() == viewLabelToNameMap.get('My Opportunity Cases')){
                    String listViewId = listView.getValue().left(15);
                    PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
                    leadOppCasesWrapper.url = ref.getUrl();
                    system.debug('*** -- Case URL = ' + leadOppCasesWrapper.url + ' -- ***');
                    leadOppCasesWrapper.isMarked = false;
                    break;
                }
            }
            
            mainList.add(leadOppCasesWrapper);
        }

        return mainList;
    }

    
    @AuraEnabled
    public static User getCurrentUser(){
        return [select Id, Name, Username from User where Id = :UserInfo.getUserId()];
    }
    
    @AuraEnabled
    public static List<Date> getCurrentDateList(){
        List<Date> dateList = new List<Date>();
        dateList.add(Date.today().addDays(-1));
        dateList.add(Date.today());
        dateList.add(Date.today().addDays(1));
        
        return dateList;
    }

    //Marks the selected Opportunity as 'High Priority'
    @AuraEnabled
    public static void setHighPriority(String oppId){
        List<Opportunity> oppList = [select Id, High_Priority__c from Opportunity where Id = :oppId LIMIT 1];
        if (!opplist.isEmpty()){
            oppList[0].High_Priority__c = TRUE;
            update oppList;
        }
    }
    
    @AuraEnabled
    public static List<String> getColumnHeaders(String whichObject, String caseTypes){
        List<String> columnList = new List<String>();
        String fieldSetName = whichObject+'SalesAgentDesktop';
        system.debug('*** -- Getting field set for ' + fieldSetName + ' -- ***');
        Map<String, Schema.FieldSet> fsMap;
        
        if ('LEAD'.equalsIgnoreCase(whichObject)){
            fsMap = Schema.SObjectType.Lead.fieldSets.getMap();
        }else if ('OPPORTUNITY'.equalsIgnoreCase(whichObject)){
            fsMap = Schema.SObjectType.Opportunity.fieldSets.getMap();
        }else if ('CASE'.equalsIgnoreCase(whichObject)){
            fsMap = Schema.SObjectType.Case.fieldSets.getMap();
        }else if ('TASK'.equalsIgnoreCase(whichObject)){
            fsMap = Schema.SObjectType.Task.fieldSets.getMap();
        }
        
        Schema.FieldSet fs = fsMap.get(fieldSetName);
        system.debug('*** -- Found ' + fs + ' -- ***');
        if ('CASE'.equalsIgnoreCase(whichObject) || 'OPPORTUNITY'.equalsIgnoreCase(whichObject)){
            columnList.add('Account Name');
        }
        for (Schema.FieldSetMember fsm : fs.getFields()){
            columnList.add(fsm.getLabel());
        }
        if ('CASE'.equalsIgnoreCase(whichObject)){
            if ('LEADOPP'.equalsIgnoreCase(caseTypes)){
                columnList.add('Type');
                columnList.add('Category');
                columnList.add('Description');
            }else if ('BOOKING'.equalsIgnoreCase(caseTypes)){
                columnList.add('Open Activity 1');
                columnList.add('Open Activity 2');
            }
        }
        if ('LEAD'.equalsIgnoreCase(whichObject) || 'OPPORTUNITY'.equalsIgnoreCase(whichObject)){
            columnList.add('Clubhouse Enquiry');
        }
        
        system.debug('*** -- About to return ' + columnList + ' -- ***');
        return columnList;
    }

    //==============================================================

    
}