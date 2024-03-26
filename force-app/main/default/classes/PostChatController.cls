/*
Name:  PostChatController.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------

Controller class for the Visualforce page : Post_Chat.page
implemented in the context of LiveAgent.

Without Sharing implemented to enable Account relationship field
population without providing read permissions for all Client records.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-08-05  Initial development. 
1.1  Mark Cane&    2016-02-08  Without Sharing modifier change.
*/
global without sharing class PostChatController {

    public PostChatController() { } // empty constructor
    
    @RemoteAction
    global static void persistRatings(String chatKey, String questionRating, String againRating) {
        System.debug(LoggingLevel.ERROR, 'FINDME>>chatKey:'+chatKey+'>>questionRating:'+questionRating+'+>>againRating:'+againRating);

        try {
            if (String.isBlank(chatKey)) return; // The rating data can't be related to a parent transcript without a Chat Key.
            
            LiveChatTranscript transcript;

            List<LiveChatTranscript> transcripts = [select Id, OwnerId, AccountId from LiveChatTranscript where ChatKey=:chatKey limit 1];          
            if (transcripts.size()==1) transcript = transcripts[0]; 

            
            Integer questionRatingVal = (questionRating.equals('-1') || !questionRating.isNumeric()) ? null : Integer.valueOf(questionRating);
            Integer againRatingVal = (againRating.equals('-1') || !againRating.isNumeric()) ? null : Integer.valueOf(againRating);
            
            Live_Chat_Transcript_Rating__c rating = new Live_Chat_Transcript_Rating__c( Chat_Key__c=chatKey,
                                                                                        Question_Rating__c=questionRatingVal, 
                                                                                        Again_Rating__c=againRatingVal);        
            if (transcript!=null){
                rating.Live_Chat_Transcript__c = transcript.Id;
                if (transcript.AccountId!=null) rating.Account__c = transcript.AccountId;
                rating.OwnerId = transcript.OwnerId;
            }
            
            insert rating;
        } catch (Exception e){ RuntimeExceptionHelper.logException(e); }
    }
}