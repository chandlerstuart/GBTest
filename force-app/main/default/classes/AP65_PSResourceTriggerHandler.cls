/*
Name:  AP65_PSResourceTriggerHandler.cls
======================================================
======================================================
Purpose:
-------
Business Logic Class for PSResourceTrigger
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-10-30   Initial development (Methods not needed are commented out)
*/
public with sharing class AP65_PSResourceTriggerHandler
{   
    // Used for logging
    public static final String CLASS_NAME = 'AP65_PSResourceTriggerHandler';
    public static final String DUPLICATE_PSR_ERROR = 'A Product / Service Record already exists for this User & Product/Service combination';
    
    //recursion flags
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    public static Boolean isBeforeDeleteTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isOnUndeleteTriggerCalled = FALSE;

    
    //******  EVENT METHODS ***** //

    public void OnBeforeInsert(List<Product_Service_Resource__c> newPSRList){
        system.debug('*** -- ' + CLASS_NAME + '.OnBeforeInsert called -- ***');
        if(!isBeforeInsertTriggerCalled){

            checkForDuplicate(newPSRList,null);

            updateTypeAndCostings(newPSRList);

            isBeforeInsertTriggerCalled = TRUE;
        }
        
    }

    public void OnBeforeUpdate(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> newPSRMap, List<Product_Service_Resource__c> oldPSRList, Map<Id,Product_Service_Resource__c> oldPSRMap){
        
        if(!isBeforeUpdateTriggerCalled){
                
            checkForDuplicate(newPSRList,oldPSRMap);

            isBeforeUpdateTriggerCalled = TRUE;
        }

    }

    /*
    public void OnBeforeDelete(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> newPSRMap, List<Product_Service_Resource__c> oldPSRList, Map<Id,Product_Service_Resource__c> oldPSRMap){
        
        if(!isBeforeDeleteTriggerCalled){
                
            isBeforeDeleteTriggerCalled = TRUE;
        }

    }
    */
    /*
    public void OnAfterInsert(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> newPSRMap, List<Product_Service_Resource__c> oldPSRList, Map<Id,Product_Service_Resource__c> oldPSRMap){
        
        if(!isAfterInsertTriggerCalled){

            isAfterInsertTriggerCalled = TRUE;
        }
    }
    */
    /*
    public void OnAfterUpdate(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> newPSRMap, List<Product_Service_Resource__c> oldPSRList, Map<Id,Product_Service_Resource__c> oldPSRMap){
      
        if(!isAfterUpdateTriggerCalled){
          
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
    */
    /*
    public void OnAfterDelete(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> newPSRMap, List<Product_Service_Resource__c> oldPSRList, Map<Id,Product_Service_Resource__c> oldPSRMap){
      
        if(!isAfterDeleteTriggerCalled){
          
            isAfterDeleteTriggerCalled = TRUE;
        }
    }
    */
    /*
    public void OnUndelete(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> newPSRMap, List<Product_Service_Resource__c> oldPSRList, Map<Id,Product_Service_Resource__c> oldPSRMap){
      
        if(!isOnUndeleteTriggerCalled){
          
            isOnUndeleteTriggerCalled = TRUE;
        }
    }   
    */
    //***** PROCESSING METHODS ***** //

    //2017-11-03 : SM : Method to stop duplicate Product / Service Resource records being added for an Employee
    public void checkForDuplicate(List<Product_Service_Resource__c> newPSRList, Map<Id, Product_Service_Resource__c> oldPSRMap){
        Set<Id> empIdSet = new Set<Id>();
        if (null == oldPSRMap){
            //INSERT EVENT
            for (Product_Service_Resource__c psr : newPSRList){
                empIdSet.add(psr.Employment__c);
            }            
        }else {
            //UPDATE EVENT
            for (Product_Service_Resource__c psr : newPSRList){
                Product_Service_Resource__c oldPSR = oldPSRMap.get(psr.Id);
                if (psr.Employment__c != oldPSR.Employment__c || psr.Product_Service__c != oldPSR.Product_Service__c){
                    empIdSet.add(psr.Employment__c);
                }
            }    
        }

        Map<Id, List<Product_Service_Resource__c>> empPSRMap = new Map<Id, List<Product_Service_Resource__c>>();

        for (Product_Service_Resource__c psr : [select Id, Employment__c, Product_Service__c from Product_Service_Resource__c
                                                where Employment__c in :empIdSet]){
            if(empPSRMap.containsKey(psr.Employment__c)) {
                empPSRMap.get(psr.Employment__c).add(psr);
            }
            else {
                empPSRMap.put(psr.Employment__c, new List<Product_Service_Resource__c>{psr});
            }
        }

        for (Product_Service_Resource__c psr : newPSRList){
            if (null != empPSRMap.get(psr.Employment__c) && !empPSRMap.get(psr.Employment__c).isEmpty()){
                for (Product_Service_Resource__c currentPSR : empPSRMap.get(psr.Employment__c)){
                    if (currentPSR.Product_Service__c == psr.Product_Service__c){
                        //WE HAVE FOUND AN EXISING RESOURCE RECORD FOR THIS EMPLOYMENT / PRODUCT/SERVICE COMBINATION
                        psr.addError(DUPLICATE_PSR_ERROR,false);
                        continue;
                    }
                }
            }
        }
    }

    //2017-10-30 : SM : Method to update Product Service Resource Costs (Annual & Monthly) from linked Product Service record
    public void updateTypeAndCostings(List<Product_Service_Resource__c> newPSRList){
        system.debug('*** -- Into updateTypeAndCostings -- ***');
        Set<Id> psIdSet = new Set<Id>();

        for (Product_Service_Resource__c psr : newPSRList){
            psIdSet.add(psr.Product_Service__c);
        }

        Map<Id, Product_Service__c> psMap = new Map<Id, Product_Service__c>([select Id, Annual_Cost__c, Monthly_Cost__c, Type__c from Product_Service__c where Id in :psIdSet]);
        
        for (Product_Service_Resource__c psr : newPSRList){
            if (null != psr.Product_Service__c){
                Product_Service__c ps = psMap.get(psr.Product_Service__c);
                psr.Product_Service_Annual_Cost__c = (null != ps && null != ps.Annual_Cost__c ? ps.Annual_Cost__c : 0);
                psr.Product_Service_Monthly_Cost__c = (null != ps && null != ps.Monthly_Cost__c ? ps.Monthly_Cost__c : 0);
                psr.Product_Service_Type__c = (null != ps && null != ps.Type__c ? ps.Type__c : null);
            }
        }
    } 
}