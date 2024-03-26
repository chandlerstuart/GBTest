/**
* @author -         Patrick Villarica (Accenture)
* @date -           14/04/2016
* @description -    Implement schedulable for the batch process AP22_ExpectedPaymentAdminCaseBatch 
* #############Change Log#############
* Modified by     Version     Change Date
**/

global class AP33_EPaymentAdminCaseBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {
        AP22_ExpectedPaymentAdminCaseBatch executeEPAdminCaseBatch = new AP22_ExpectedPaymentAdminCaseBatch();
        database.executebatch(executeEPAdminCaseBatch);
    }
}