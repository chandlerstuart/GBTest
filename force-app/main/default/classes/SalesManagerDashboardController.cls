public with sharing class SalesManagerDashboardController {
    
    //String Constants 
    private static final String ALL_TEAM = 'All Teams';
    private static final String EU_TEAM_1 = 'S- EU 0-7 Sales Team';
    private static final String EU_TEAM_2 = 'S- EU 8+ Sales Team';
    private static final String LIVE_AGENT_TEAM = 'S- Live Agent';
    private static final String RETURNING_TRAVELLER_TEAM = 'S- Returning Traveller';
    private static final String ROW_LONG_HAUL_TEAM = 'S- ROW-Long Haul Sales Team';
    private static final String ROW_LONG_MID_TEAM = 'S- ROW-Mid Haul Sales Team';
    private static final String SPECIALIST_TEAM = 'S- Specialist Sales Team';
    private static final String UK_TEAM_1 = 'S- UK 0-8 Sales Team';
    private static final String UK_TEAM_2 = 'S- UK 9+ Sales Team';
    private static final String UNKNOWN_LEADS_SALES_TEAM = 'S- Unknown Leads Sales Team';
    
    private static final String LEAD_NEW = 'New';
    private static final String LEAD_CONTACT_ATTEMPTED = 'Contact Attempted';
    
    private static final String OPP_RECOMMENDATION = '1. Recommendations';
    private static final String OPP_QUOTE_SENT = '2. Quote Sent';
    private static final String OPP_CLOSED = '3. Close Sale';
    private static final String OPP_CUST_ACCEPTED = '4. Customer Accepted';
    
    private static final String TASK_TYPE_CALL = 'Call Back Request';
    
    private static final String STRING_YES = 'Yes';
    private static final String STRING_NO = 'No';
    
    private static final String CASE_CLOSED = 'Closed';
    
    private static final Id RT_SERVICE_CASE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();
    private static final Id RT_AMENDMENT_CASE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Amendment').getRecordTypeId();
    private static final Id RT_ADMIN_CASE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Admin').getRecordTypeId();
    private static final Id RT_COMPLAINT_CASE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
    
    public List<SalesUserWrapper> salesUserWrapperList {get; set;}
    public String filterPicklist { get; set; }
    public Boolean noUser { get; set; }
    
    //Constructor - Value initialization
    public SalesManagerDashboardController(){
        
        //filterPicklist = new List<SelectOption>();
        noUser = false;
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        Set<String> userTeams = new Set<String>();
        userTeams.add(EU_TEAM_1);
        userTeams.add(EU_TEAM_2);
        userTeams.add(LIVE_AGENT_TEAM);
        userTeams.add(RETURNING_TRAVELLER_TEAM);
        userTeams.add(ROW_LONG_HAUL_TEAM);
        userTeams.add(ROW_LONG_MID_TEAM);
        userTeams.add(SPECIALIST_TEAM);
        userTeams.add(UK_TEAM_1);
        userTeams.add(UK_TEAM_2);
        userTeams.add(UNKNOWN_LEADS_SALES_TEAM);
        
        for(Group g : [Select Id from Group where type='Queue' and Name IN: userTeams]){
            queueIds.add(g.Id);
        }
        for(GroupMember u : [Select UserOrGroupId From GroupMember where GroupId IN: queueIds]){
            userIdSet.add(u.UserOrGroupId);
        }
        System.debug('###queueIds' + queueIds);
        System.debug('###userIdSet' + userIdSet);
        if(userIdSet != null) getValues(userIdSet);
        else{
            salesUserWrapperList = new List<SalesUserWrapper>();
            noUser = true;
        }
        // filterPicklist.add(new SelectOption('EU Team', 'EU Team'));
        // filterPicklist.add(new SelectOption('UK Team', 'UK Team'));
        // filterPicklist.add(new SelectOption('Specialist Team', 'Specialist Team'));
        // filterPicklist.add(new SelectOption('ROW Team', 'ROW Team'));
        // filterPicklist.add(new SelectOption('Sales Agent Team', 'Sales Agent Team'));
    }
    
    //Method called when filter picklist is changed by the user
    public void changeFilter(){
        salesUserWrapperList = new List<SalesUserWrapper>();
        Set<String> userTeams = new Set<String>();
        Set<Id> queueIds = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        if(filterPicklist == ALL_TEAM){
            userTeams.add(EU_TEAM_1);
            userTeams.add(EU_TEAM_2);
            userTeams.add(LIVE_AGENT_TEAM);
            userTeams.add(RETURNING_TRAVELLER_TEAM);
            userTeams.add(ROW_LONG_HAUL_TEAM);
            userTeams.add(ROW_LONG_MID_TEAM);
            userTeams.add(SPECIALIST_TEAM);
            userTeams.add(UK_TEAM_1);
            userTeams.add(UK_TEAM_2);
            userTeams.add(UNKNOWN_LEADS_SALES_TEAM);
        }
        else if(filterPicklist == EU_TEAM_1){
            userTeams.add(EU_TEAM_1);
        }
        else if(filterPicklist == EU_TEAM_2){
            userTeams.add(EU_TEAM_2);
        }
        else if(filterPicklist == LIVE_AGENT_TEAM){
            userTeams.add(LIVE_AGENT_TEAM);
        }
        else if(filterPicklist == RETURNING_TRAVELLER_TEAM){
            userTeams.add(RETURNING_TRAVELLER_TEAM);
        }
        else if(filterPicklist == ROW_LONG_HAUL_TEAM){
            userTeams.add(ROW_LONG_HAUL_TEAM);
        }
        else if(filterPicklist == ROW_LONG_MID_TEAM){
            userTeams.add(ROW_LONG_MID_TEAM);
        }
        else if(filterPicklist == SPECIALIST_TEAM){
            userTeams.add(SPECIALIST_TEAM);
        }
        else if(filterPicklist == UK_TEAM_1){
            userTeams.add(UK_TEAM_1);
        }
        else if(filterPicklist == UK_TEAM_2){
            userTeams.add(UK_TEAM_2);
        }
        else if(filterPicklist == UNKNOWN_LEADS_SALES_TEAM){
            userTeams.add(UNKNOWN_LEADS_SALES_TEAM);
        }
        for(Group g : [Select Id from Group where type='Queue' and Name IN: userTeams]){
            queueIds.add(g.Id);
        }
        for(GroupMember u : [Select UserOrGroupId From GroupMember where GroupId IN: queueIds]){
            userIdSet.add(u.UserOrGroupId);
        }
        
        if(userIdSet != null) getValues(userIdSet);
        else{
            salesUserWrapperList = new List<SalesUserWrapper>();
            noUser = true;
        }
    }
    
    //Method called to populate the table
    private void getValues(Set<Id> userIdSet){
        Map<Id, List<Lead>> ownerIdLeadMap = new Map<Id, List<Lead>>();
        Map<Id, List<Opportunity>> ownerIdOppMap = new Map<Id, List<Opportunity>>();
        Map<Id, List<Case>> ownerIdCaseMap = new Map<Id, List<Case>>();
        Map<Id, List<Event>> ownerIdTaskMap = new Map<Id, List<Event>>();
        Map<Id, Boolean> ownerOnlineMap = new Map<Id, Boolean>();
        salesUserWrapperList = new List<SalesUserWrapper>();
        Integer newLeads;
        Integer diarisedLeads;
        Integer recommendationOpp;
        Integer quoteSentOpp;
        Integer closeOpp;
        Integer custAcceptedOpp;
        Integer cases;
        Integer taskCallBacks;
        Integer leadTotal;
        Integer oppTotal;
        Integer caseTotal;
        Integer taskTotal;
        String online;
        
        //Get Leads for user
        for(Lead l : [SELECT OwnerId, Status, CreatedDate, Diarydate__c FROM Lead WHERE OwnerId IN: userIdSet AND IsConverted = false AND (Status <>: ApplicationConstant.LEAD_STATUS_DUPLICATE AND Status <>: ApplicationConstant.LEAD_NO_SALE AND Status <>: ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED)]){
            if(!ownerIdLeadMap.containsKey(l.OwnerId)){
                ownerIdLeadMap.put(l.OwnerId, new List<Lead>());
            }
            ownerIdLeadMap.get(l.OwnerId).add(l);
            
        }
        //Get Opportunity for user
        for(Opportunity o : [SELECT OwnerId, StageName, CreatedDate, Diarydate__c FROM Opportunity WHERE OwnerId IN: userIdSet AND (StageName =: OPP_RECOMMENDATION OR StageName =: OPP_QUOTE_SENT OR StageName =: OPP_CUST_ACCEPTED OR StageName =: OPP_CLOSED)]){
            if(!ownerIdOppMap.containsKey(o.OwnerId)){
                ownerIdOppMap.put(o.OwnerId, new List<Opportunity>());
            }
            ownerIdOppMap.get(o.OwnerId).add(o);
        }
        //Get Cases for user
        for(Case c : [SELECT OwnerId, Status, CreatedDate, Booking__c FROM Case WHERE OwnerId IN: userIdSet AND (RecordTypeId =: RT_COMPLAINT_CASE OR RecordTypeId =: RT_SERVICE_CASE OR RecordTypeId =: RT_ADMIN_CASE OR RecordTypeId =: RT_AMENDMENT_CASE) AND Status <>: CASE_CLOSED]){
            if(!ownerIdCaseMap.containsKey(c.OwnerId)){
                ownerIdCaseMap.put(c.OwnerId, new List<Case>());
            }
            ownerIdCaseMap.get(c.OwnerId).add(c);
        }
        //Get Tasks for Users 
        for(Event t : [SELECT OwnerId, Type, CreatedDate, StartDateTime, Subject FROM Event WHERE OwnerId IN: userIdSet AND Subject =: TASK_TYPE_CALL AND IsInvalidCallBack__c = FALSE AND StartDateTime >=: Date.Today()]){
            if(!ownerIdTaskMap.containsKey(t.OwnerId)){
                ownerIdTaskMap.put(t.OwnerId, new List<Event>());
            }
            ownerIdTaskMap.get(t.OwnerId).add(t);
        }
        
        // for(AuthSession auth : [SELECT LastModifiedDate,LoginType,NumSecondsValid,SessionType,UsersId 
        //                       FROM AuthSession 
        //                       WHERE SessionType = 'UI'
        //                       AND LoginType = 'Application' 
        //                       AND UsersId IN: userIdSet ]){
        //         if((System.now().hourGMT() - auth.LastModifiedDate.hourGMT()) < 1 ){
        //             ownerOnlineMap.put(auth.UsersId, True);
        //         }else{
        //             ownerOnlineMap.put(auth.UsersId, False);
        //         }
        //     }
        for(Sales_Agent_Attributes__c saa : [SELECT Sales_Rep__c, Online__c FROM Sales_Agent_Attributes__c WHERE Sales_Rep__c IN: userIdSet]){
            ownerOnlineMap.put(saa.Sales_Rep__c, saa.Online__c);
        }
        
        for(User u : [SELECT Id, Name FROM User WHERE Id =: userIdSet]){
            online = STRING_NO;
            newLeads = 0;
            diarisedLeads = 0;
            recommendationOpp = 0;
            quoteSentOpp = 0;
            closeOpp = 0;
            custAcceptedOpp = 0;
            cases = 0;
            taskCallBacks = 0;
            oppTotal = 0;
            leadTotal = 0;
            caseTotal = 0;
            taskTotal = 0;
            if(ownerIdLeadMap != null){
                if(ownerIdLeadMap.containsKey(u.Id)){
                    for(Lead l : ownerIdLeadMap.get(u.Id)){
                        if(l.Status == LEAD_NEW) newLeads++;
                        else if(l.Diarydate__c <= Date.Today()) diarisedLeads++;
                        // if(l.CreatedDate == Date.Today()){
                        //     if(l.Status == LEAD_NEW) newLeads++;
                        //     else if(l.Status == LEAD_CONTACT_ATTEMPTED) diarisedLeads++;
                        // }
                        leadTotal++;
                    } 
                }
            }
            // = newLeads + diarisedLeads;
            if(ownerIdOppMap != null){
                if(ownerIdOppMap.containsKey(u.Id)){
                    for(Opportunity o : ownerIdOppMap.get(u.Id)){
                        //if(o.CreatedDate == Date.Today()){
                            if(o.StageName == OPP_RECOMMENDATION && o.Diarydate__c <= Date.Today()) recommendationOpp++;
                            else if(o.StageName == OPP_QUOTE_SENT && o.Diarydate__c <= Date.Today()) quoteSentOpp++;
                            else if(o.StageName == OPP_CLOSED && o.Diarydate__c <= Date.Today()) closeOpp++;
                            else if(o.StageName == OPP_CUST_ACCEPTED && o.Diarydate__c <= Date.Today()) custAcceptedOpp++;
                        //}
                        oppTotal++;
                    }
                }
            }
            // = recommendationOpp + quoteSentOpp + closeOpp + custAcceptedOpp;
            if(ownerIdCaseMap != null){
                if(ownerIdCaseMap.containsKey(u.Id)){
                    for(Case c : ownerIdCaseMap.get(u.Id)){
                        if(c.CreatedDate >= System.Today()) cases++;
                        caseTotal++;
                    }
                }
            }
            //  = cases;
            if(ownerIdTaskMap != null){
                if(ownerIdTaskMap.containsKey(u.Id)){
                    for(Event t : ownerIdTaskMap.get(u.Id)){
                        if(t.StartDateTime == Date.Today()) taskCallBacks++;
                        taskTotal++;
                    }
                }
            }
            if(ownerOnlineMap != null){
                if(ownerOnlineMap.containsKey(u.Id)){
                    if(ownerOnlineMap.get(u.Id) == true) online = STRING_YES;
                    else online = STRING_NO;
                }
            }
            salesUserWrapperList.add(new salesUserWrapper(u.Name, online, newLeads, diarisedLeads, recommendationOpp, quoteSentOpp, closeOpp, custAcceptedOpp, cases, taskCallBacks, leadTotal, oppTotal, caseTotal, taskTotal));  
        }
    }
}