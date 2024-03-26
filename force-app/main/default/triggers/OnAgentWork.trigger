/*
Name:  OnAgentWork
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Centralised trigger for the Standard Omnichannel Object : AgentWork

This trigger is not packaged as Unit Test coverage can't be added and
all packaged triggers must have greater than 0% coverage.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2018-07-07  Initial development.
*/
trigger OnAgentWork on AgentWork (after insert, after update) {

    /* **/
    GBWire.AgentWorkTriggerHandler handler = new GBWire.AgentWorkTriggerHandler();

           
   /* if (Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }*/

    if (Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    /* */
}