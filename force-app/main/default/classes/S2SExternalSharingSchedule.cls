/*
Name:  S2SExternalSharingSchedule.cls
======================================================
======================================================
Purpose:
-------
To enable scheduling of external sharing of child records
Due to delays in the sharing of the parent record

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-11-17  Initial Development.
1.1  Simon Molloy  2017-12-07  Corrected code to use 'scope' in main processing block
*/
global class S2SExternalSharingSchedule implements Schedulable, Database.Batchable<sObject> {
  global static final String CLASS_NAME = 'S2SExternalSharingSchedule';
  global List<Error_Log__c> logs {get; set;}
  global String query {get; set;}
  global String whichObject {get; set;}
  global String parentFieldName {get; set;}
  global Set<Id> recordIds {get; set;}
  global String relatedObjects {get; set;}

  global S2SExternalSharingSchedule(Set<Id> recordIds, String whichObject, String parentFieldName, String relatedObjects){
    this.recordIds = recordIds;
    this.whichObject = whichObject;
    this.parentFieldName = parentFieldName;
    this.relatedObjects = relatedObjects;
  }


  //Batchable calls
  global Database.QueryLocator start(Database.BatchableContext BC) {

    if (null == query){
        query = 'SELECT Id, ConnectionReceivedId, ' + parentFieldName;        
        query += ' FROM ';        
        query += whichObject;
        query += ' WHERE Id in :recordIds';
    }

    system.debug('*** -- QUERY : ' + query + ' -- ***');

    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    if (null != scope && !scope.isEmpty()){
      S2SExternalSharingHelper helper = new S2SExternalSharingHelper();
      helper.isFromTrigger = FALSE;
      helper.shareRecordsFromTrigger(scope, parentFieldName, whichObject, true, relatedObjects);
    }
  }

  global void finish(Database.BatchableContext BC) {

  }

  //Schedulable call
  global void execute(SchedulableContext sc) {
    System.abortJob(sc.getTriggerId());
    S2SExternalSharingSchedule s2sSchedule = new S2SExternalSharingSchedule(recordIds, whichObject, parentFieldName, relatedObjects);
    Database.executeBatch(s2sSchedule, 100);
  }
}