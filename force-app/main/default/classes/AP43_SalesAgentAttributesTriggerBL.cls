public with sharing class AP43_SalesAgentAttributesTriggerBL {

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP43_SalesAgentAttributesTriggerBL';
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-04-21
    Version -      1.0 
    Function -     handles after insert process
    #############Change Log#############
    Modified by     Version     Change Date 
    Nicole DG       2.0         2016-04-23
    ****************************************************************************************/
    public static void updateQueueOnAfterInsert(Map<Id, Sales_Agent_Attributes__c> newSalesAgentAttributesMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
            //retrieve saa with sales agent and team populated to update queue
            Set<Id> saaIds = new Set<Id>();
            for(Sales_Agent_Attributes__c saa: newSalesAgentAttributesMap.values()){
                if(saa.Sales_Rep__c != null && saa.Team__c != null){
                    saaIds.add(saa.Id);
                }
            }
            if(!saaIds.isEmpty()){
                updateQueue(saaIds);
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateQueueOnAfterInsert', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }

    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-04-21
    Version -      1.0 
    Function -     handles after update process
    #############Change Log#############
    Modified by     Version     Change Date 
    Nicole DG       2.0         2016-04-23
    ****************************************************************************************/
    public static void updateQueueOnAfterUpdate(Map<Id, Sales_Agent_Attributes__c> newSalesAgentAttributesMap, Map<Id, Sales_Agent_Attributes__c> oldSalesAgentAttributesMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
            //retrieve saa if sales agent and team has been updated to update queue
            Set<Id> saaIds = new Set<Id>();
            for(Sales_Agent_Attributes__c saa: newSalesAgentAttributesMap.values()){
                Sales_Agent_Attributes__c oldSAA = oldSalesAgentAttributesMap.get(saa.Id);
                if(saa.Sales_Rep__c != null && oldSAA.Team__c != saa.Team__c){
                    saaIds.add(saa.Id);
                }
            }
            if(!saaIds.isEmpty()){
                updateQueue(saaIds);
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateQueueOnAfterUpdate', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }


    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-04-21
    Version -      1.0 
    Function -     handles updating queue
    #############Change Log#############
    Modified by     Version     Change Date 
    Nicole DG       2.0         2016-04-23
    ****************************************************************************************/
    @future
    static void updateQueue(Set<Id> saaIds){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        List<GroupMember> groupMembersToInsert = new List<GroupMember>();
        Set<Id> salesRepIDs = new Set<Id>();
        Set<String> queueNames = new Set<String>();
        
        try{
            List<Sales_Agent_Attributes__c> salesAgentAttributes = [SELECT Sales_Rep__c, Team__c FROM Sales_Agent_Attributes__c WHERE Id IN: saaIds];
            for(Sales_Agent_Attributes__c saa: salesAgentAttributes){
                salesRepIDs.add(saa.Sales_Rep__c);
                
                if(saa.Team__c != NULL){
                    for(String queueName: saa.Team__c.split(';')){
                        queueNames.add(queueName);
                    }
                }
            }
            
            //deletes the existing membership of Sales Agents to the Queues
            delete [SELECT Id FROM GroupMember WHERE UserOrGroupId IN: salesRepIDs AND Group.Type = 'Queue'];
            
            Map<String,Group> queueMap = new Map<String,Group>();
            for(Group queue: [SELECT Id,Name FROM Group WHERE Name IN: queueNames AND Type = 'Queue']){
                queueMap.put(queue.Name,queue);
            }
            
            //adds Sales Agents to the Queues
            for(Sales_Agent_Attributes__c saa: salesAgentAttributes){
                if(saa.Team__c != NULL){
                    for(String queueName: saa.Team__c.split(';')){
                        if(queueMap.containsKey(queueName)){
                            GroupMember groupMember = new GroupMember();
                            groupMember.GroupId = queueMap.get(queueName).Id;
                            groupMember.UserOrGroupId = saa.Sales_Rep__c;
                            groupMembersToInsert.add(groupMember);
                        }
                    }
                }
            }
            insert groupMembersToInsert;
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateQueue', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
}