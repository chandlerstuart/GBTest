/*
Name:  ActionTypeRequestSchedulable.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Set<String> actionTypeIds = new Set<String>{ '','' };
System.schedule('Action Type Request Processing','0 0 * * * ?',new clearmdm.ActionTypeRequestSchedulable(actionTypeIds));

Schedulable processor class for the ActionTypeRequest__c object.

======================================================
======================================================
Permissions Model:
-----------------
Object Access: 
Read+Update access to ActionTypeRequest__c custom object (includes FLS).
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-11-22  Initial development.
*/
global with sharing class ActionTypeRequestSchedulable implements System.Schedulable {

    private Set<String> actionTypeNames;
    private Boolean isExclusiveMode=false;

    global ActionTypeRequestSchedulable() { }

    global ActionTypeRequestSchedulable(Set<String> actionTypeNames){ this.actionTypeNames = actionTypeNames; }

    global ActionTypeRequestSchedulable(Boolean isExclusiveMode){ this.isExclusiveMode = isExclusiveMode; }

    global ActionTypeRequestSchedulable(Set<String> actionTypeNames, Boolean isExclusiveMode){ 
        this.actionTypeNames = actionTypeNames;
        this.isExclusiveMode = isExclusiveMode;
    }

    global void execute(SchedulableContext context){
        try {
                                
            if (actionTypeNames==null || actionTypeNames.isEmpty()){

                for (ActionType__mdt at : [select Id,DeveloperName from ActionType__mdt]){

                    if((Test.isRunningTest() && (context==null || context.getTriggerId()==null)) ||
                        [select count() from ActionTypeRequest__c 
                                where ((IsBatch__c=true and Status__c='New' and ProcessorJobId__c=null)
                                        or (IsBatch__c=false and Status__c='Pending' and ProcessorJobId__c=:context.getTriggerId()))
                                    and ActionType__c=:at.DeveloperName limit 1]>0){
                        Database.executeBatch(new ActionTypeRequestProcessor( String.valueOf(at.DeveloperName),(isExclusiveMode?context?.getTriggerId():null) ),getBatchSize(at));
                    }
                }
            } else {

                for (ActionType__mdt at : [select Id, DeveloperName, MaxRequestsPerProcessor__c from ActionType__mdt where DeveloperName in:actionTypeNames]){

                    if((Test.isRunningTest() && (context==null || context.getTriggerId()==null)) ||
                        [select count() from ActionTypeRequest__c 
                                        where ((IsBatch__c=true and Status__c='New' and ProcessorJobId__c=null)
                                                or (IsBatch__c=false and Status__c='Pending' and ProcessorJobId__c=:context.getTriggerId()))                            
                                            and ActionType__c=:at.DeveloperName limit 1]>0){
                        Database.executeBatch(new ActionTypeRequestProcessor( at.DeveloperName,isExclusiveMode?context?.getTriggerId():null),getBatchSize(at));
                    }
                }
            }
        } catch(Exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestIProcessor', 'Schedulable.execute'); }
    }
    
    private Integer getBatchSize(ActionType__mdt at){
        if (at==null || at.MaxRequestsPerProcessor__c==null || at.MaxRequestsPerProcessor__c==0){
            return 10;//todo magic number
        } else return at.MaxRequestsPerProcessor__c.intValue();
    }
}