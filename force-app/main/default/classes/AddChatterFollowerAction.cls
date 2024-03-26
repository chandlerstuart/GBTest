/*
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------

Adds Chatter Followers via the EntitySubscription object.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-12-06  Initial development.
*/
global without sharing class AddChatterFollowerAction {

    @InvocableMethod(label='Add Chatter Record Follower' description='Creates an EntitySubscription record for the specified user Id and record Id.')
    global static List<Boolean> addChatterFollower(List<AddChatterFollowerRequest> addRequests){
        
        List<Boolean> results = new List<Boolean>();
            
        try {

            AddChatterFollowerRequest r;
            List<EntitySubscription> entitySubsToInsert = new List<EntitySubscription>();
            
            for (Integer i=0; i<addRequests.size(); i++){
                results.add(false);
                
                r = addRequests[i];
                
                entitySubsToInsert.add( new EntitySubscription(SubscriberId=r.userId, ParentId=r.recordId) );                
            }
            
            List<Database.SaveResult> saveResults = Database.insert( entitySubsToInsert, false );
            
            for (Integer i=0; i< saveResults.size(); i++){                
                if (SaveResults[i].isSuccess()){
                    results[i] = true;
                }
            }
            
        } catch(Exception e){ RuntimeExceptionHelper.logException(e); }
        return results;
    }
    
    global class AddChatterFollowerRequest {
        @InvocableVariable(label='User Id' description='User record Id.' required=true)
        global String userId;

        @InvocableVariable(label='Record Id' description='Record Id.' required=true)
        global String recordId;        
    }       
}