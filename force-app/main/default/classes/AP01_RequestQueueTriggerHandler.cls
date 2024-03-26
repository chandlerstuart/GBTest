/**
* @author -         Abrar Haq (Accenture)
* @date -           01/04/2016
* @description -    Trigger handler for Request Queue object. 
* #############Change Log#############
* Modified by     Version     Change Date
**/
public with sharing class AP01_RequestQueueTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    // Trigger After Insert context
    public void OnAfterInsert(Request_Queue__c[] newlstRequestQueue){
        if(!isAfterInsertTriggerCalled){
            runRequestQueueBatchProcess(newlstRequestQueue);
            
            isAfterInsertTriggerCalled = TRUE;
        }
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         01/04/2016
    Version -      1.0 
    Function -     Run Batch Process to process Request Queue records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void runRequestQueueBatchProcess(List<Request_Queue__c> lstRequestQueue){
        if( lstRequestQueue.size() > 0 ){
            RequestQueueUtility.runRequestQueueBatch();
        }
    }
    
}