/**
* @author -         Abrar Haq (Accenture)
* @date -           27/06/2015
* @description -    A test class for a utility class "APIMockResponseUtility"
* #############Change Log#############
* Modified by     Version     Change Date
**/
@isTest
private class APIMockResponseUtilityTest {

    /*    
    Considerations for @testSetup:
    -If a test class contains a test setup method, the test setup method executes first, before any test method in the class.
    -Records that are created in a test setup method are available to all test methods in the test class and are rolled back at the end of test class execution.
    -If a test method changes those records, such as record field updates or record deletions, those changes are rolled back after each test method finishes execution. The next executing test method gets access to the original unmodified state of those records.
    -It takes no arguments, and return no value.
        @testSetup static void methodName(){
        }
    -@testSetup method only works with the default data isolation mode "@isTest(SeeAllData=true)" for a test class.
    It does not work with "@isTest(​SeeAllData=​true)". Because data isolation for tests is available for API versions 24.0 and later, test setup methods are also available for those versions only.
    Otherwise you will get an error:
    Test class containing a test setup method cannot be annotated with @isTest(​SeeAllData=​true)
    -Multiple @testSetup methods are allowed in a test class, but the order in which they’re executed by the testing framework isn’t guaranteed.
    -If a fatal error occurs during the execution of a @testSetup method, such as an exception that’s caused by a DML operation or an assertion failure, the entire test class fails, and no further tests in the class are executed.
    -If a @testSetup method calls a non-test method of another class, no code coverage is calculated for the non-test method.
    */        
    @testSetup static void setupCommonData(){

    }

    @isTest static void test_getBreakpointsAPIMockResponse() {
        // Breakpoints API
        String mockResponseBreakpointsAPI = APIMockResponseUtility.getBreakpointsAPIMockResponse();
        System.assert( String.isNotBlank(mockResponseBreakpointsAPI) );
    }

    @isTest static void test_getGuestGroupJSON() {
        // GuestGroup API
        String mockResponseGuestGroupAPI = APIMockResponseUtility.getGuestGroupJSON();
        System.assert( String.isNotBlank(mockResponseGuestGroupAPI) );
    }

    @isTest static void test_getQuoteANDBookingSundriesJSON() {
        // Quotes and Booking Sundries JSON API
        String mockResponseQuoteANDBookingSundriesJSONAPI = APIMockResponseUtility.getQuoteANDBookingSundriesJSON();
        System.assert( String.isNotBlank(mockResponseQuoteANDBookingSundriesJSONAPI) );
    }

    @isTest static void test_getGolfbreaksImageAPIJSON() {
        // Golfbreaks Image API
        String mockResponseGolfbreaksImageAPI = APIMockResponseUtility.getGolfbreaksImageAPIJSON();
        System.assert( String.isNotBlank(mockResponseGolfbreaksImageAPI) );
    }
    
    @isTest static void test_getBrowserCookieJSON() {
        // BrowserCookie API
        String mockResponseBrowserCookieAPI = APIMockResponseUtility.getBrowserCookieJSON();
        System.assert( String.isNotBlank(mockResponseBrowserCookieAPI) );
    }

    @isTest static void test_getBookingIdsJSON() {
        // BookingIds API
        String mockResponseBookingIdsAPI = APIMockResponseUtility.getBookingIdsJSON();
        System.assert( String.isNotBlank(mockResponseBookingIdsAPI) );
    }
    
}