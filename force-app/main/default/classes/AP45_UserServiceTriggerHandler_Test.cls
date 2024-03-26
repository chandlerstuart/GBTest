@isTest
public class AP45_UserServiceTriggerHandler_Test{
    private static testMethod void tstHndler(){
        List<UserServicePresence> newUserServicePresenceList = new List<UserServicePresence>();
        List<UserServicePresence> oldUserServicePresenceList = new List<UserServicePresence>();
        
        
        List<UserServicePresence> userPresenceList = new List<UserServicePresence>();
        for(integer i=0; i<20; i++){
            UserServicePresence usrprsnce = new UserServicePresence();
            usrprsnce.UserId = Userinfo.getuserID();
            userPresenceList.add(usrprsnce);
        }
        insert userPresenceList;
        
        System.assertEquals(userPresenceList.size(), 20);
        
        newUserServicePresenceList.addAll(userPresenceList);
        oldUserServicePresenceList.addAll(userPresenceList);
        Map<Id,UserServicePresence> newUserServicePresenceMap = new Map<Id,UserServicePresence>([SELECT Id FROM UserServicePresence]);
        Map<Id,UserServicePresence> oldUserServicePresenceMap = new Map<Id,UserServicePresence>([SELECT Id FROM UserServicePresence]);
        
        test.startTest();
        AP45_UserServiceTriggerHandler usp = new AP45_UserServiceTriggerHandler();
        //Calling methods since updating userservicepresence receives an error.
        usp.OnBeforeInsert(newUserServicePresenceList);
        usp.OnAfterInsert(newUserServicePresenceList);

        usp.OnBeforeUpdate(newUserServicePresenceList, newUserServicePresenceMap, oldUserServicePresenceList, oldUserServicePresenceMap);
        usp.OnAfterUpdate(newUserServicePresenceList, newUserServicePresenceMap, oldUserServicePresenceList, oldUserServicePresenceMap);
        
        usp.OnBeforeDelete(newUserServicePresenceList, newUserServicePresenceMap, oldUserServicePresenceList, oldUserServicePresenceMap);
        usp.OnAfterDelete(newUserServicePresenceList, newUserServicePresenceMap, oldUserServicePresenceList, oldUserServicePresenceMap);
        
        usp.OnUndelete(newUserServicePresenceList, newUserServicePresenceMap, oldUserServicePresenceList, oldUserServicePresenceMap);
        usp.OnAfterUnDelete(newUserServicePresenceList, newUserServicePresenceMap, oldUserServicePresenceList, oldUserServicePresenceMap);
        
        test.stopTest();
    }
}