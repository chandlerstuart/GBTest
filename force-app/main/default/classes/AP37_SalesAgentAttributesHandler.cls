/**
Name:  AP37_SalesAgentAttributesHandler.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the Sales Agent Attributes custom object.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-04-21  Initial development.
2.0  Nicole DG  2016-04-23  Implemented the logic to add or remove the Sales Agent/User to the Queues based on selected values on the Sales_Agent_Attributes__c.Team__c field.
**/
public class AP37_SalesAgentAttributesHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-04-21
    Version -      1.0 
    Function -     handles after insert process
    #############Change Log#############
    Modified by     Version     Change Date 
    Nicole DG       2.0         2016-04-23
    ****************************************************************************************/
    public void onAfterInsert(Map<Id, Sales_Agent_Attributes__c> newSalesAgentAttributesMap){
        if(!isAfterInsertTriggerCalled){
            AP43_SalesAgentAttributesTriggerBL.updateQueueOnAfterInsert(newSalesAgentAttributesMap);
            
            isAfterInsertTriggerCalled = TRUE;
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
    public void onAfterUpdate(Map<Id, Sales_Agent_Attributes__c> newSalesAgentAttributesMap, Map<Id, Sales_Agent_Attributes__c> oldSalesAgentAttributesMap){
        if(!isAfterUpdateTriggerCalled){
            AP43_SalesAgentAttributesTriggerBL.updateQueueOnAfterUpdate(newSalesAgentAttributesMap, oldSalesAgentAttributesMap); 
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
}