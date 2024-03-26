/*
Name:  EmpCommunity_GBNewsGroupUpdate.cls
Copyright © 2016  Golfbreaks.
======================================================
======================================================
Purpose:
-------
Utility class to make sure all memebers of the community are in
the Golfbreaks News group

======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Simon Molloy      2016-10-12  Class creation.

*/
global class EmpCommunity_GBNewsGroupUpdate implements schedulable {
    global static final String EMP_COMMUNITY_NAME = 'The Locker Room';
    
    global void execute(SchedulableContext sc){
        //Call the main method
        updateGroupMembers();
    }
    
    global static void updateGroupMembers(){
       List<Network> commList = [select Id from Network where Name = :EMP_COMMUNITY_NAME LIMIT 1];
       
       List<NetworkMember> commMembers = [select MemberId from NetworkMember where NetworkId = :commList[0].Id and Member.Isactive = TRUE];
       
       String groupName = (test.IsRunningTest() ? 'Test GB News' : 'Golfbreaks News');
        
       List<CollaborationGroup> groupList = [select Id, Name from CollaborationGroup 
                                              where Name = :groupName LIMIT 1];
       Id groupId;
       if (!groupList.isEmpty()){
           groupId = groupList[0].Id;
       }else {
           return;
       }
       
       Map<Id, CollaborationGroupMember> allgms = new Map<Id, CollaborationGroupMember>();
       
       for (CollaborationGroupMember cgm : [SELECT Id, MemberId, NotificationFrequency FROM CollaborationGroupMember WHERE CollaborationGroupId = :groupId]){
           allgms.put(cgm.memberId, cgm);
       }
       
       List<CollaborationGroupMember> membersToUpdate = new List<CollaborationGroupMember>();
       List<CollaborationGroupMember> membersToInsert = new List<CollaborationGroupMember>();
       
       for (NetworkMember nm : commMembers){
           CollaborationGroupMember cgm = allgms.get(nm.MemberId);
           if (null == cgm){
               CollaborationGroupMember gm = new CollaborationGroupMember();
               gm.MemberId = nm.memberId;
               gm.NotificationFrequency = 'P';
               gm.CollaborationRole = 'Standard';
               gm.CollaborationGroupId = groupId;
               
               system.debug('*** -- Adding ' + gm + ' -- ***');
               membersToInsert.add(gm);  
                 
           }else {
               if(cgm.NotificationFrequency != 'P'){
                  cgm.NotificationFrequency = 'P';
                  membersToUpdate.add(cgm);
               }
           }
       }
           
       system.debug('*** -- Updating ' + membersToUpdate.size() + ' records -- ***');
       update membersToUpdate;
       system.debug('*** -- inserting ' + membersToUpdate.size() + ' records -- ***');
       insert membersToInsert;
       
    }
    
}