/**************************************************************
@author - James Radcliffe (Golfbreaks)
@date - 25/11/2016
@description - This Class retrieves, evaluates and sorts lists for the records passed in through the trigger. These lists are then passed to the CoopInvoiceDML Class for the more complex logic
***************************************************************/
public Class CoopInvoiceTriggerHandler{

    public void onBeforeInsert(List<Co_op_Invoice__c> newInvs){
        List<Co_op_Invoice__c> allInvsWithAmount = new List<Co_op_Invoice__c>();
        system.debug('invoice count: '+newInvs.size());
        for(Co_op_Invoice__c i : newInvs){
            if(i.Amount__c != null){
                allInvsWithAmount.add(i);
            }
        }
        CoopInvoiceDML.convertToGBP(allInvsWithAmount);
        
        
    }

    public void onBeforeUpdate(Map<Id,Co_op_Invoice__c> newMap, Map<Id,Co_op_Invoice__c> oldMap){
    	List<Co_op_Invoice__c> invsWithChangedAmount = new List<Co_op_Invoice__c>();
        for(Co_op_Invoice__c newI : newMap.values()){
            Co_op_Invoice__c oldI = oldMap.get(newI.Id);
            if(newI.Amount__c != oldI.Amount__c){
                invsWithChangedAmount.add(newI);
            }
        }
        CoopInvoiceDML.convertToGBP(invsWithChangedAmount);
    }
}