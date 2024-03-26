trigger RequestQueueTrigger on Request_Queue__c (after insert) {
    // Org Wide Settings to check whether this Apex trigger should run or not?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ){
        return;
    }
    
    if( Trigger.isAfter ){
        AP01_RequestQueueTriggerHandler requestQueueHandler = new AP01_RequestQueueTriggerHandler();
        if( Trigger.isInsert ){
            requestQueueHandler.OnAfterInsert(Trigger.new);        
        }
    }
}