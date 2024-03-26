/*
Name:  AP66_ProductServiceTriggerHandler.cls
======================================================
======================================================
Purpose:
-------
Business Logic Class for ProductServiceTrigger
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-11-03   Initial development
*/
public with sharing class AP66_ProductServiceTriggerHandler
{   
    // Used for logging
    public static final String CLASS_NAME = 'AP66_ProductServiceTriggerHandler';
    
    //recursion flags
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    public static Boolean isBeforeDeleteTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isOnUndeleteTriggerCalled = FALSE;

    
    //******  EVENT METHODS ***** //

    public void OnBeforeInsert(List<Product_Service__c> newPSList){
        system.debug('*** -- ' + CLASS_NAME + '.OnBeforeInsert called -- ***');
        if(!isBeforeInsertTriggerCalled){

            updateAnnualAndMonthlyCosts(newPSList, null);

            isBeforeInsertTriggerCalled = TRUE;
        }
        
    }

    public void OnBeforeUpdate(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> newPSMap, List<Product_Service__c> oldPSList, Map<Id,Product_Service__c> oldPSMap){
        
        if(!isBeforeUpdateTriggerCalled){
                
            updateAnnualAndMonthlyCosts(newPSList, oldPSMap);

            isBeforeUpdateTriggerCalled = TRUE;
        }

    }

    /** Commenting out uncalled methods **/
    /*
    public void OnBeforeDelete(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> newPSMap, List<Product_Service__c> oldPSList, Map<Id,Product_Service__c> oldPSMap){
        
        if(!isBeforeDeleteTriggerCalled){
                
            isBeforeDeleteTriggerCalled = TRUE;
        }

    }

    public void OnAfterInsert(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> newPSMap, List<Product_Service__c> oldPSList, Map<Id,Product_Service__c> oldPSMap){
        
        if(!isAfterInsertTriggerCalled){

            isAfterInsertTriggerCalled = TRUE;
        }
    }

    public void OnAfterUpdate(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> newPSMap, List<Product_Service__c> oldPSList, Map<Id,Product_Service__c> oldPSMap){
      
        if(!isAfterUpdateTriggerCalled){
          
            isAfterUpdateTriggerCalled = TRUE;
        }
    }

    public void OnAfterDelete(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> newPSMap, List<Product_Service__c> oldPSList, Map<Id,Product_Service__c> oldPSMap){
      
        if(!isAfterDeleteTriggerCalled){
          
            isAfterDeleteTriggerCalled = TRUE;
        }
    }

    public void OnUndelete(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> newPSMap, List<Product_Service__c> oldPSList, Map<Id,Product_Service__c> oldPSMap){
      
        if(!isOnUndeleteTriggerCalled){
          
            isOnUndeleteTriggerCalled = TRUE;
        }
    }   
    */

    //***** PROCESSING METHODS ***** //

    //2017-10-30 : SM : Method to calculate Annual Costs if Monthly entered, and vice versa
    public void updateAnnualAndMonthlyCosts(List<Product_Service__c> newPSList, Map<Id, Product_Service__c> oldPSMap){
        if (null == oldPSMap){
            //INSERT EVENT
            for (Product_Service__c ps : newPSList){
                if (null != ps.Annual_Cost__c && null == ps.Monthly_Cost__c){
                    ps.Monthly_Cost__c = ps.Annual_Cost__c / 12;
                }else if (null != ps.Monthly_Cost__c && null == ps.Annual_Cost__c){
                    ps.Annual_Cost__c = ps.Monthly_Cost__c * 12;
                }

            }
        }else {
            //UPDATE EVENT
            for (Product_Service__c ps : newPSList){
                Product_Service__c oldPS = oldPSMap.get(ps.Id);
                if (ps.Annual_Cost__c != oldPS.Annual_Cost__c && null != ps.Annual_Cost__c){
                    ps.Monthly_Cost__c = ps.Annual_Cost__c / 12;
                }else if (ps.Monthly_Cost__c != oldPS.Monthly_Cost__c && null != ps.Monthly_Cost__c){
                    ps.Annual_Cost__c = ps.Monthly_Cost__c * 12;
                }   
            }
        }
    } 
}