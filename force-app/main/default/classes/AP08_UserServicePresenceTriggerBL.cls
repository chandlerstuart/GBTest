/**
   @Author: Jerella Ledesma
   @name: AP08_UserServicePresenceTriggerBL
   @CreateDate: 04.03.2016
   @Description: Handler Class for UserServicePresence
   @Modification: 2017-03-10 : SM : Modified handler to filter on UserIDs as per SG-582
   @Version <1.0>
 */ 
public with sharing class AP08_UserServicePresenceTriggerBL implements TriggerHandlerInterface{

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP08_UserServicePresenceTriggerBL';

    //UserId Set property to filter SAA Records by
    public Set<Id> userIdSet {get; set;}
    
    //recursion flags
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeDeleteTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    /**
    *  @name: runBeforeInsertTrigger
    *  @description: These methods are used to set the values for the recursion boolean variables
    */
    public Boolean runBeforeInsertTrigger() {
        Boolean returnVar = !AP08_UserServicePresenceTriggerBL.isBeforeInsertTriggerCalled;
        AP08_UserServicePresenceTriggerBL.isBeforeInsertTriggerCalled = TRUE;
        return returnVar;
    }
    
    /**
    *  @name: runBeforeUpdateTrigger
    *  @description: These methods are used to set the values for the recursion boolean variables
    */
    public Boolean runBeforeUpdateTrigger() {
        Boolean returnVar = !AP08_UserServicePresenceTriggerBL.isBeforeUpdateTriggerCalled;
        AP08_UserServicePresenceTriggerBL.isBeforeUpdateTriggerCalled = TRUE;
        return returnVar;
    }
    
    /**
    *  @name: runBeforeDeleteTrigger
    *  @description: These methods are used to set the values for the recursion boolean variables
    */
    public Boolean runBeforeDeleteTrigger() {
        Boolean returnVar = !AP08_UserServicePresenceTriggerBL.isBeforeDeleteTriggerCalled;
        AP08_UserServicePresenceTriggerBL.isBeforeDeleteTriggerCalled = TRUE;
        return returnVar;
    }
    
    /**
    *  @name: runAfterInsertTrigger
    *  @description: These methods are used to set the values for the recursion boolean variables
    */
    public Boolean runAfterInsertTrigger() {
        Boolean returnVar = !AP08_UserServicePresenceTriggerBL.isAfterInsertTriggerCalled;
        AP08_UserServicePresenceTriggerBL.isAfterInsertTriggerCalled = TRUE;
        return returnVar;
    }
    
    /**
    *  @name: runAfterUpdateTrigger
    *  @description: These methods are used to set the values for the recursion boolean variables
    */
    public Boolean runAfterUpdateTrigger() {
        Boolean returnVar = !AP08_UserServicePresenceTriggerBL.isAfterUpdateTriggerCalled;
        AP08_UserServicePresenceTriggerBL.isAfterUpdateTriggerCalled = TRUE;
        return returnVar;
    }
    
    /**
    *  @name: runAfterDeleteTrigger
    *  @description: These methods are used to set the values for the recursion boolean variables
    */
    public Boolean runAfterDeleteTrigger() {
        Boolean returnVar = !AP08_UserServicePresenceTriggerBL.isAfterDeleteTriggerCalled;
        AP08_UserServicePresenceTriggerBL.isAfterDeleteTriggerCalled = TRUE;
        return returnVar;
    }
    //Instantiation of the list, maps, records to be used.
    Id queuePresenceRecordTypeId;
    Id salesAgentRecordTypeId;
    Id salesManagerRecordTypeId;
    List<Sales_Agent_Attributes__c> salesAgentAttributeList;
    Sales_Agent_Attributes__c salesAgentAttribute = new Sales_Agent_Attributes__c();
    Map<String, Sales_Agent_Attributes__c> queueNameToSalesAgent = new Map<String, Sales_Agent_Attributes__c>();
    List<GroupMember> groupMembers = new List<GroupMember>();
    @testvisible Map<Id, Set<Id>> queueToPublicGroup = new Map<Id, Set<Id>>();
    @testvisible Map<Id, Set<Id>> publicToUsers = new Map<Id, Set<Id>>();
    @testvisible Map<Id, Set<Id>> queueToUsers = new Map<Id, Set<Id>>();
    Map<Id, GroupMember> publicGroupIds = new Map<Id, GroupMember>();
    Map<Id, String> queueIdToQueueName = new Map<Id, String>();
    @testvisible Map<Id, Set<Id>> userIdToQueueIdsMap = new Map<Id, Set<Id>>();
    Map<Id, Sales_Agent_Attributes__c> updateSalesAgent = new Map<Id, Sales_Agent_Attributes__c>();
    Map<Id, Sales_Agent_Attributes__c> salesAgentToAvailabilityStatus = new Map<Id, Sales_Agent_Attributes__c>();
    
    
    /**
    *  @name: bulkBefore
    *  @description: Data are being collated for the processes of the beforeDelete, beforeInsert or beforeUpdate
    */
    public void bulkBefore() {
        
    }
    
    /**
    *  @name: bulkAfter
    *  @description: Data are being collated for the processes of the afterDelete, afterInsert or afterUpdate
    */
    public void bulkAfter() {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
            //query record type of the Sales Agent Attribute
            queuePresenceRecordTypeId = ApplicationConstant.getRecordTypeId(ApplicationConstant.USP_OBJECT, ApplicationConstant.USP_QUEUE_PRESENCE_DEVNAME);
            salesAgentRecordTypeId = ApplicationConstant.getRecordTypeId(ApplicationConstant.USP_OBJECT, ApplicationConstant.USP_SALES_AGENT_DEVNAME);
            salesManagerRecordTypeId = ApplicationConstant.getRecordTypeId(ApplicationConstant.USP_OBJECT, ApplicationConstant.USP_SALES_MANAGER_DEVNAME);
            //query all the group members of the Queues, Public Groups
            //2017-03-10 : SM : Now using a userIdSet to help filter these records, to stop record locking contention
            //groupMembers = [SELECT UserOrGroupId, Group.Id, Group.Type, Group.Name FROM GroupMember];
            Set<Id> groupIdSet = new Set<Id>();
            for (GroupMember gm : [select Id, Group.Id from GroupMember where UserOrGroupId in :userIdSet and Group.Type='Regular']){
            	groupIdSet.add(gm.Group.Id);
            }
            
            groupMembers = [select UserOrGroupId, Group.Id, Group.Type, Group.Name from GroupMember 
            					where (UserOrGroupId in :userIdSet or UserOrGroupId in :groupIdSet)]; //queue membership can be direct or indirect via group. No recursive lookup.
            
            System.debug(LoggingLevel.ERROR, 'groupMembers>'+groupMembers);
            
            for(GroupMember grpMember : groupMembers){
            	
            	System.debug(LoggingLevel.ERROR, 'grpMember.Type>'+grpMember.Group.Type);
            	System.debug(LoggingLevel.ERROR, 'grpMember.Name>'+grpMember.Group.Name);
            	
                if(grpMember.Group.Type == ApplicationConstant.USP_QUEUE){
                    publicGroupIds.put(grpMember.UserOrGroupId, grpMember);
                    queueIdToQueueName.put(grpMember.Group.Id, grpMember.Group.Name);
                    if(queueToPublicGroup.containsKey(grpMember.Group.Id)){
                        queueToPublicGroup.get(grpMember.Group.Id).add(grpMember.UserOrGroupId);
                    }
                    else{
                        queueToPublicGroup.put(grpMember.Group.Id, new Set<Id>());
                        queueToPublicGroup.get(grpMember.Group.Id).add(grpMember.UserOrGroupId); //&queue to member UserId or GroupId
                    }
                }
            }
            System.debug(LoggingLevel.ERROR, 'queueToPublicGroup>'+queueToPublicGroup); //& or Queue to User
            System.debug(LoggingLevel.ERROR, 'publicGroupIds>'+publicGroupIds); //&User to GroupMember
            
            for(GroupMember grpMember : groupMembers){
                if(publicGroupIds.containsKey(grpMember.Group.Id)){ //& where Queue membership is via Group - collate Group members=>publicTousers.
                    if(publicToUsers.containsKey(grpMember.Group.Id)){ publicToUsers.get(grpMember.Group.Id).add(grpMember.UserOrGroupId); }
                    else{
                        publicToUsers.put(grpMember.Group.Id, new Set<Id>());
                        publicToUsers.get(grpMember.Group.Id).add(grpMember.UserOrGroupId); //&public group to member UserId
                    }
                }
            }
            System.debug(LoggingLevel.ERROR, 'publicToUsers>'+publicToUsers); //public group to users - empty where direct queue member (not via public group)
            
            
            for(Id queueId : queueToPublicGroup.keySet()){ //for each Queue            	
            	queueToUsers.put(queueId, new Set<Id>());
            	
                for(Id pubId : queueToPublicGroup.get(queueId)){ // for each Group or User that is member

                    if(publicToUsers.containsKey(pubId)){ // if Group then relate group members to the Queue. 
                        for(Id userId : publicToUsers.get(pubId)){                                
                            queueToUsers.get(queueId).add(userId);
                        }
                    } else {
                    	queueToUsers.get(queueId).add(pubId);
                    }
                }
            }
            System.debug(LoggingLevel.ERROR, 'queueToUsers>'+queueToUsers);
            
            for(Id queueId :queueToUsers.keySet()) {
                if(queueToUsers.containsKey(queueId)){
                    for(Id userId :queueToUsers.get(queueId)) {                    	
                    	if (userIdToQueueIdsMap.containsKey(userId)) userIdToQueueIdsMap.get(userId).add(queueId);
                    	else userIdToQueueIdsMap.put(userId, new Set<Id> {queueId});                     	
                    }
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'userIdToQueueIdsMap>'+userIdToQueueIdsMap);
            
            //** HERE 
            //query all the Sales Agent Attributes where the Online Users are to be updated based on the status of the User Agent
            //2017-03-10 : SM : Now using a userIdSet to help filter these records, to stop record locking contention
            salesAgentAttributeList = [SELECT Sales_Rep__c, Online__c, RecordTypeId, Queue__c, NumberOfOnlineUser__c, Name FROM Sales_Agent_Attributes__c WHERE Sales_Rep__c in :userIdSet AND (RecordTypeId = :queuePresenceRecordTypeId OR RecordTypeId = :salesAgentRecordTypeId OR RecordTypeId = :salesManagerRecordTypeId) FOR UPDATE];
            System.debug(LoggingLevel.ERROR, 'salesAgentAttributeList>'+salesAgentAttributeList);
            
            //Data preparation - assignment of maps to obtain the map of User to Queue is done here
            for(Sales_Agent_Attributes__c salesAgent: salesAgentAttributeList){
                if(salesAgent.RecordTypeId == queuePresenceRecordTypeId){
                    queueNameToSalesAgent.put(salesAgent.Queue__c, salesAgent);
                }
                if((salesAgent.RecordTypeId == salesAgentRecordTypeId) || (salesAgent.RecordTypeId == salesManagerRecordTypeId)){
                    salesAgentToAvailabilityStatus.put(salesAgent.Sales_Rep__c, salesAgent);
                }
            }
            System.debug(LoggingLevel.ERROR, 'queueNameToSalesAgent>'+queueNameToSalesAgent);
            System.debug(LoggingLevel.ERROR, 'salesAgentToAvailabilityStatus>'+salesAgentToAvailabilityStatus);
            
        }catch(Exception e){ logs.add(ApplicationConstant.getExceptionLog(e, 'bulkAfter()', CLASS_NAME, null));
        }finally{ if(!logs.isEmpty()){ Database.insert(logs, false); } }
    }
    
    /**
    *  @name: beforeInsert
    *  @description: Processes all transaction needed for the beforeInsert
    */
    public void beforeInsert(SObject so) {
    }
    /**
    *  @name: beforeUpdate
    *  @description: Processes all transaction needed for the beforeUpdate
    */
    public void beforeUpdate(SObject oldSo, SObject so) {
    }
    
    /**
    *  @name: beforeDelete
    *  @description: Processes all transaction needed for the beforeDelete
    */
    public void beforeDelete(SObject so) {
    }
    
    /**
    *  @name: afterInsert
    *  @description: Processes all transaction needed for the afterInsert
    */
    public void afterInsert(SObject so) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
            //gets the Queue for the Sales Attribute Agent object and update the Number of Online Users based on the change of status of the agent
            Set<Id> queueIdFromUserMap;
            UserServicePresence userp = (UserServicePresence)so;
            queueIdFromUserMap = new Set<Id>();
            if(userIdToQueueIdsMap.containsKey(userp.UserId)){
                queueIdFromUserMap = userIdToQueueIdsMap.get(userp.UserId);
                for(Id queueId : queueIdFromUserMap){
                    if(queueNameToSalesAgent.containsKey(queueIdToQueueName.get(queueId))){
                        salesAgentAttribute = queueNameToSalesAgent.get(queueIdToQueueName.get(queueId));
                        if(userp.IsCurrentState){
                            salesAgentAttribute.NumberOfOnlineUser__c++;
                            //collects the Sales Agent Attribute record to be updated if there are changes
                            updateSalesAgent.put(salesAgentAttribute.Id, salesAgentAttribute);
                        }
                    }
                }
            }

            if(salesAgentToAvailabilityStatus.containsKey(userp.UserId)){
                salesAgentAttribute = salesAgentToAvailabilityStatus.get(userp.UserId);

                if(userp.IsCurrentState){
                    salesAgentAttribute.Online__c = TRUE;
                    //collects the Sales Agent Attribute record to be updated if there are changes
                    updateSalesAgent.put(salesAgentAttribute.Id, salesAgentAttribute);
                }
                else{
                    salesAgentAttribute.Online__c = FALSE;
                    //collects the Sales Agent Attribute record to be updated if there are changes
                    updateSalesAgent.put(salesAgentAttribute.Id, salesAgentAttribute);
                }
            }
        }catch(Exception e){ logs.add(ApplicationConstant.getExceptionLog(e, 'afterInsert()', CLASS_NAME, null));
        }finally{ if(!logs.isEmpty()){ Database.insert(logs, false); } }
    }
    
    /**
    *  @name: afterUpdate
    *  @description: Processes all transaction needed for the afterUpdate
    */
    public void afterUpdate(SObject oldSo, SObject so) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
    
        try{
            //gets the Queue for the Sales Attribute Agent object and update the Number of Online Users based on the change of status of the agent
            Set<Id> queueIdFromUserMap;
            UserServicePresence userp = (UserServicePresence)so;
            UserServicePresence oldUserp = (UserServicePresence)oldSo;
            queueIdFromUserMap = new Set<Id>();
            if(userIdToQueueIdsMap.containsKey(userp.UserId)){
                queueIdFromUserMap = userIdToQueueIdsMap.get(userp.UserId);
                for(Id queueId : queueIdFromUserMap){
                    if(queueNameToSalesAgent.containsKey(queueIdToQueueName.get(queueId))){
                        salesAgentAttribute = queueNameToSalesAgent.get(queueIdToQueueName.get(queueId));
                        if(!userp.IsCurrentState){
                            salesAgentAttribute.NumberOfOnlineUser__c--;
                            if(salesAgentAttribute.NumberOfOnlineUser__c < 0){
                                salesAgentAttribute.NumberOfOnlineUser__c = 0;  
                            }
                            //collects the Sales Agent Attribute record to be updated if there are changes
                            updateSalesAgent.put(salesAgentAttribute.Id, salesAgentAttribute);
                        }
                    }
                }
            }

            if(salesAgentToAvailabilityStatus.containsKey(userp.UserId)){
                salesAgentAttribute = salesAgentToAvailabilityStatus.get(userp.UserId);

                if(userp.IsCurrentState){
                    salesAgentAttribute.Online__c = TRUE;
                    //collects the Sales Agent Attribute record to be updated if there are changes
                    updateSalesAgent.put(salesAgentAttribute.Id, salesAgentAttribute);
                }
                else{
                    salesAgentAttribute.Online__c = FALSE;
                    //collects the Sales Agent Attribute record to be updated if there are changes
                    updateSalesAgent.put(salesAgentAttribute.Id, salesAgentAttribute);
                }
            }

            /*

            //2017-02-24 : SM : New code to send email notification if a user goes offline unexpectedly
            //First check if the Custom Setting says the code is enabled
            Set<Id> offlineUsers = new Set<Id>();
            Set<Id> emailIds = new Set<Id>();
            UserPresenceEmails__c upe = UserPresenceEmails__c.getInstance('Default');
            if (upe.Enabled__c) {
                if (!userp.IsCurrentState && oldUserp.IsCurrentState){
                    //Someone has gone offline
                    offlineUsers.add(userp.UserId);
                }   

                Map<Id, UserServicePresence> currentUSPMap = new Map<Id, UserServicePresence>();
                for (UserServicePresence usp : [select Id, UserId from UserServicePresence where IsCurrentState = TRUE AND UserId in :offlineUsers]){
                    currentUSPMap.put(usp.UserId, usp);
                }

                for (Id i : offlineUsers){
                    if (currentUSPMap.get(i) == null){
                        //The user has no current active UserServicePresence
                        emailIds.add(i);
                    }
                }

                if (!emailIds.isEmpty()){
                    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

                    for(Id i : emailIds){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> toAddresses = new List<String>();
                        String emailBody = 'The following user has gone offline unexpectedly: ' + userp.User.Name;
                        mail.setPlainTextBody(emailBody);
                        mail.setSubject('Sales Agent Offline - ' + userp.User.Name);
                        mail.setSenderDisplayName('Salesforce Offline Monitor');
                        if (upe.Send_to_Owner__c) toAddresses.add(userp.User.Email);
                        if (null != upe.Email_Addresses__c){
                            String[] emailAddresses = upe.Email_Addresses__c.split(',');
                            toAddresses.addAll(emailAddresses);
                        }
                        if (upe.Send_to_IT__c){
                            if (null != upe.IT_Email_Addresses__c){
                                String[] itEmailAddresses = upe.IT_Email_Addresses__c.split(',');
                                toAddresses.addAll(itEmailAddresses);
                            }
                        }
                        if (toAddresses.isEmpty()){
                            //We must have at least one Email Address but hopefully this will never be called
                            toAddresses.add(userp.User.Email);
                        }
                        mail.setSaveAsActivity(false);
               
                        mails.add(mail);
                    }

                    if (!mails.isEmpty()){
                        //Set the allOrNothing parameter to be FALSE so it still sends emails on failures
                        Messaging.sendEmail(mails, false);
                    }
                }

            }

        */

        }catch(Exception e){ logs.add(ApplicationConstant.getExceptionLog(e, 'afterUpdate()', CLASS_NAME, null));
        }finally{ if(!logs.isEmpty()){ Database.insert(logs, false);} }            
    }
    
    /**
    * @name: sendNotificationEmails
    * @description: Sends emails to the Owner and / or email addreses stored in the custom setting UserPresenceEmails__c
    */
    /*
    public static void sendNotificationEmails(List<UserServicePresence> newRecords, Map<Id, UserServicePresence> oldRecords){
        List<Error_Log__c> logs = new List<Error_Log__c>();

        try {
            //First check if the Custom Setting says the code is enabled
            UserPresenceEmails__c upe = UserPresenceEmails__c.getInstance('Default');
            if (!upe.Enabled__c) return;

            Set<Id> offlineUsers = new Set<Id>();
            Set<Id> emailIds = new Set<Id>();

            for (UserServicePresence usp : newRecords){
                UserServicePresence oldUSP = oldRecords.get(usp.Id);
                if (!usp.IsCurrentState && oldUSP.IsCurrentState){
                    //Someone has gone offline
                    offlineUsers.add(usp.UserId);
                }
            }

            Map<Id, UserServicePresence> currentUSPMap = new Map<Id, UserServicePresence>();
            for (UserServicePresence usp : [select Id, UserId from UserServicePresence where IsCurrentState = TRUE AND UserId in :offlineUsers]){
                currentUSPMap.put(usp.UserId, usp);
            }

            Map<Id, User> userMap = new Map<Id, User>([select Id, Name, Email from User where Id in :offlineUsers]);

            for (Id i : offlineUsers){
                if (currentUSPMap.get(i) == null){
                    //The user has no current active UserServicePresence
                    emailIds.add(i);
                }
            }

            if (!emailIds.isEmpty()){
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

                for(Id i : emailIds){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> toAddresses = new List<String>();
                    String emailBody = 'The following user has gone offline unexpectedly: ' + userMap.get(i).Name;
                    mail.setPlainTextBody(emailBody);
                    mail.setSubject('Sales Agent Offline - ' + userMap.get(i).Name);
                    mail.setSenderDisplayName('Salesforce Offline Monitor');
                    if (upe.Send_to_Owner__c) toAddresses.add(userMap.get(i).Email);
                    if (null != upe.Email_Addresses__c){
                        String[] emailAddresses = upe.Email_Addresses__c.split(',');
                        toAddresses.addAll(emailAddresses);
                    }
                    if (upe.Send_to_IT__c){
                        if (null != upe.IT_Email_Addresses__c){
                            String[] itEmailAddresses = upe.IT_Email_Addresses__c.split(',');
                            toAddresses.addAll(itEmailAddresses);
                        }
                    }
                    if (toAddresses.isEmpty()){
                        //We must have at least one Email Address but hopefully this will never be called
                        toAddresses.add(userMap.get(i).Email);
                    }
                    mail.setSaveAsActivity(false);
           
                    mails.add(mail);
                }

                if (!mails.isEmpty()){
                    //Set the allOrNothing parameter to be FALSE so it still sends emails on failures
                    Messaging.sendEmail(mails, false);
                }
            }
        }catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'sendNotificationEmails()', CLASS_NAME, 'UserServicePresence'));    
        }finally {
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }   
        }

    }
    */
    /**
    *  @name: afterDelete
    *  @description: Processes all transaction needed for the afterDelete
    */
    public void afterDelete(SObject so) {
    }
    
    /**
    *  @name: andFinally
    *  @description: All final actions are included here. Usually DML statements are contained in this method
    */
    public void andFinally() {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
            //updates the list if there are records to be updated.
            String errorLogDescription = '';
            Map<Id, Sales_Agent_Attributes__c> salesAgentMap = new Map<Id, Sales_Agent_Attributes__c>();
            Map<String, String> salesAgentErrorMap = new Map<String, String>();
            
            for(Sales_Agent_Attributes__c SAA: updateSalesAgent.values()){
                salesAgentMap.put(SAA.Id, SAA);
            }
        }catch(Exception e){ logs.add(ApplicationConstant.getExceptionLog(e, 'andFinally', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && updateSalesAgent.size() > 0){
                Database.SaveResult[] updateLeadList = Database.update(updateSalesAgent.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'andFinally', CLASS_NAME, 'Sales Agent Attribute', 'Update'));
            }        
            if(!logs.isEmpty()){ Database.insert(logs, false); }
        }
    }
}