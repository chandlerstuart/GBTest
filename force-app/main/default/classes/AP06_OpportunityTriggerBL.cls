/**
   @Author: Renz Melecotones
   @name: AP06_OpportunityTriggerBL
   @CreateDate: 06.04.2016
   @Description: Business Logic Class for AP06_OpportunityTriggerBL
   @Modification: 20/12/2016 : SM : No longer update old Events, we delete them instead as per Tom H.
   @Modification: 03/01/2017 : SM : Method updateMonthlySalesTargetRollup now calls from WithoutSharingUtility.cls
   @Version <1.0>

History
------- 
Ver. Author        Date        Detail
1.1  J.Radcliffe   2016-06-19  Implementing the 'Phased Code Removal' custom setting to support with the phased removal of redundant code (Housekeeping)
1.2  J.Radcliffe   2018-11-06  New Method setDefaultBusinessUnitAndBookingSystem
1.3  J.Radcliffe   2019-07-04  New Method updateCustomerCallBackDateTime
1.4  J.Radcliffe   2019-07-04  Comment out redundant methods - IFramework Phase 1
1.5  J.Radcliffe   2019-10-17  Comment out redundant methods - IFramework Phase 2
1.6  J.Radcliffe   2021-11-02  New Method calculateQuoteShareId
1.7  J.Radcliffe   2023-04-04  New method formatOpportunityQuoteParagraphs
*/ 
public with sharing class AP06_OpportunityTriggerBL
{   

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP06_OpportunityTriggerBL';
    @testVisible public static DateTime currentDTOverride;

    //static Map<Id, 
    public static final Map<String, Id> oppRecordTypes;
    static{
        oppRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity']){
            oppRecordTypes.put(recType.DeveloperName, recType.Id);
        }
    }

         /**
     ** @Author: Simon Molloy
     ** @Method Name: updateCallbackDateTime
     ** @Description: Updates Call Back Date Time with Diary Date + Call Back Hour / Minute (if populated)
     **
     **/    
    public static void updateCallbackDateTime(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        if (null != oldOpps){
            for (Opportunity o : newOpps){
                boolean isError = false;
                Opportunity oldOpp = oldOpps.get(o.Id);
                if (o.Call_Back_Hour__c != oldOpp.Call_Back_Hour__c ||
                    o.Call_Back_Minute__c != oldOpp.Call_Back_Minute__c ||
                    o.DiaryDate__c != oldOpp.DiaryDate__c){
                    if (null != o.Call_Back_Hour__c || null != o.Call_Back_Minute__c){
                        if (null != o.Call_Back_Hour__c && null == o.Call_Back_Minute__c){
                            //2016-12-09 : SM : Defaulting minutes to '00' if Hour is selected
                            //o.addError('Please select a Call Back Minute value for this Opportunity');
                            //isError = true;
                            o.Call_Back_Minute__c = '00';
                        }
                        if (null != o.Call_Back_Minute__c && null == o.Call_Back_Hour__c){
                            o.addError('Please select a Call Back Hour value for this Opportunity');
                            isError = true;
                        }
                        
                        if (!isError){
                            o.RequestedCallbacktimedate__c = buildCallBackDateTime(o);
                        }
                    }
                    if (null == o.Call_Back_Hour__c && null == o.Call_Back_Minute__c){
                        if (null != o.RequestedCallbacktimedate__c) o.RequestedCallbacktimedate__c = null;
                    }
                }
            }
        }else {
            for (Opportunity o : newOpps){
                boolean isError = false;
                if (null != o.Call_Back_Hour__c || null != o.Call_Back_Minute__c){
                    if (null != o.Call_Back_Hour__c && null == o.Call_Back_Minute__c){
                        //2016-12-09 : SM : Defaulting minutes to '00' if Hour is selected
                        //o.addError('Please select a Call Back Minute value for this Opportunity');
                        //isError = true;
                        o.Call_Back_Minute__c = '00';
                    }
                    if (null != o.Call_Back_Minute__c && null == o.Call_Back_Hour__c){
                        o.addError('Please select a Call Back Hour value for this Opportunity');
                        isError = true;
                    }
                    
                    if (!isError){
                        o.RequestedCallbacktimedate__c = buildCallBackDateTime(o);
                    }
                }
            }
        }
       
    }
    
     private static DateTime buildCallBackDateTime(Opportunity o){
        if (null == o.DiaryDate__c) return null;
        Time myTime = Time.newInstance(integer.valueOf(o.Call_Back_Hour__c), integer.valueOf(o.Call_Back_Minute__c), 0, 0);

        DateTime dt = DateTime.newInstance(o.Diarydate__c, myTime);
        
        return dt;
    }
    
    //1.2 - This method sets the Default Golfbreaks Business Unit and Booking System on the Opportunity if none is specified
    //Note - To be run in a Before Trigger Context
    public static void setDefaultBusinessUnitAndBookingSystem(List<Opportunity> oppList){
        
        system.debug('setDefaultBusinessUnitAndBookingSystem>Start');
                
        //Query Default Golfbreaks Business Unit record - This will retrieve the record flagged as default first followed by the 'UK' business unit (if none has been flagged)
        Golfbreaks_Business_Unit__c[] gbus = [Select Id, Name, Default_Booking_System__c From Golfbreaks_Business_Unit__c WHERE IsDefault__c = true OR Name LIKE '%UK%' ORDER By IsDefault__c ASC LIMIT 2];
        if(gbus.size()>0){
            system.debug('setDefaultBusinessUnitAndBookingSystem>RetrievedDefaultBusinessUnit');
            Id defaultBusinessUnitId = gbus[0].Id;
            String defaultBookingSystem = gbus[0].Default_Booking_System__c;
            for(Opportunity o :oppList){
                if(o.Golfbreaks_Business_Unit__c == null){
                    system.debug('setDefaultBusinessUnitAndBookingSystem>AssigningDefaultBusinessUnitToOpp');
                    o.Golfbreaks_Business_Unit__c = defaultBusinessUnitId;
                    o.Booking_System__c = defaultBookingSystem;
                }
            }
        }     
        
        system.debug('setDefaultBusinessUnitAndBookingSystem>Stop');
        
    }
        
    /**
     ** @Author: J Radcliffe
     ** @Method Name: updateCustomerCallBackDateTime
     ** @Description: Set the DST aware time field value.
     **
     **/    
    //1.3
    public static void updateCustomerCallBackDateTime(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){

        try {
            if ((Trigger.isInsert && null != newOpps && !newOpps.isEmpty()) ||               
              (Trigger.isUpdate && oldOpps!=null && !oldOpps.isEmpty())){

                TimeZone tz = TimeZone.getTimeZone('Europe/London');
                Datetime startDt,adjustedDt;
                Integer tzOffset;
  
                for (Opportunity opp : newOpps){
          
                    if (Trigger.isInsert && opp.Customer_Call_Back_Date_Time__c==null) continue;          
                    if (Trigger.isUpdate && (!oldOpps.containsKey(opp.Id) || oldOpps.get(opp.Id).Customer_Call_Back_Date_Time__c==opp.Customer_Call_Back_Date_Time__c)) continue;
                      
                      
                    if (Trigger.isUpdate && oldOpps.get(opp.Id).Customer_Call_Back_Date_Time__c!=null && opp.Customer_Call_Back_Date_Time__c==null){
                        // date field is set from non-null to null == blank the target field.
                        opp.Customer_Call_Back_Time_DST__c=null;
            
                    } else {
                        // new Opp with the date field set, or updated Opp and the date value has changed.                   
                        startDt = opp.Customer_Call_Back_Date_Time__c;
              
                        tzOffset = tz.getOffset(startDt);
                        adjustedDt = startDt.addSeconds(tzOffset/1000);
                        
                        opp.Customer_Call_Back_Time_DST__c = String.valueOf(adjustedDt.timeGmt()).Left(5);
                    }          
                }
            }
        }catch (Exception e){
            PlatformLogManager.logExceptions(e, 'AP06_OpportunityTriggerBL', 'updateCustomerCallBackDateTime');
        }      
    }

    //1.6+
    //This method set the Unique Identifier for an Opportunity's Quote Lite Preview
    //Comprised of encoded SF Id interspersed by current D/T values to guarantee it is uniqueness.
    public static void calculateQuoteShareId(List<Opportunity> opportunities){

        List<Opportunity> oppsForUpdate = new List<Opportunity>();

        for(Opportunity opp : opportunities){
            if(opp.QuoteShareId__c == null){
                DateTime currentDT = (currentDTOverride != null && Test.isRunningTest())?currentDTOverride:system.now();//The key will be derived from both the current date/time and randomly calculated characters
                String encodedId = EncodingUtil.base64Encode(Blob.valueof(opp.Id));              
                String part1 = encodedId.substring(0,encodedId.length()/4);
                String part2 = encodedId.substring(encodedId.length()/4,encodedId.length()/2);
                String part3 = encodedId.substring(encodedId.length()/2,(encodedId.length()/4)*3);
                String part4 = encodedId.substring((encodedId.length()/4)*3,encodedId.length());
                String quoteShareId;
                quoteShareId = 'Q-'+part1;
                quoteShareId = quoteShareId+'-'+currentDT.millisecond()+currentDT.hour();
                quoteShareId = quoteShareId+'-'+part2;
                quoteShareId = quoteShareId+'-'+currentDT.minute()+currentDT.second()+currentDT.year();
                quoteShareId = quoteShareId+'-'+part3;
                quoteShareId = quoteShareId+'-'+currentDT.day()+currentDT.month();          
                quoteShareId = quoteShareId+'-'+part4;    
                if(Trigger.isAfter && Trigger.isInsert){
                    oppsForUpdate.add(new Opportunity(Id=opp.Id,QuoteShareId__c=quoteShareId));//Cannot modify trigger record after insert, create new and update
                }else{
                    opp.QuoteShareId__c = quoteShareId;
                }
            }
        }
        if(oppsForUpdate.size()>0){
            Database.SaveResult[] results = Database.update(oppsForUpdate,false);
            Golfbreaks.PlatformLogManager.logExceptions(results,'AP06_OpportunityTriggerBL','calculateQuoteShareId',oppsForUpdate);
        }
    }

    //1.7+ - This method replaces line breaks in quote paragraphs (populated from Clubhouse) with HTML <p> tags, so they are correctly formatted when featured in HTML emails (e.g. the Quote Email).
    public static void formatOpportunityQuoteParagraphs(Map<Id,Opportunity> oldMap, List<Opportunity> newList){

        try{
            if(Trigger.isInsert){
                if(newList == null || newList.size()==0) return; 
                for(Opportunity opp : newList){
                    if(opp.Signoff_Paragraph__c != null) opp.Signoff_Paragraph__c = applyHTMLFormatting(opp.Signoff_Paragraph__c);
                    if(opp.EmailIntroductoryText__c != null) opp.EmailIntroductoryText__c = applyHTMLFormatting(opp.EmailIntroductoryText__c);
                }
            }else if(Trigger.isUpdate){
                system.debug('updating > isUpdated');
                if(newList == null || newList.size()==0 || oldMap == null || oldMap.size()==0) return;
                system.debug('list size > '+newList.size());
                for(Opportunity newOpp : newList){
                    Opportunity oldOpp = oldMap.get(newOpp.Id);
                    if(oldOpp == null) continue;
                    if(oldOpp.Signoff_Paragraph__c != newOpp.Signoff_Paragraph__c && newOpp.Signoff_Paragraph__c != null) newOpp.Signoff_Paragraph__c = applyHTMLFormatting(newOpp.Signoff_Paragraph__c);
                    if(oldOpp.EmailIntroductoryText__c != newOpp.EmailIntroductoryText__c && newOpp.EmailIntroductoryText__c != null) newOpp.EmailIntroductoryText__c = applyHTMLFormatting(newOpp.EmailIntroductoryText__c);
                }
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'AP06_OpportunityTriggerBL','formatOpportunityQuoteParagraphs');
        }

    }

    //1.7+
    public static String applyHTMLFormatting(String input){
        if(input == null) return null;
        if(!input.startsWith('<p>')) input = '<p>'+input;
        if(!input.endsWith('</p>')) input = input+'</p>';
        input = input.replace('\r','</p><p>').replace('\n','</p><p>').replace('\r\n','</p><p>');
        return input;
    }

         /**
       *  Verifies if lead owner has changed
       *  @name: checkLeadOwnerUpdate
       *  @developer: Merari Cebrian
       *  @date: 5/19/2016
       *  @requirement: D-0586
     */
    /*1.5 
    public static void checkOppOwnerUpdate(List<Opportunity> newOppList, Map<Id,Opportunity> oldOppMap){
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        for(Opportunity newOpp : newOppList) {
            if(oldOppMap.containsKey(newOpp.Id) && newOpp.OwnerId != oldOppMap.get(newOpp.Id).OwnerId) {
                oppToUpdate.add(newOpp);
            }
        }

        //if(!oppToUpdate.isEmpty()) AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(new List<Lead>(), oppToUpdate);

        if( !oppToUpdate.isEmpty() ){
            RequestQueueUtility.populateRequestQueueRecords(oppToUpdate);
            //1.1 - Check the 'Disable SAA Capacity Calculation' setting before executing
            /*1.4
            if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){
            	AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(new List<Lead>(), oppToUpdate);  
            }    
        } 
    }*/

   /**
   *  This method is used to create an event if the Call Back Date Time is updated 
   *  @name: createEvent
   *  @developer: Jerella Ledesma 04/11/2016
   *  @modification: 20/12/2016 : SM : Instead of marking unwanted events as 'Invalid Callback' we now 
   *  Delete them, as per a request from Tom Herridge
   *  @param: oldOpportunityList - get Trigger.old from OpportunityTrigger; of Map<Id, Opportunity> data type
   *  @param: oppList - get Trigger.new from OpportunityTrigger; of Map<Id, Opportunity> data type
   */
   /*1.4
    public static void createUpdateEvent(Map<Id,Opportunity> oppList, Map<Id,Opportunity> oldOpportunityList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Id, Opportunity> oppListToUpdate = new Map<Id, Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Set<DateTime>> eventRelatedtoOpportunity = new Map<Id, Set<DateTime>>();
        List<Event> eventToCreate = new List<Event>();
        Event event;
        Map<Id, List<Event>> oppIdToEvents = new Map<Id, List<Event>>();
        List<Event> eventList = new List<Event>();
        List<Event> eventToUpdate = new List<Event>();
        List<Event> eventToDelete = new List<Event>();
        
        try{
            if(oppList.size() > 0){
                for(Opportunity oppRec : oppList.values()){
                    oppIds.add(oppRec.Id);
                }
            }
            
            for(Event eventRec : [SELECT OwnerId, WhatId, StartDateTime, Subject FROM Event WHERE WhatId IN : oppIds AND EventIsClosed__c = false]){
                if(eventRelatedtoOpportunity.containsKey(eventRec.WhatId)){
                    eventRelatedtoOpportunity.get(eventRec.WhatId).add(eventRec.StartDateTime);
                }
                else{
                    eventRelatedtoOpportunity.put(eventRec.WhatId, new Set<DateTime>{eventRec.StartDateTime});
                }
                
                if(oppIdToEvents.containsKey(eventRec.WhatId)){
                    oppIdToEvents.get(eventRec.WhatId).add(eventRec);
                }
                else{
                    oppIdToEvents.put(eventRec.WhatId, new List<Event>{eventRec});
                }
            }
            
            if(oppList.size() > 0){
                for(Opportunity oppRec : oppList.values()){
                    if(oppRec.RequestedCallbacktimedate__c <> null && oppRec.Reminder_Event__c && oppRec.RequestedCallbacktimedate__c <> oldOpportunityList.get(oppRec.Id).RequestedCallbacktimedate__c){  
                        event = new Event(
                        OwnerId = oppRec.OwnerId,
                        StartDateTime = oppRec.RequestedCallbacktimedate__c,
                        EndDateTime = oppRec.RequestedCallbacktimedate__c,
                        ReminderDateTime = (oppRec.RequestedCallbacktimedate__c).addMinutes(-15),
                        IsReminderSet = true,
                        ActivityDateTime = oppRec.RequestedCallbacktimedate__c,
                        Subject = 'Call Back Request',
                        WhatId = oppRec.Id
                        );
                        if(eventRelatedtoOpportunity.containsKey(oppRec.Id)){
                            if(!eventRelatedtoOpportunity.get(oppRec.Id).contains(oppRec.RequestedCallbacktimedate__c)){
                                eventToCreate.add(event);
                            }
                        }
                        else{
                            eventToCreate.add(event);
                        }
                        
                        if(oppIdToEvents.containsKey(oppRec.Id)){
                            eventList = oppIdToEvents.get(oppRec.Id);
                            for(Event ev : eventList){
                                
                                if(ev.Subject == 'Call Back Request' && oppRec.RequestedCallbacktimedate__c <> oldOpportunityList.get(oppRec.Id).RequestedCallbacktimedate__c && ev.StartDateTime < oppRec.RequestedCallbacktimedate__c) {
                                    //We now no longer update these events, we delete them
                                    //ev.IsInvalidCallBack__c = true;
                                    //ev.StartDateTime = DateTime.Now();
                                    //ev.EndDateTime = DateTime.Now();
                                    //ev.IsReminderSet = false;
                                    
                                    //eventToUpdate.add(ev);
                                    eventToDelete.add(ev);
                                }
                            }  
                        }
                    } else if (oppRec.RequestedCallbacktimedate__c == null && oppRec.RequestedCallbacktimedate__c <> oldOpportunityList.get(oppRec.Id).RequestedCallbacktimedate__c) {
                        
                        eventList = new List<Event>();
                        if(oppIdToEvents.containsKey(oppRec.Id)) {
                        
                            eventList = oppIdToEvents.get(oppRec.Id);
                            for(Event e: eventList) {
                                if(e.Subject == 'Call Back Request') {
                                    //We now no longer update these events, we delete them
                                    //e.IsInvalidCallBack__c = true;
                                    //e.StartDateTime = DateTime.Now();
                                    //e.EndDateTime = DateTime.Now();
                                    //e.IsReminderSet = false;
                                    //eventToUpdate.add(e);
                                    eventToDelete.add(e);
                                }
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'createUpdateEvent', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && eventToCreate.size() > 0){
                Database.SaveResult[] updateLeadList = Database.insert(eventToCreate, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'createUpdateEvent', CLASS_NAME, ApplicationConstant.LEAD_SOURCE_EVENT, 'Insert'));
            }
            
            if(eventToUpdate.size() > 0){
                Database.SaveResult[] updateLeadList = Database.update(eventToUpdate, false);
                String errorLogDescription;
                logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'createUpdateEvent', CLASS_NAME, ApplicationConstant.LEAD_SOURCE_EVENT, 'Update'));
            }
            
            if (eventToDelete.size() > 0){
                Database.DeleteResult[] deleteList = Database.delete(eventToDelete, false);
            }    
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/
    

    /**
       *  This method is used to update OppId on Account upon Opportunity creation
       *  @name: updateOppIdOnAccount
       *  @developer: Jerome To
       *  @param: 
       *  Modified by     Version     Change Date
       *  Merari Cebrian    2         17/05/2016    Added closed sales opportunity in the process
       */  
       /*1.4
    public static void updateOppIdOnAccount(List<Opportunity> oppList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        // For error checking
        Map<String, String> mapAccAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        Set<Id> accountIdSet = new Set<Id>();  
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> latestOpportunityIdSet = new Set<Id>();
        Map<Id, Id> oppBookingIdMap = new Map<Id, Id>();
        
        try{
            for(Opportunity oppRec : oppList){
                if(oppRec.RecordTypeId == oppRecordTypes.get(ApplicationConstant.OPPORTUNITY_RECORD_NEWSALES) && oppRec.AccountId <> null){                   
                    accountIdSet.add(oppRec.AccountId);        
                }
            }
            
            for(Account acct : [SELECT Id, OppId__c, BookingId__c, 
                                    (SELECT Id, AccountId, CreatedDate 
                                    FROM Opportunities 
                                    WHERE StageName <>: ApplicationConstant.OPP_STAGE_TRIPCOMPLETED 
                                    AND StageName <>: ApplicationConstant.OPP_STAGE_DUPLICATE 
                                    AND StageName <>: ApplicationConstant.OPP_STAGE_NOSALE 
                                    AND StageName <>: ApplicationConstant.OPP_STAGE_CANCELLED 
                                    AND (RecordTypeId =: ApplicationConstant.OPP_RECTYPEID_NSO OR RecordTypeId =: ApplicationConstant.OPP_RECTYPEID_CSO)
                                    ORDER BY CreatedDate desc) 
                                FROM Account WHERE Id IN: accountIdSet]){
                acct.OppId__c = '';
                acct.BookingId__c = '';
                if(!acct.Opportunities.isEmpty()){
                    acct.OppId__c = acct.Opportunities[0].Id;
                    latestOpportunityIdSet.add(acct.Opportunities[0].Id);
                }            
                accountsToUpdate.add(acct);
            }
    
            for(Booking__c bookRec : [SELECT Id, TECH_Opportunity__c FROM Booking__c WHERE TECH_Opportunity__c IN: latestOpportunityIdSet]){            
                oppBookingIdMap.put(bookRec.TECH_Opportunity__c , bookRec.Id);
            }
    
            for(Account acct : accountsToUpdate){
                if(!String.isEmpty(acct.OppId__c) && oppBookingIdMap.containsKey(acct.OppId__c)){
                    acct.BookingId__c = oppBookingIdMap.get(acct.OppId__c);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateOppIdOnAccount', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && accountsToUpdate.size() > 0){
                Database.SaveResult[] updateAccountMap = Database.update(accountsToUpdate, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateAccountMap, 'updateOppIdOnAccount', CLASS_NAME, ApplicationConstant.OBJECT_TYPE_ACCOUNT, 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/


    /**
       *  This method is used to update Monthly Sales Target Id
       *  @name: updateMonthlySalesTargetLookup
       *  @developer: Jerome To
       *  @param: 
       */  

       /*1.4
    public static void mapMonthlySalesTargetLookup(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<String> closedWonStageNames = new Set<String> { ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_DEPOSIT, ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_BALANCE, ApplicationConstant.OPPORTUNITY_STAGENAME_TRIP_COMPLETED };
        Set<String> salesAgentCloseDateSet = new Set<String>();
        Map<Id, String> opportunityWithUpdateMap = new Map<Id, String>();
        Map<String, Id> monthlySalesTargetIdAndSalesAgentCloseDateMap = new Map<String, Id>();

        try{
            for(Opportunity newOpp : newOppList){
                if (closedWonStageNames.contains(newOpp.Stagename)){
                    if(newOpp.TECH_Monthly_Sales_Target__c == null){
                        String salesAgentCloseDate = String.valueOf(newOpp.OwnerId).left(15) + String.valueOf(newOpp.CloseDate.month()) + String.valueOf(newOpp.CloseDate.year());
                        if (!salesAgentCloseDateSet.contains(salesAgentCloseDate)){
                            salesAgentCloseDateSet.add(salesAgentCloseDate);
                        }                
                        opportunityWithUpdateMap.put(newOpp.Id, salesAgentCloseDate);
                    }
                    if(oldOppMap <> null && 
                       oldOppMap.containskey(newOpp.Id) &&
                       (newOpp.OwnerId != oldOppMap.get(newOpp.Id).OwnerId || newOpp.CloseDate != oldOppMap.get(newOpp.Id).CloseDate)) {
                        String salesAgentCloseDateNew = 
        String.valueOf(newOpp.OwnerId).left(15) + String.valueOf(newOpp.CloseDate.month()) + String.valueOf(newOpp.CloseDate.year());
                        String salesAgentCloseDateOld = 
        String.valueOf(oldOppMap.get(newOpp.Id).OwnerId).left(15) + String.valueOf(oldOppMap.get(newOpp.Id).CloseDate.month()) + String.valueOf(oldOppMap.get(newOpp.Id).CloseDate.year());
                        if (!salesAgentCloseDateSet.contains(salesAgentCloseDateNew)){
                            salesAgentCloseDateSet.add(salesAgentCloseDateNew);
                        }
                        if (!salesAgentCloseDateSet.contains(salesAgentCloseDateOld)){
                            salesAgentCloseDateSet.add(salesAgentCloseDateOld);
                        }
                        opportunityWithUpdateMap.put(newOpp.Id, salesAgentCloseDateNew);
                    }
                }
            }

            if(!salesAgentCloseDateSet.isEmpty()){            
                for(Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id,TECH_Duplicate_Sales_Target__c FROM Monthly_Sales_Target__c WHERE TECH_Duplicate_Sales_Target__c in :salesAgentCloseDateSet]){
                    monthlySalesTargetIdAndSalesAgentCloseDateMap.put(monthlySalesTarget.TECH_Duplicate_Sales_Target__c , monthlySalesTarget.Id);
                }                      
            }
            for(Opportunity newOpp : newOppList){
                if(opportunityWithUpdateMap.keySet().contains(newOpp.Id)){
                    String salesAgentCloseDate = String.valueOf(newOpp.OwnerId).left(15) + String.valueOf(newOpp.CloseDate.month()) + String.valueOf(newOpp.CloseDate.year());
                    if(monthlySalesTargetIdAndSalesAgentCloseDateMap.containsKey(salesAgentCloseDate)){
                        newOpp.TECH_Monthly_Sales_Target__c = monthlySalesTargetIdAndSalesAgentCloseDateMap.get(salesAgentCloseDate);
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'mapMonthlySalesTargetLookup', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/


    /** 
       *  This method is used to update Roll up on Monthly Sales target
       *  This method now calls WithoutSharingUtility.updateMonthlySalesTargetRollup
       *  @name: updateMonthlySalesTargetRollup
       *  @developer: Jerome To
       *  @param: 
       */  
       /*1.4
    public static void updateMonthlySalesTargetRollup(List<Opportunity> newOppList , Map<Id, Opportunity> oldOppMap){
        
        WithoutSharingUtility.updateMonthlySalesTargetRollup(newOppList, oldOppMap);

    }*/
    
    /**
       *  This method is used to update the TotalPreviousOpportunities field in the associated lead record
       *  @name: updateTotalPreviousOpportunitiesOnLead
       *  @developer: Tristan Zantua
       *  @date: 5/14/2016
       *  @requirement: D-0404
       *  @param: bookingList - get Trigger.new from BookingTrigger of List<Booking__c> data type
     */
     /*1.4
    public static void updateTotalPreviousOpportunitiesOnLead(List<Opportunity> oppList) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Lead, Integer> leadsAndNumOfOpps = new Map<Lead, Integer>();
        Map<Id, Set<Id>> leadAndAcctId = new Map<Id, Set<Id>>();
        List<Lead> listOfLeadsToUpdate = new List<Lead>();

        List<Opportunity> opps = new List<Opportunity>();
        Map<Id, Integer> oppsPerAcctId = new Map<Id, Integer>();
        List<Id> acctIds = new List<id>();

        Map<Id, Integer> accountIdTotalOpps = new Map<Id, Integer>();

        try{
            //GetAllOpportunityAccount
            for (Opportunity opp : oppList) {
                if (opp.AccountId != null) {
                    acctIds.add(opp.AccountId);
                }
            }
            //Get count all opps related to opp account
            if (!acctIds.isEmpty()) {
                
                for (AggregateResult ar : [SELECT AccountId acctId, Count(id) totalOpps FROM Opportunity WHERE Opportunity.AccountId != null AND AccountId IN: acctIds GROUP BY AccountId]) {
                    accountIdTotalOpps.put((Id)ar.get('acctId'), (Integer)ar.get('totalOpps'));
                }
            }
            //Update Lead based on opp account
            if (!accountIdTotalOpps.isEmpty()) {
                for (Lead l : [SELECT id, Account__c, TotalPreviousOpportunities__c FROM Lead WHERE IsConverted = false AND Account__c IN: accountIdTotalOpps.keySet()]) {
                    l.TotalPreviousOpportunities__c = accountIdTotalOpps.get(l.Account__c);
                    listOfLeadsToUpdate.add(l);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateTotalPreviousOpportunitiesOnLead', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && listOfLeadsToUpdate.size() > 0){
                Database.SaveResult[] updateLeadList = Database.update(listOfLeadsToUpdate, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'updateTotalPreviousOpportunitiesOnLead', CLASS_NAME, 'Lead', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/
        
    /**
       *  This method checks if there are Opportunities with Status equal to Closed
       *  @name: checkStatusUpdates
       *  @developer: Recuerdo Bregente
       *  @param: Opportunity - get Trigger.new, Trigger.oldMap
     */
     /*1.4
     public static void checkStatusUpdates(List<Opportunity> oppList,  Map<Id,Opportunity> oldOppMap)
     {
         System.debug('checkStatusUpdates --- Start');
         List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> salesRep = new Set<Id>();
        
        
        try{
        
            for (Opportunity oppRec : oldOppMap.values()){
                salesRep.add(oppRec.OwnerId);
            }
            System.debug('checkStatusUpdates --- salesRep: ' +salesRep);
            
            Map<Id, Sales_Agent_Attributes__c> saaMap = new Map<Id, Sales_Agent_Attributes__c>();
            Map<Id, Sales_Agent_Attributes__c> saaToUpdateMap = new Map<Id, Sales_Agent_Attributes__c>();
            
            //MC - 2017-02-24 - Error log remediation #SG-445-3. FOR UPDATE added to reduce lock errors.
            for(Sales_Agent_Attributes__c saa : [SELECT Id, Sales_Rep__c, Current_Number_of_Open_Leads_Opps__c 
            									FROM Sales_Agent_Attributes__c 
            									WHERE Sales_Rep__c IN :salesRep AND (RecordType.DeveloperName = :ApplicationConstant.USP_SALES_AGENT_DEVNAME OR 
                                                RecordType.DeveloperName = :ApplicationConstant.USP_SALES_MANAGER_DEVNAME)
                                                FOR UPDATE]){
                 
                   if(saa.Current_Number_of_Open_Leads_Opps__c == null){
                       saa.Current_Number_of_Open_Leads_Opps__c = 0;
                   }
                   saaMap.put(saa.Sales_Rep__c, saa);     
            }
            
            // Go through every lead in the trigger
            for (Opportunity oppRec : oppList){
            
                // Added due to deffect D-0587 By Dee 05/21
                if(oppRec.IsClosed <> oldOppMap.get(oppRec.Id).IsClosed && oppRec.IsClosed && saaMap.containsKey(oldOppMap.get(oppRec.Id).OwnerId)){
                        if(!saaToUpdateMap.containsKey(oldOppMap.get(oppRec.Id).OwnerId)){
                            saaToUpdateMap.put(oldOppMap.get(oppRec.Id).OwnerId, saaMap.get(oldOppMap.get(oppRec.Id).OwnerId));
                        }
                        
                        if(saaToUpdateMap.get(oldOppMap.get(oppRec.Id).OwnerId).Current_Number_of_Open_Leads_Opps__c > 0){
                            saaToUpdateMap.get(oldOppMap.get(oppRec.Id).OwnerId).Current_Number_of_Open_Leads_Opps__c--;
                        }
                }
            }
            
            if(!saaToUpdateMap.isEmpty()){
                Database.SaveResult[] updatedsalesAgentList = database.update(saaToUpdateMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updatedsalesAgentList, 'checkStatusUpdates()', CLASS_NAME, 'Sales Agent Attribute', 'Update'));
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'checkStatusUpdates()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('checkStatusUpdates --- End');
     }*/
     
     /**
       *  This method is used to update the default values for Opportunity record  
       *  @name: populateOppDetails
       *  @developer: Patrick Villarica (ACN) - May 26, 2016
       *  @param: List<Opportunity> newCaseList from Trigger.New
       *          Map<Id, Opportunity> oldCaseMap from Trigger.OldMap
       */
    /*1.4
    public static void populateOppDetails(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
    
        for(Opportunity opp: newOppList) {
                
            if(oldOppMap.ContainsKey(opp.Id)) {
                
                if(opp.TECH_NVMCallBackUrgent__c != oldOppMap.get(opp.Id).TECH_NVMCallBackUrgent__c) {
    
                    opp.Reminder_Event__c = false;
                } else {
                    if(opp.RequestedCallbacktimedate__c <> null && opp.RequestedCallbacktimedate__c <> oldOppMap.get(opp.Id).RequestedCallbacktimedate__c) {
                        
                        opp.Reminder_Event__c = true;
                    }
                }
            }
        }    
    }*/
        
}