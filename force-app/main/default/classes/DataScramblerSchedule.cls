/*
Name:  DataScramblerSchedule.cls
======================================================
======================================================
Purpose:
-------
Scheduled Class used to call DataScrambler

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-30  Initial development.
1.1  Simon Molloy  2018-01-02  Added in check to make sure this does NOT run on Live instance
*/
global class DataScramblerSchedule implements Schedulable {
    global String LIVE_URL = 'https://golfbreaks.my.salesforce.com';

    global void execute(SchedulableContext sc) {
        //Safety measure to ensure this does not run in LIVE
        if (!Test.isRunningTest() && LIVE_URL.equalsIgnoreCase(URL.getSalesforceBaseUrl().toExternalForm())){
            return;
        }
        DataScrambler leadDS = new DataScrambler('Lead');
        DataScrambler leadAcc = new DataScrambler('Account');
        
        Database.executebatch(leadDS,100);
        Database.executebatch(leadAcc,100);
    }
}