/*
Name:  QuickCalloutButtonController.cls
======================================================
======================================================
Purpose: Controller for QuickCalloutButton lwc
-------

The QuickCalloutButton lwc can be displayed (dynamically) 
on any record page (via Lightning App Builder). When selected
the action will execute a callout using the Id of the related
record and the configured DET.

The results are displayed in a Toast Message

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-02-04  Initial development.
*/
public with sharing class QuickCalloutButtonController {

    public Class ActionResult{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String responseBody;
        public ActionResult(Boolean isSuccess,String errorMessage,String responseBody){
            this.isSuccess = isSuccess;
            this.errorMessage = errorMessage;
            this.responseBody = responseBody;
        }
    }

    @AuraEnabled
    public static ActionResult executeCallout(Id recordId, String dataEventType){

        try {
            //Validate Input
            System.assertEquals(1, [Select Count() From DataEventType__mdt Where DeveloperName =:dataEventType and IsActive__c = true], 'Could not find Active Data Event Type called '+dataEventType);
            if(recordId == null) return new ActionResult(false,'A record Id must be provided',null);

            //Execute Callout
            List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ new DataEventTypeAction.DataEventTypeActionRequest(dataEventType,recordId)});
            if(detaResults == null || detaResults.size()==0) return new ActionResult(false,'No results were returned from callout action',null);

            //Assess Results
            DataEventTypeAction.DataEventTypeActionResult result = detaResults[0];
            //[Removed for release] system.debug('RESULT > '+result);
            if(result.isSuccess){
                return new ActionResult(true,null,null);
            }else{
                return new ActionResult(false,result.errorMessage,result.responseBody);
            }

        } catch (Exception e) {
            LogHelper.logExceptions(e, 'QuickCalloutButtonController', 'executeCallout');
            return new ActionResult(false,'Error attempting to execute action: '+e.getMessage()+'-'+e.getStackTraceString(),null);
        }
    }
}