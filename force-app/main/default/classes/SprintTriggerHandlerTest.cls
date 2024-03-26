/*
Name:  SprintTriggerHandlerTest.cls
======================================================
======================================================
Purpose:
-------
Test class for SprintTriggerHandler.cls

======================================================
======================================================
History
------- 
Ver. Author             Date        Detail
1.0  James Radcliffe    2017-09-01  Initial development.
*/

@IsTest
public class SprintTriggerHandlerTest{

    @testSetup
    public static void buildTestData(){
    
    //Create a Sprint that finishes today
    Sprint__c activeSprint = new Sprint__c();
    activeSprint.Name = ApplicationConstant.ACTIVE_SPRINT;
    activeSprint.Start_Date__c = system.today().addDays(-14);
    activeSprint.End_Date__c = system.today();
    activeSprint.Type__c = ApplicationConstant.SALESFORCE_SPRINT_TYPE ;
    insert activeSprint;
    
    //Create a Sprint that starts tomorrow and finishes in two weeks
    Sprint__c inactiveSprint = new Sprint__c();
    inactiveSprint.Name = ApplicationConstant.INACTIVE_SPRINT;
    inactiveSprint.Start_Date__c = system.today().addDays(1);
    inactiveSprint.End_Date__c = system.today().addDays(14);
    inactiveSprint.Type__c = ApplicationConstant.SALESFORCE_SPRINT_TYPE;
    insert inactiveSprint;
    
    }
    
    //This method ensures an error is presented to the user when they attempt to insert or update a Sprint record that will result in two overlapping Sprints of the same type
    public static testMethod void testOverlappingSprintValidation(){
    
    //Attempt to insert an overlapping Sprint with a matching type (should fail)
    
    //Create a Sprint that finishes today
    Sprint__c newActiveSprint = new Sprint__c();
    newActiveSprint.Name = 'New Active Sprint';
    newActiveSprint.Start_Date__c = system.today().addDays(-21);
    newActiveSprint.End_Date__c = system.today().addDays(-7);
    newActiveSprint.Type__c = ApplicationConstant.SALESFORCE_SPRINT_TYPE;
    try{
        insert newActiveSprint;  
    }catch(Exception e){
        boolean expectedExceptionThrown = e.getMessage().contains(ApplicationConstant.OVERLAPPING_SPRINT_ERROR)?true:false;
        system.assertEquals(expectedExceptionThrown,true);
    }  
    
    //Attempt to update a Sprint with a matching type to overlap with an existing Sprint (should fail)
    
    //Retrieve the Inactive Sprint
    String inactiveSprint = ApplicationConstant.INACTIVE_SPRINT;
    Sprint__c sprint = [Select Id, Start_Date__c, Name From Sprint__c Where Name = :inactiveSprint LIMIT 1];
    system.debug('Inactive Sprint Id: '+sprint.Id);
    //Set the Start Date to be within the previous Sprint's timeframe
    if(sprint != null){
        sprint.Start_Date__c = system.today().addDays(-7);
    }
    try{
        update sprint;
    }catch(Exception e){
        boolean expectedExceptionThrown = e.getMessage().contains(ApplicationConstant.OVERLAPPING_SPRINT_ERROR)?true:false;
        system.assertEquals(expectedExceptionThrown,true);    
    }
   
    //Insert a Sprint of the same type that does not overlap and an overlapping Sprint with of a different type (both should insert successfully)
    List<Sprint__c> newSprints = new List<Sprint__c>();
    
    //Create a Sprint that Spans the two other Sprints, but has a different type
    Sprint__c sprint2 = new Sprint__c();
    sprint2.Name = ApplicationConstant.OTHER_SPRINT;
    sprint2.Start_Date__c = system.today().addDays(-7);
    sprint2.End_Date__c = system.today().addDays(7);
    sprint2.Type__c = applicationConstant.WEB_SPRINT_TYPE;
    newSprints.add(sprint2);
    
    //Create a Sprint with the same type as existing Sprints but with dates that do not overlap
    Sprint__c sprint3 = new Sprint__c();
    sprint3.Name = ApplicationConstant.OTHER_SPRINT+2;
    sprint3.Start_Date__c = system.today().addDays(15);
    sprint3.End_Date__c = system.today().addDays(29);
    sprint3.Type__c = applicationConstant.SALESFORCE_SPRINT_TYPE;
    newSprints.add(sprint3);
    
    //Check the number of Sprint records before the insert
    Integer sprintCountBefore = [Select Id From Sprint__c].size();
    
    test.startTest();
        insert newSprints;
    test.stopTest();
    
    //Check the number of Sprint records after the insert
    Integer sprintCountAfter = [Select Id From Sprint__c].size();
    
    system.assertEquals(sprintCountBefore+2,sprintCountAfter);
    
    }

}