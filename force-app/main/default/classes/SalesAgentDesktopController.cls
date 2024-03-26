/***************************************************************************************************************************
 * Author: Erika Hidalgo
 * Description: Used for SalesAgentDesktop Component. Returns all the summary report for each sales agent component
 * Date Created: April 14, 2016 
 * History:
 * Jerome To   04.22.2016   refactor
 * <Author> <Date> <Desc>
****************************************************************************************************************************/    

public with sharing class SalesAgentDesktopController {

    static Map<String, ListViewWrapper> getListViewWrapper(String objectName) {    
        String listViewId = '';
        String listViewURL  = '';
        String q = 'SELECT Id FROM ' + objectName + ' LIMIT 1';
        Map<String, ListViewWrapper> listViewWrapperMap = new Map<String, ListViewWrapper>();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(Database.getQueryLocator(q));       
        List<SelectOption> listViews = ssc.getListViewOptions();
        for(SelectOption listView : listViews ){
            ListViewWrapper listViewWrapper = new ListViewWrapper();
            listViewId = listView.getValue().left(15);
            ssc.setFilterId(listViewId);
            listViewWrapper.label = listView.getLabel();
            PageReference ref = new PageReference('/'+ Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix() +'?fcf='+listViewId);
            listViewWrapper.url = ref.getUrl();     
            listViewWrapper.recordCount = ssc.getRecords().size();
            listViewWrapperMap.put(listView.getLabel() ,listViewWrapper);
        }
        
        return listViewWrapperMap;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTodayReportLeads() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Lead');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Leads_Today__c> settings = Leads_Today__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTodayReportOpportunities() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Opportunity');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Opportunities_Today__c> settings = Opportunities_Today__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTodayReportCases() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Case');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Cases_Today__c> settings = Cases_Today__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTodayReportTasks() {
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Tasks_Today__c> settings = Tasks_Today__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            PageReference ref = new PageReference('/007?fcf='+ settings.get(String.valueOf(ctr)).List_View_Id__c);            
            String currentUserId = UserInfo.getUserId();
            wrapper.recordCount = Database.countQuery(settings.get(String.valueOf(ctr)).Task_Query__c);            
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;            
            wrapper.url = ref.getUrl();
            reportList.add(wrapper);
            ctr++;
        }

        return reportList;
    }


    //==============================================================

    @AuraEnabled
    public static List<ListViewWrapper> getThisWeekReportLeads() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Lead');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Leads_This_Week__c> settings = Leads_This_Week__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getThisWeekReportOpportunities() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Opportunity');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Opportunities_This_Week__c> settings = Opportunities_This_Week__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getThisWeekReportCases() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Case');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String, Cases_This_Week__c> settings = Cases_This_Week__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getThisWeekReportTasks() {
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Tasks_This_Week__c> settings = Tasks_This_Week__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            PageReference ref = new PageReference('/007?fcf='+ settings.get(String.valueOf(ctr)).List_View_Id__c);
            String currentUserId = UserInfo.getUserId();
            wrapper.recordCount = Database.countQuery(settings.get(String.valueOf(ctr)).Task_Query__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;            
            wrapper.url = ref.getUrl();
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    //==============================================================

    @AuraEnabled
    public static List<ListViewWrapper> getTotalReportLeads() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Lead');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Leads_Total__c> settings = Leads_Total__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTotalReportOpportunities() {
        Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Opportunity');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Opportunities_Total__c> settings = Opportunities_Total__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTotalReportCases() {
      Map<String, ListViewWrapper> listViewWrapper = SalesAgentDesktopController.getListViewWrapper('Case');
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String, Cases_Total__c> settings = Cases_Total__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            wrapper = listViewWrapper.get(settings.get(String.valueOf(ctr)).List_View_Name__c);
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

    @AuraEnabled
    public static List<ListViewWrapper> getTotalReportTasks() {
        List<ListViewWrapper> reportList = new List<ListViewWrapper>();
        Integer ctr = 1;
        Map<String,Tasks_Total__c> settings = Tasks_Total__c.getAll();
        ListViewWrapper wrapper =  new ListViewWrapper();
        while (ctr <= settings.size() ){
            PageReference ref = new PageReference('/007?fcf='+ settings.get(String.valueOf(ctr)).List_View_Id__c);
            String currentUserId = UserInfo.getUserId();
            wrapper.recordCount = Database.countQuery(settings.get(String.valueOf(ctr)).Task_Query__c);            
            wrapper.label = settings.get(String.valueOf(ctr)).Label__c;            
            wrapper.url = ref.getUrl();
            reportList.add(wrapper);
            ctr++;
        }
        return reportList;
    }

}