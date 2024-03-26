/**************************************************************
@author - James Radcliffe (Golfbreaks)
@date - 11/10/2016
@description - Test class for EmpCommunity_GBNewsGroupUpdate
***************************************************************/
@isTest
private class EmpCommunity_GBNewsGroupUpdateTest {
    
    @testSetup
    public static void setup() {
        Network comm = [select Id from Network where Name = :EmpCommunity_GBNewsGroupUpdate.EMP_COMMUNITY_NAME LIMIT 1];
        CollaborationGroup cg = new CollaborationGroup(Name = 'Test GB News');
        cg.CollaborationType = 'public';
        cg.NetworkId = comm.Id;
        insert cg;
    }
    
    static testMethod void testSchedule(){
        Date runDate = Date.today().addDays(1);
        String sDay = runDate.day().format();
        String sMonth = runDate.month().format();
        String sYear = (runDate.year().format()).replace(',','');
        String CRON_EXP = '0 0 0 ' + sDay + ' ' + sMonth + ' ? ' + sYear;
        
        String jobId = System.schedule('testGroupUpdateSchedule',CRON_EXP,new EmpCommunity_GBNewsGroupUpdate());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        String checkDate = sYear + '-' + ('0' + sMonth).right(2) + '-' + ('0' + sDay).right(2);
        System.assertEquals(checkDate + ' 00:00:00', String.valueOf(ct.NextFireTime));
    }

    static testMethod void runInsertTest() {
        //Assert records before and after method has run
        Network theCommunity = [select Id from Network where Name = :EmpCommunity_GBNewsGroupUpdate.EMP_COMMUNITY_NAME LIMIT 1];
        CollaborationGroup cg = [select Id, Name from CollaborationGroup where Name = 'Test GB News' LIMIT 1];
        
        List<CollaborationGroupMember> currentGroupList = [select Id from CollaborationGroupMember where
                                                            CollaborationGroupId = :cg.Id];
                                                            
        List<NetworkMember> currentMemberList = [select MemberId from NetworkMember where NetworkId = :theCommunity.Id and Member.IsActive = TRUE];
        
        system.assertEquals(1, currentGroupList.size());
        system.assertNotEquals(currentMemberList.size(), currentGroupList.size());
        
        test.startTest();    
            EmpCommunity_GBNewsGroupUpdate.updateGroupMembers();
        test.stopTest();
        
        List<CollaborationGroupMember> newGroupList = [select Id from CollaborationGroupMember where
                                                            CollaborationGroupId = :cg.Id];
        
        
        system.assertNotEquals(0, newGroupList.size());
        system.assertEquals(currentMemberList.size(), newGroupList.size());
        
        
    }
    
    static testMethod void runUpdateTest() {
        //Assert records before and after method has run
        Network theCommunity = [select Id from Network where Name = :EmpCommunity_GBNewsGroupUpdate.EMP_COMMUNITY_NAME LIMIT 1];
        CollaborationGroup cg = [select Id, Name from CollaborationGroup where Name = 'Test GB News' LIMIT 1];
        
        Map<Id, CollaborationGroupMember> cgmMap = new Map<Id, CollaborationGroupMember>();
        for (CollaborationGroupMember cgm : [select MemberId from CollaborationGroupMember where
                                                            CollaborationGroupId = :cg.Id]){
                                                            
            cgmMap.put(cgm.MemberId, cgm);                                                    
        }
        
        List<CollaborationGroupMember> newGroupList = new List<CollaborationGroupMember>();
        Set<Id> memberIdSet = new Set<Id>();

        for (NetworkMember nm : [select MemberId from NetworkMember where NetworkId = :theCommunity.Id and Member.Isactive = TRUE]){
            if (cgmMap.get(nm.MemberId) == null){
                CollaborationGroupMember cgm = new CollaborationGroupMember();
                cgm.MemberId = nm.MemberId;
                cgm.NotificationFrequency = 'N';
                cgm.CollaborationRole = 'Standard';
                cgm.CollaborationGroupId = cg.Id;
                newGroupList.add(cgm);
                memberIdSet.add(nm.MemberId);
            }
        }
        
        insert newGroupList;
          
        test.startTest();
            EmpCommunity_GBNewsGroupUpdate.updateGroupMembers();
        test.stopTest();
        
        newGroupList = [select Id, NotificationFrequency from CollaborationGroupMember where
                                                            MemberId in :memberIdSet];
                                                            
        for (CollaborationGroupMember cgm : newGroupList){
            system.assertEquals('P', cgm.NotificationFrequency);
        }
        
    }
    
}