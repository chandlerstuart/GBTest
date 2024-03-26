/*
Name: BookingSystemAssignmentRuleHelperTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for BookingSystemAssignmentRuleHelperHelper class.

Coverage for classes below (target 85%):
BookingSystemAssignmentRuleHelperTest.cls : 76%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-07  Initial development.
*/
@isTest(SeeAllData=false)
public with sharing class BookingSystemAssignmentRuleHelperTest {
	/*
    Test cases:
        singleTestCase1a - Booking System assigned via single Rule Entry - Integer - Greater than.
        singleTestCase1b - Booking System assigned via single Rule Entry - String - Contains.
        singleTestCase1c - Booking System assigned via single Rule Entry - Boolean - Equals.
        singleTestCase1d - Booking System assigned via single Rule Entry - List - Contains.
        ..
        negativeTestCase1 - No Booking System assigned.
        ..
        bulkTestCase1 - BusinessLogic. todo.
	*/
	
    @testSetup static void setup(){}
    
    /* **/
    static testMethod void singleTestCase1a() {
        // Test case 1a : Booking System assigned via single Rule Entry - Integer - Greater than.

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';
        e.tripDetails.groupSize=3;// rule is greater than 2.
        e.propertyCache.putAll(e.tripDetails.propertyCache);
        
		Test.startTest();
        List<EnquiryManager.Enquiry> enquiriesToAssign = new List<EnquiryManager.Enquiry> { e };        
        System.assert(BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiriesToAssign));
		Test.stopTest();
        
        System.assertEquals('Clubhouse', e.bookingSystem);
  	}
    /* */

    /* **/
    static testMethod void singleTestCase1b() {
        // Test case 1b : Booking System assigned via single Rule Entry - String - Contains.

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';
        e.tripDetails.additionalInformation='This is a PGA enquiry';// rule is contains Scotland.
        e.propertyCache.putAll(e.tripDetails.propertyCache);
        
		Test.startTest();
        List<EnquiryManager.Enquiry> enquiriesToAssign = new List<EnquiryManager.Enquiry> { e };        
        System.assert(BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiriesToAssign));
		Test.stopTest();
        
        System.assertEquals('Clubhouse', e.bookingSystem);
  	}
    /* */

    /* **/
    static testMethod void singleTestCase1c() {
        // Test case 1c : Booking System assigned via single Rule Entry - Boolean - Equals.

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';
        e.tripDetails.tournamentEnquiry=true;// rule is TRUE.
        e.propertyCache.putAll(e.tripDetails.propertyCache);
        
		Test.startTest();
        List<EnquiryManager.Enquiry> enquiriesToAssign = new List<EnquiryManager.Enquiry> { e };        
        System.assert(BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiriesToAssign));
		Test.stopTest();
        
        System.assertEquals('Clubhouse', e.bookingSystem);
  	}
    /* */

    /* **/
    static testMethod void singleTestCase1d() {
        // Test case 1d : Booking System assigned via single Rule Entry - List - Contains.

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';
        e.tripDetails.countries=new List<String>{ 'Scotland'};// rule is Contains Scotland.
        e.propertyCache.putAll(e.tripDetails.propertyCache);
        
		Test.startTest();
        List<EnquiryManager.Enquiry> enquiriesToAssign = new List<EnquiryManager.Enquiry> { e };        
        System.assert(BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiriesToAssign));
		Test.stopTest();
        
        System.assertEquals('Clubhouse', e.bookingSystem);
  	}
    /* */

    /* **/
    static testMethod void negativeTestCase1() {
        // Negative test case 1 : No Booking System assigned.

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';
        e.tripDetails.groupSize=1;// rule is greater than 2.
        e.propertyCache.putAll(e.tripDetails.propertyCache);
        
		Test.startTest();
        List<EnquiryManager.Enquiry> enquiriesToAssign = new List<EnquiryManager.Enquiry> { e };        
        System.assert(BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiriesToAssign));
		Test.stopTest();
        
        System.assertNotEquals('Clubhouse', e.bookingSystem);
  	}
    /* */
}