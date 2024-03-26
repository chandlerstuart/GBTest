/*
Name:  BookingExperienceTriggerTest
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Suite for for BookingExperience__c trigger activity

======================================================
======================================================

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-02-13  Initial development. Note - At the time of creation there is no handler or bl class. The trigger simply invokes the SUP (Salesforce Utility Package)
*/
@isTest
public with sharing class BookingExperienceTriggerTest {

    //testScenario1 - Entity Locking - Confirm users cannot edit or delete a locked entity record without the custom permissions.

    
    @TestSetup static void createTestData(){
        
        User adminUser = AP23_TestDataFactory.createAdminUsers(1, 'BookingExp_Admin', true)[0];
        Id runningUserId = UserInfo.getUserId();

        //1.1+ Assign edit/delete permissions 
        system.runAs(adminUser){
            PermissionSet ps = [Select Id From PermissionSet Where Name = :ApplicationConstant.ENTITY_LOCKING_PERMISSION_SET_NAME];
            insert new PermissionSetAssignment(AssigneeId=runningUserId,PermissionSetId=ps.Id);
        }
    }

    @isTest static void testScenario1(){
 
        //Confirm the running user can successfully insert, update and delete a Booking Experience record (by default).
        BookingExperience__c bookingExp = new BookingExperience__c();
        bookingExp.Name = 'Experience 1';
        bookingExp.Type__c = ApplicationConstant.BOOKING_EXPERIENCE_TYPE_STANDARD;
        insert bookingExp;
        System.assertEquals(1,[Select Count() From BookingExperience__c]);
        
        //Reset vals
        golfbreaks.EntityAdministrationLockManager.recs = null;
        golfbreaks.EntityAdministrationLockManager.opType = null;

        update bookingExp; 
        
        //Reset vals
        golfbreaks.EntityAdministrationLockManager.recs = null;
        golfbreaks.EntityAdministrationLockManager.opType = null;
        delete bookingExp;
        
        System.assertEquals(0,[Select Count() From BookingExperience__c]); 

        Boolean updateFailure = false;
        Boolean deleteFailure = false;

        //Remove permissions 
        User adminUser = [Select Id From User Where LastName Like 'BookingExp_Admin%']; 
        Id runningUserId = UserInfo.getUserId();
        System.runAs(adminUser){
            delete [Select Id From PermissionSetAssignment Where PermissionSet.Name = :ApplicationConstant.ENTITY_LOCKING_PERMISSION_SET_NAME and AssigneeId = :runningUserId];
        }

        Test.startTest();

            //Reset vals
            golfbreaks.EntityAdministrationLockManager.recs = null;
            golfbreaks.EntityAdministrationLockManager.opType = null;

            BookingExperience__c bookingExp2 = new BookingExperience__c();
            bookingExp2.Name = 'Experience 2';
            bookingExp2.Type__c = ApplicationConstant.BOOKING_EXPERIENCE_TYPE_STANDARD;
            insert bookingExp2;
            System.assertEquals(1,[Select Count() From BookingExperience__c]);

            //Reset vals
            golfbreaks.EntityAdministrationLockManager.recs = null;
            golfbreaks.EntityAdministrationLockManager.opType = null;
            try{
                update bookingExp2;
            }catch(Exception e){
                updateFailure = true;
                System.assertEquals(true, e.getMessage().contains('Entity Administration Locked'));//Verify expected failure
            }
            System.assertEquals(true, updateFailure);
            
            //Reset vals
            golfbreaks.EntityAdministrationLockManager.recs = null;
            golfbreaks.EntityAdministrationLockManager.opType = null;
            try{
                delete bookingExp2;
            }catch(Exception e){
                deleteFailure = true;
                System.assertEquals(true, e.getMessage().contains('Entity Administration Locked'));
            }
            System.assertEquals(true, deleteFailure);//Verify expected failure

            System.assertEquals(1,[Select Count() From BookingExperience__c]);//Record remains

        Test.stopTest();

    }



}