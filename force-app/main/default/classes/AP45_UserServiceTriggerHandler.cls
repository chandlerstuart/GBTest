public with sharing class AP45_UserServiceTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    //2017-03-10 : SM : Modified call to BL class, to populate a userIdSet to help filter records
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    
    public AP45_UserServiceTriggerHandler() {
        
    }

    public void OnBeforeInsert(List<UserServicePresence> newUserServicePresenceList){
        
    }   
    
    public void OnBeforeUpdate(List<UserServicePresence> newUserServicePresenceList, Map<Id,UserServicePresence> newUserServicePresenceMap, List<UserServicePresence> oldUserServicePresenceList, Map<Id,UserServicePresence> oldUserServicePresenceMap){
           
    }
    
    public void OnAfterInsert(List<UserServicePresence> newUserServicePresenceList){
        if(!isAfterInsertTriggerCalled){
            //2017-03-10 : SM : Collate and populate userIdSet in the BL class
            Set<Id> userIdSet = new Set<Id>();
            for (UserServicePresence usp : newUserServicePresenceList){
                userIdSet.add(usp.UserId);
            }
            AP08_UserServicePresenceTriggerBL BL = new AP08_UserServicePresenceTriggerBL();
            BL.userIdSet = userIdSet;

            BL.bulkAfter();
    
            for(UserServicePresence rec : newUserServicePresenceList){
                BL.afterInsert((SObject)rec);
            }
    
            BL.runAfterInsertTrigger();
            BL.andFinally(); 
            
            isAfterInsertTriggerCalled = TRUE;
            
        }  
    }
    
    public void OnAfterUpdate(List<UserServicePresence> newUserServicePresenceList, Map<Id,UserServicePresence> newUserServicePresenceMap, List<UserServicePresence> oldUserServicePresenceList, Map<Id,UserServicePresence> oldUserServicePresenceMap){
        if(!isAfterUpdateTriggerCalled){
            //2017-03-10 : SM : Collate and populate userIdSet in the BL class
            Set<Id> userIdSet = new Set<Id>();
            for (UserServicePresence usp : newUserServicePresenceList){
                userIdSet.add(usp.UserId);
            }
            AP08_UserServicePresenceTriggerBL BL = new AP08_UserServicePresenceTriggerBL();
            BL.userIdSet = userIdSet;
            BL.bulkAfter();
    
            for(UserServicePresence rec : newUserServicePresenceList){
                BL.afterUpdate( (SObject)oldUserServicePresenceMap.get(rec.Id) ,(SObject)rec);
            }
    
            BL.runAfterUpdateTrigger();
            BL.andFinally();
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
    
    public void OnBeforeDelete(List<UserServicePresence> newUserServicePresenceList, Map<Id,UserServicePresence> newUserServicePresenceMap, List<UserServicePresence> oldUserServicePresenceList, Map<Id,UserServicePresence> oldUserServicePresenceMap){
        
    }
    
    public void OnAfterDelete(List<UserServicePresence> newUserServicePresenceList, Map<Id,UserServicePresence> newUserServicePresenceMap, List<UserServicePresence> oldUserServicePresenceList, Map<Id,UserServicePresence> oldUserServicePresenceMap){
        
    }
     
    public void OnAfterUnDelete(List<UserServicePresence> newUserServicePresenceList, Map<Id,UserServicePresence> newUserServicePresenceMap, List<UserServicePresence> oldUserServicePresenceList, Map<Id,UserServicePresence> oldUserServicePresenceMap){
        
    }
    
    public void OnUndelete(List<UserServicePresence> newUserServicePresenceList, Map<Id,UserServicePresence> newUserServicePresenceMap, List<UserServicePresence> oldUserServicePresenceList, Map<Id,UserServicePresence> oldUserServicePresenceMap){
        
    }
}