/*
Class:  BusinessHoursActionTest.cls
Copyright © 2024  Golfbreaks
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) code behaviour related to the action BusinessHoursAction.

Coverage for classes below (target 85%):
BusinessHoursAction.cls : 78%

======================================================
======================================================
Revision History
---------------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2024-02-08  Initial development.
*/
@isTest 
public class BusinessHoursActionTest {

    /*
    Test cases:
        singleTestCase1 - Business Logic. Simple isWithin [Business Hours] test.
    */

    @testSetup static void setup(){ }

    /* **/    
    static testMethod void singleTestCase1() {
        // Test Case 1 : Business Logic. Business Logic. Simple isWithin [Business Hours] test.

        if ([select count() from BusinessHours where IsDefault=true]==0) return;
        
        BusinessHours bh = [select Id, Name from BusinessHours where IsDefault=true];
        
        Datetime nextStartDt = BusinessHours.nextStartDate(bh.Id, Datetime.now());

        Boolean isWithin1 = BusinessHours.isWithin(bh.Id,nextStartDt);
        Boolean isWithin2 = BusinessHours.isWithin(bh.Id,nextStartDt.addMinutes(-10));

        BusinessHoursAction.ActionRequest request;
        List<BusinessHoursAction.ActionRequest> requests = new List<BusinessHoursAction.ActionRequest>();
        
        request = new BusinessHoursAction.ActionRequest();
        request.businessHoursName = bh.Name;
        request.timeToCheck = nextStartDt;
        requests.add(request);

        request = new BusinessHoursAction.ActionRequest();
        request.businessHoursName = bh.Name;
        request.timeToCheck = nextStartDt.addMinutes(-10);
        requests.add(request);

        List<BusinessHoursAction.ActionResult> results = BusinessHoursAction.checkIsWithinBusinessHours(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.areEqual(isWithin1,results[0].isWithinBusinessHours);

        Assert.isTrue(results[1].isSuccess);
        Assert.areEqual(isWithin2,results[1].isWithinBusinessHours);
    }/* */
}