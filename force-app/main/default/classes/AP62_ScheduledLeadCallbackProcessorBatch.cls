/*
Name:  AP62_ScheduledLeadCallbackProcessorBatch.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------

Releases Leads from the Callback queue at Callback time minus 15.
Sends notifications as defined in the Custom Setting : CustomerCallbackNotificationListSetting__c
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-11-29  Initial development.
1.1  Mark Cane&    2016-12-03  Continued development.
1.2  Mark Cane&    2016-12-05  Added Notify_Owner_Manager__c settings behaviour and lead ownership requery.
1.3  Mark Cane&    2016-12-06  Scheduling changes to align to a 15,30,45,0 pattern.
1.4  Mark Cane&    2016-12-07  Updated the linkUrl format to use console#
1.5  Mark Cane&    2016-12-13  Logic fix. Added 5m tolerance to allow Leads created after the correct release cycle (15 minute before CBT).
1.6  Mark Cane&    2016-12-14  Bug fix. Reset of userIds var for each notification - previously cumulative. 
1.7  Simon Molloy  2017-01-30  Changed call to getDMLLog as this is now private, use getSaveResultLog instead
1.8  Simon Molloy  2017-09-05  Added in OrgWideEmailAddress to the buildSingleEmailMessag method
1.9  Simon Molloy  2017-11-30  Corrected email message builder - cannot set SenderDisplayName if Org Wide Email address is used
*/
global with sharing class AP62_ScheduledLeadCallbackProcessorBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful{

    public static final String CLASS_NAME = 'AP62_ScheduledLeadCallbackProcessorBatch';

    @testVisible private static Integer messagesToSendCount { get; private set; } 
    @testVisible private static Set<Id> messageRecipientIds { get; private set; }
    
    private static final String CALLBACK_QUEUE_DEVELOPER_NAME = 'S_Callback_Leads'; // Move to ApplicationConstant.cls
    private static final String LEAD_SOURCE_WEBFORM_CALLBACK = 'Web Callback';

    private Id callBackQueueId;     
    private Datetime nowDt,nowPlus20mDt,nowMinus5mDt;

    public AP62_ScheduledLeadCallbackProcessorBatch(){ }
    
    // Schedulable implementation.
    public void execute(SchedulableContext sc){
        
        System.abortJob(sc.getTriggerId());     
        
        // if the current time is greater than 20:00pm then schedule for 08.30am the following day.
        // if the current time is between 08.30am and 21:00pm then reschedule for next whole 15 minute increment.
               
        nowDt  = DateTime.now();
        Integer intervalMinutes=0;
        
        DateTime nextRunTime;
        if (nowDt.hour() > 20 ){                        
            Datetime nextDayDt = nowDt.addDays(1);          
            nextRunTime = Datetime.newInstance(nextDayDt.year(), nextDayDt.month(), nextDayDt.day(), 8, 30, 0); //Datetime.newInstance(2008, 12, 1, 12, 30, 2);
            
        } else {
            
            if (nowDt.minute()<15){
                intervalMinutes = 15-(nowDt.minute()); // 13.03 - 15-3 = 12 13.03+12 = 13.15
            } else if (nowDt.minute()<30){
                intervalMinutes = 30-(nowDt.minute()); // 13.16 - 30-16 = 14 13.16+14 = 13.30
            } else if (nowDt.minute()<45){
                intervalMinutes = 45-(nowDt.minute()); // 13.38 - 45-38 = 7 13.38+7 = 13.45
            } else if (nowDt.minute()<60){
                intervalMinutes = 60-(nowDt.minute()); // 13.46 - 60-46 = 14 13.46+14 = 14.00
            }
            nextRunTime = nowDt.addMinutes(intervalMinutes);
        }
        
        String cronString = '0 ' + nextRunTime.minute() + ' ' + 
                            nextRunTime.hour() +' ' + nextRunTime.day() + ' ' + 
                            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        System.debug(LoggingLevel.ERROR,'cronString:'+cronString);
                
        System.schedule('Web Callback Lead Batch-'+nowDt.format(), cronString, new AP62_ScheduledLeadCallbackProcessorBatch());
        
        Database.executeBatch(new AP62_ScheduledLeadCallbackProcessorBatch(), 100);        
    }   
    // End Schedulable implementation.

    // Batchable implementation.
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        messageRecipientIds = new Set<Id>();
        
        nowDt = Datetime.now(); //'2016-12-03 08:45'
        nowPlus20mDt = nowDt.addMinutes(20); //'2016-12-03 09:05'
        nowMinus5mDt = nowDt.addMinutes(-5); //'2016-12-03 08:40' //1.5
        Datetime nowPlus1hDt = nowDt.addHours(1); //'2016-12-03 09:45'
        Datetime nowMinus1hDt = nowDt.addHours(-1); //'2016-12-03 07:45'
        
        List<Group> groups = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'];
        if (groups.size()>0) callBackQueueId=groups[0].Id;
        else return null; //todo add error logging/handling here.
                                
        String q = 'select Id, Name, CountriesInterested__c, Account__c, AssignedtoSAA__c, TravelGroupSize__c, LastName, ' +
                       'FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, CustomerLifetimeValue__c, ' +
                       'IsLeadAssigned__c, SpecialistSales__c, Bypass_SAA_Routing__c, ' +
                       'OwnerId, Owner.Name, ' +
                       'Customer_Call_Back_Date_Time__c,Agent_Call_Back_Date_Time__c';                        
        q+=' from Lead';
        q+=' where IsConverted = false';
        q+=' and SalesRegion__c != null and TravelGroupSize__c != null';
        q+=' and LeadSource=\''+LEAD_SOURCE_WEBFORM_CALLBACK+'\'';  
        q+=' and Customer_Call_Back_Date_Time__c!=null'; //'2016-12-03 09:00'
        //q+=' and ((OwnerId=:callBackQueueId and Customer_Call_Back_Date_Time__c < :nowPlus20mDt and Customer_Call_Back_Date_Time__c > :nowDt)';
        //q+=' or (Customer_Call_Back_Date_Time__c >= :nowMinus1hDt and Customer_Call_Back_Date_Time__c <= :nowPlus1hDt))';
        q+=' and Customer_Call_Back_Date_Time__c >= :nowMinus1hDt and Customer_Call_Back_Date_Time__c <= :nowPlus1hDt';
        System.debug(LoggingLevel.ERROR,'q:'+q);

        return Database.getQueryLocator(q);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope){        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
        
        if (messageRecipientIds==null) messageRecipientIds = new Set<Id>();
        
        Datetime callbackDt, calcDt, calcToleranceDt;
        List<Messaging.SingleEmailMessage> messagesToSend = new List<Messaging.SingleEmailMessage>();       
        Set<String> userIds;
        
        List<Lead> leadsToRoute = new List<Lead>();
        
        try {
        
            for (Lead l : scope){
                
                callbackDt = l.Customer_Call_Back_Date_Time__c;
                System.debug(LoggingLevel.ERROR,'callbackDt: '+callbackDt);
                System.debug(LoggingLevel.ERROR,'nowPlus20mDt: '+nowPlus20mDt);
                System.debug(LoggingLevel.ERROR,'nowDt: '+nowDt);
                    
                //Owner is the Callback queue
                //Customer_Call_Back_Date_Time__c < :nowPlus20mDt
                //1.5 Customer_Call_Back_Date_Time__c > :nowMinus5mDt (allows leads with a CBT of 9am to be released by the 9am cycle). 
                if (l.OwnerId==callBackQueueId &&
                    callbackDt < nowPlus20mDt 
                    && callbackDt > nowMinus5mDt 
                    ) {
    
                    // release the lead via SAA.
                    System.debug(LoggingLevel.ERROR,'released lead: '+l);
                    
                    leadsToRoute.add(l);
                }
            }       
            
            if (!leadsToRoute.isEmpty()){
                System.debug(LoggingLevel.ERROR,'leadsToRoute: '+leadsToRoute);      
                
                List<Lead> leadsToUpdate = new List<Lead>();
                 
                leadsToRoute = AP27_LeadAssignmentUtility.leadRouter(leadsToRoute, true, false);
                System.debug(LoggingLevel.ERROR,'leadsToRoute: '+leadsToRoute);
                
                for (Lead l : leadsToRoute){ if (l.OwnerId!=callBackQueueId) leadsToUpdate.add(l); }
                
                if (!leadsToUpdate.isEmpty()){
                    Database.SaveResult[] saveResults = Database.update(leadsToUpdate, false);
                    //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
                    logs.addAll(ApplicationConstant.getSaveResultLog(saveResults, 'execute', CLASS_NAME, 'Lead', 'Update'));
                    /*
                    for ( Integer i=0; i<saveResults.size(); i++ ){
                        if (!saveResults[i].isSuccess()){
                            log = ApplicationConstant.getDMLLog(saveResults[i], 'execute', CLASS_NAME, 'Lead', 'Update');
                            log.trace__c += ' \n Record Name: ' + leadsToUpdate[i].Name;
                            logs.add(log);
                        }       
                    }
                    */
                }
            }
            
            // process callback notifications.
            if (CustomerCallbackNotificationListSetting__c.getAll().size()==0) return;
            
            // requery leads to establish current owner.
            Set<Id> ownerIds = new Set<Id>();
            Map<Id,Lead> idToLead = new Map<Id,Lead>( [select Id, Name, OwnerId from Lead where Id in:scope] );

            for (Lead l : idToLead.values()){ ownerIds.add(l.OwnerId); }
            
            Map<Id,Id> ownerIdToManagerId = new Map<Id,Id>();
            for (User u : [select Id, ManagerId from User where Id in:ownerIds and ManagerId!=null]){ ownerIdToManagerId.put(u.Id,u.ManagerId); }   
            
            Id ownerId;
            Id ownerManagerId;
            String linkUrl;
            
            for (Lead l : scope){
                
                ownerId = idToLead.get(l.Id).OwnerId; // current owner id (lead may have been released this cycle.)
                ownerManagerId = ownerIdToManagerId.containsKey(ownerId) ? ownerIdToManagerId.get(ownerId) : null;   
                
                //https://golfbreaks--sit.cs81.my.salesforce.com/console#00Q26000003IXMK
                //linkUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/ui/support/servicedesk/ServiceDeskPage#'+l.Id;                                
                linkUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/console#%2F'+l.Id+'%3FsrPos%3D0%26srKp%3D00Q';                
                
                callbackDt = l.Customer_Call_Back_Date_Time__c; //09:00
                    
                for (CustomerCallbackNotificationListSetting__c ns : CustomerCallbackNotificationListSetting__c.getAll().values()){
                    System.debug(LoggingLevel.ERROR,'ns: '+ns);
                    
                    userIds = new Set<String>(); //reset userIds.
                                                                            
                    calcDt = callbackDt.addMinutes(Integer.valueOf(ns.Elapsed_Minutes__c)); //09:15
                    System.debug(LoggingLevel.ERROR,'calcDt: '+calcDt);
                    
                    calcToleranceDt = calcDt.addMinutes(1);  //09:16
                    System.debug(LoggingLevel.ERROR,'calcToleranceDt: '+calcToleranceDt);
                    
                    //& calcToleranceDt adds 1 minute tolerance to the job start time. 
                    if ( (nowDt.date()==calcDt.date() &&
                        nowDt.hour()==calcDt.hour() &&
                        nowDt.minute()==calcDt.minute()) ||                 
                        (nowDt.date()==calcToleranceDt.date() &&
                        nowDt.hour()==calcToleranceDt.hour() &&
                        nowDt.minute()==calcToleranceDt.minute())                   
                         ){
                            
                        if (!String.isBlank(ns.Notification_User_Ids__c)){                      
                            userIds = new Set<String>( ns.Notification_User_Ids__c.split('\\|') );
                        }
                        if (ns.Notify_Owner__c && 
                            !String.valueOf(ownerId).left(3).equals('00G')){
                        
                            if (userIds==null) userIds = new Set<String>();
                            userIds.add( ownerId );
                        }
                        if (ns.Notify_Owner_Manager__c && 
                            !String.valueOf(ownerId).left(3).equals('00G') &&
                            !String.isBlank(ownerManagerId)){
                                                    
                            if (userIds==null) userIds = new Set<String>();
                            userIds.add( ownerManagerId );                          
                        }
                        
                        System.debug(LoggingLevel.ERROR,'userIds: '+userIds);                       
                        if (userIds==null || userIds.isEmpty()) continue; // skip the notification if no notification users identified.
                                                            
                        if (ns.Check_Is_Queue_Assigned__c){
    
                            // Check if ownership is a Queue *any queue.
                            System.debug(LoggingLevel.ERROR,'ownerId: '+ownerId);                       
                            if (String.valueOf(ownerId).left(3).equals('00G')){ messagesToSend.addAll(buildSingleEmailMessages(userIds, ns.Notification_Subject__c+' - '+l.Name, ns.Notification_Body__c+' - '+linkUrl)); }                                                    

                        } else {
                            
                            // check whether field Agent_Call_Back_Date_Time__c is populated.
                            if (l.Agent_Call_Back_Date_Time__c==null){ messagesToSend.addAll(buildSingleEmailMessages(userIds, ns.Notification_Subject__c+' - '+l.Name, ns.Notification_Body__c+' - '+linkUrl)); }
                        }
                        System.debug(LoggingLevel.ERROR,'messagesToSend: '+messagesToSend);
                    }
                }           
            }
            AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount = messagesToSend.size();
            System.debug(LoggingLevel.ERROR,'AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount: '+messagesToSendCount);      
            if (!messagesToSend.isEmpty()) Messaging.sendEmail(messagesToSend); // todo error handling.   
        
        } catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'execute', CLASS_NAME, null));
            
        } finally {
            if(!logs.isEmpty()){ Database.insert(logs, false); }            
        }
    }
    
    private List<Messaging.SingleEmailMessage> buildSingleEmailMessages(Set<String> userIds, String subject, String body){
        //Get the OrgWideEmailAddress to set on the SingleEmailMessage
        List<OrgWideEmailAddress> orgWideEmails = ApplicationConstant.getOrgWideEmailAddressByName('Salesforce Support');
        Id orgWideEmailId = (!orgWideEmails.isEmpty() ? orgWideEmails[0].Id : null);
        
        Messaging.SingleEmailMessage m;
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();     
        
        System.debug(LoggingLevel.ERROR,'userIds: '+userIds);
        System.debug(LoggingLevel.ERROR,'subject+body: '+subject+' '+body);
        System.debug(LoggingLevel.ERROR, 'orgWideEmail: ' + orgWideEmailId);
        
        for (Id userId : userIds){
            m = new Messaging.SingleEmailMessage();
            
            m.setTargetObjectId( userId ); //avoid email limit consumption     
            m.saveAsActivity = false; //must be false if sending to internal user
            m.setSubject(subject);
            m.setBccSender(false);
            m.setUseSignature(false);
            m.setPlainTextBody(body);
            if (null != orgWideEmailId) {
                m.setOrgWideEmailAddressId(orgWideEmailId);
            }else {
                m.setSenderDisplayName( UserInfo.getOrganizationName()+' Admin' ); // approach taken from EmailHelper.cls
            }
            
            messages.add(m);
            messageRecipientIds.add(userId);
        }
        return messages;
    }
        
    global void finish(Database.BatchableContext BC){ }
    
    // End Batchable implementation.
}