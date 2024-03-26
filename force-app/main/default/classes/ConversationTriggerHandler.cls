/*
Name:  ConversationTriggerHandler.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Handler class for Conversation__c trigger activity
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-01  Initial development.
*/
public with sharing class ConversationTriggerHandler {

    public static final String conversationObjectType = 'Conversation__c';

    public void onAfterInsert(Map<Id, Conversation__c> newMap){

        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//Temporarily disable omni trigger activity (prevent recursion). Omni related trigger activity must be executed selectively. 

        //<--- Add all local trigger activity here

        WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//Enable/revert omni trigger activity to previous state.
        
        //Execute omni related trigger activity
        //e.g. detecting changes to the owners or status' of records that could require capacity recalculation (etc)
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){
            try{
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;
                Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                WIREMap = WorkItemWIREActionIdentifier.processWorkItems(null, newMap, conversationObjectType);//Detect changes relevant to omni. 
                if(WIREMap != null && WIREMap.keySet().size()>0){try{GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, conversationObjectType);}catch(exception e){PlatformLogManager.logExceptions(e, 'ConversationTriggerHandler', 'onAfterInsert');}}
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; 
            }catch(exception e){
                PlatformLogManager.logExceptions(e, 'ConversationTriggerHandler', 'onAfterInsert');
            }
        }  

        //Call the integration framework to determine if changes to the record require communicating to external applications.
        DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(conversationObjectType);
        dth.handleTriggerOperationType();//2.8+

        
    }

    public void onAfterUpdate(Map<Id,Conversation__c> oldMap, Map<Id,Conversation__c> newMap){   

        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//Temporarily disable omni trigger activity (prevent recursion). Omni related trigger activity must be executed selectively. 

        //<--- Add all local trigger activity here

        WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//Enable/revert omni trigger activity to previous state.
        
        //Execute omni related trigger activity
        //e.g. detecting changes to the owners or status' of records that could require capacity recalculation (etc)
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){
            try{
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;
                Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                WIREMap = WorkItemWIREActionIdentifier.processWorkItems(oldMap, newMap, conversationObjectType);//Detect changes relevant to omni.  
                //Execute Omni activity
                if(WIREMap != null && WIREMap.keySet().size()>0){ try{GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, conversationObjectType); }catch(exception e){PlatformLogManager.logExceptions(e, 'ConversationTriggerHandler', 'OnAfterUpdate');}}
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; 
            }catch(exception e){
                PlatformLogManager.logExceptions(e, 'ConversationTriggerHandler', 'onAfterUpdate');
            }
        }  

        //Call the integration framework to determine if changes to the record require communicating to external applications.
        DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(conversationObjectType);
        dth.handleTriggerOperationType();
    }


}