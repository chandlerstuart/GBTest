/*
Name:  LiveChatTranscriptTestSuite.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) Trigger code
behaviour on the LiveChatTranscript object plus related code.

Coverage for classes below (target 85%):
LiveChatTranscriptTriggerHandler.cls : 92%
PostChatController.cls : 89%

Future enhancements: tbc
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-08-05  Initial development.
*/
@isTest
private class LiveChatTranscriptTestSuite {
    /*
    Test cases:
        singleTestCase1 - Transcript saved after Rating record (ApexTrigger).
        singleTestCase2 - Transcript saved before Rating record (Controller JS Remoting Method).
        bulkTestCase1 - bulk record (200) test of the singleTestCase1 logic.
    */
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test Case 1 : Transcript saved after Rating record (ApexTrigger)
        //Steps. Create orphaned rating record. Insert Transcript with shared ChatKey and check parenting occurred.
 		
 		LiveChatVisitor visitor = new LiveChatVisitor();
 		insert visitor;
 		
 		LiveChatTranscript transcript = new LiveChatTranscript();
 		transcript.Status = 'Completed';
 		transcript.ChatKey = 'Test';
 		transcript.LiveChatVisitorId = visitor.Id; 
 		
 		Live_Chat_Transcript_Rating__c rating = new Live_Chat_Transcript_Rating__c();
 		rating.Chat_Key__c = 'Test';
 		rating.Question_Rating__c = 1;
 		rating.Again_Rating__c = 1;
 		insert rating;
 		
 		Test.startTest();
 		insert transcript;
 		Test.stopTest();
 		
		System.assertEquals(transcript.Id, [select Live_Chat_Transcript__c from Live_Chat_Transcript_Rating__c where Id=:rating.Id].Live_Chat_Transcript__c, 'Rating should be parented to transcript'); 		
    }
    /* */
    
    /* **/
    static testMethod void singleTestCase2() {
        // Test Case 2 : Transcript saved before Rating record (Controller JS Remoting Method)
        //Steps. Create Transcript record. Insert rating with shared ChatKey and check parenting occurred.
 		LiveChatVisitor visitor = new LiveChatVisitor();
 		insert visitor;
 		
 		LiveChatTranscript transcript = new LiveChatTranscript();
 		transcript.Status = 'Completed';
 		transcript.ChatKey = 'Test';
 		transcript.LiveChatVisitorId = visitor.Id; 
 		insert transcript;
 		
 		Test.startTest();
 		PostChatController.persistRatings('Test', '-1', '5');
 		Test.stopTest();
 		
 		System.assertEquals(1, [select count() from Live_Chat_Transcript_Rating__c], 'Rating should be inserted'); 		
		System.assertEquals(transcript.Id, [select Live_Chat_Transcript__c from Live_Chat_Transcript_Rating__c limit 1].Live_Chat_Transcript__c, 'Rating should be parented to transcript'); 		
    }
    /* */
    
    /* **/
    static testMethod void bulkTestCase1() {
        // Bulk Test Case 1 : bulk record (200) test of the singleTestCase1 logic.
        final Integer TEST_REC_SIZE=200;
        
 		LiveChatVisitor visitor = new LiveChatVisitor();
 		insert visitor;
 		
 		LiveChatTranscript transcript;
 		List<LiveChatTranscript> transcripts = new List<LiveChatTranscript>();
 		
 		Live_Chat_Transcript_Rating__c rating;
 		List<Live_Chat_Transcript_Rating__c> ratings = new List<Live_Chat_Transcript_Rating__c>();

		for (Integer i=0; i<TEST_REC_SIZE; i++){
 			transcript = new LiveChatTranscript();
 			
 			transcript.Status = 'Completed';
 			transcript.ChatKey = 'Test'+i;
	 		transcript.LiveChatVisitorId = visitor.Id;	 		
	 		transcripts.add(transcript);
	 		
	 		rating = new Live_Chat_Transcript_Rating__c();
	 		rating.Chat_Key__c = 'Test'+i;
 			rating.Question_Rating__c = 1;
 			rating.Again_Rating__c = 1;	 		
	 		ratings.add(rating);
		}
		
		insert ratings;

 		Test.startTest();
 		insert transcripts;
 		Test.stopTest();
 		
		System.assertEquals(TEST_REC_SIZE, [select count() from Live_Chat_Transcript_Rating__c where Live_Chat_Transcript__c<>null], 'Ratings should be parented to transcripts');
		System.assertEquals(transcripts[0].Id, [select Live_Chat_Transcript__c from Live_Chat_Transcript_Rating__c where Id=:ratings[0].Id].Live_Chat_Transcript__c, 'Rating should be parented to transcript');        
    }
    /* */

	@testSetup static void setup(){  	
        OrgSettings__c orgSettings = OrgSettings__c.getInstance( UserInfo.getOrganizationId() );
        if (!orgSettings.TriggersActive__c){        
        	orgSettings.TriggersActive__c = true;  
        	insert orgSettings;
        }
    }
}