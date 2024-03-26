/*
Name:  EmpCommunity_ParkingController.cls
Copyright © 2016  Golfbreaks.
======================================================
======================================================
Purpose:
-------
Controller for EmpCommunity_ParkingSpaceMap Lightning Component. 
getSpaces method - Retrieves a list of Parking Space records

======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Simon Molloy      2016-09-27  Class creation.

*/

public with sharing class EmpCommunity_ParkingController {

    @AuraEnabled
    public static User getUser(){
        return [select Id, Name, UserName, UserRole.Name 
                from User where Id = :UserInfo.getUserId() LIMIT 1];
    }

    @AuraEnabled
    public static List<ParkingWrapper> getSpaces(){
        List<ParkingWrapper> wrapperList = new List<ParkingWrapper>();
        
        for (Parking_Space__c s : [select Id, Name, Current_User__r.Name, Owner__r.Name, 
                                    Available__c, Available_From__c, Available_To__c,
                                    Is_Reserved__c, Reserved_By__c, Reserved_By__r.Name,
                                    Reserved_Date__c, Reserved_From__c, Reserved_To__c,
                                    Current_User_Name__c, Visitor__c, Visitor_Name__c, 
                                    Visitor_Car_Registration__c
                                    from Parking_Space__c ORDER BY Name ASC]){
            wrapperList.add(new ParkingWrapper(s));    
        }
        
        return wrapperList;
    }

    @AuraEnabled
    public static ParkingWrapper getAssignSpace(String whichSpace){
        Parking_Space__c spaceRecord;
        ParkingWrapper wrapper;
        List<Parking_Space__c> psList = [select Id, Name, Current_User__r.Name, Owner__r.Name, Current_User__c,
                                            Owner__c, Available__c, Available_From__c, Is_Reserved__c, Reserved_By__c, Reserved_By__r.Name,
                                            Reserved_Date__c, Reserved_From__c, Reserved_To__c, Available_To__c,
                                            Current_User_Name__c, Visitor__c, Visitor_Name__c, 
                                            Visitor_Car_Registration__c 
                                            from Parking_Space__c where Name = :whichSpace LIMIT 1];
                                           
        if (psList.isEmpty()){
            spaceRecord = new Parking_Space__c();
            spaceRecord.Name = whichSpace;
            wrapper = new ParkingWrapper(spaceRecord);    
        }else {
            wrapper = new ParkingWrapper(psList[0]);
        }
        
        return wrapper;
    }
    
    @AuraEnabled
    public static List<UserWrapper> getUsersForAssignment(){
        system.debug('*** -- into getUsersForAssignment -- ***');
        Map<Id, Parking_Space__c> psMap = new Map<Id, Parking_Space__c>();
        
        for (Parking_Space__c ps : [select Id, Owner__r.Name, Owner__c, Current_User__c, Current_User__r.Name from Parking_Space__c]){
            if (!psMap.containsKey(ps.Current_User__c)){
                psMap.put(ps.Current_User__c, ps);
            }
            if (!psMap.containsKey(ps.Owner__c)){
                psMap.put(ps.Owner__c, ps);
            }
        }
        
        
        List<UserWrapper> userWrapperList = new List<UserWrapper>();
        //Get the first page first
        ConnectApi.UserPage userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(),0,100);
        integer nextPageToken = userPage.nextPageToken;

        for (ConnectApi.UserDetail ud : userPage.users){
            if (psMap.get(ud.Id) == null){
                userWrapperList.add(new UserWrapper(ud));
            }
        }

        
        while (nextPageToken != null){
            userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(), nextPageToken, 100);
            for (ConnectApi.UserDetail ud : userPage.users){
                if (psMap.get(ud.Id) == null){
                    userWrapperList.add(new UserWrapper(ud));
                }
            }
            nextPageToken = userPage.nextPageToken;
        }

        system.debug('*** -- about to return ' + userWrapperList.size() + ' user wrappers from getAllUsers -- ***');

        return userWrapperList;
        
    }
    @AuraEnabled
    public static void assignSpaceToUser(Id selectedUserId, String whichSpace){
        system.debug('*** -- assignSpace fired with ' + selectedUserId + ' and ' + whichSpace + ' -- ***');
    
        List<Parking_Space__c> psList = [select Id, Available__c, Current_User__c, Car_Detail__c, Temporary_Use__c from Parking_Space__c where Name = :whichSpace LIMIT 1];
        List<Car_Detail__c> cdList = [select Id from Car_Detail__c where Owner__c = :selectedUserId LIMIT 1];
        
        if (!psList.isEmpty()){
            Parking_Space__c ps = psList[0];
            ps.Current_User__c = selectedUserId;
            if (!cdList.isEmpty()){
                ps.Car_Detail__c = cdList[0].Id;
            }
            ps.Temporary_Use__c = TRUE;
            ps.Available__c = FALSE;
            
            update ps;    
        }
            
    }

    public class ParkingWrapper {
        @AuraEnabled
        public String spaceNumber {get; set;}
        @AuraEnabled
        public String recordURL {get; set;}
        @AuraEnabled
        public String currentUser {get; set;}
        @AuraEnabled
        public String ownerName {get; set;}
        @AuraEnabled
        public boolean isAvailable {get; set;}
        @AuraEnabled
        public Date availableFrom {get; set;}
        @AuraEnabled
        public Date availableTo {get; set;}
        @AuraEnabled
        public Parking_Space__c parkingRecord {get; set;}
        @AuraEnabled
        public String reservedBy {get; set;}
        @AuraEnabled
        public boolean isReserved {get; set;}
        @AuraEnabled
        public Date reserveFrom {get; set;}
        @AuraEnabled
        public Date reserveTo {get; set;}
        @AuraEnabled
        public boolean canBeBooked {get; set;}
        @AuraEnabled
        public String availableDates {get; set;}
        
        public ParkingWrapper(Parking_Space__c space){
            this.canBeBooked = FALSE;
            this.spaceNumber = space.Name;
            this.recordURL = space.Name + '/getRecord';
            //this.currentUser = space.Current_User__r.Name;
            this.currentUser = space.Current_User_Name__c;
            this.isAvailable = space.Available__c;
            this.availableFrom = space.Available_From__c;
            this.availableTo = space.Available_To__c;
            this.reserveFrom = (space.Reserved_From__c == null ? space.Available_From__c : space.Reserved_From__c);
            this.reserveTo = (space.Reserved_To__c == null ? space.Available_To__c : space.Reserved_To__c);
            
            if (null != space.Available_From__c){
                String avFrom = ('0' + space.Available_From__c.day()).right(2);
                avFrom += '/' + ('0' + space.Available_From__c.month()).right(2);
                avFrom += '/' + (space.Available_From__c.year().format()).right(2);
                String avTo = ('0' + space.Available_To__c.day()).right(2);
                avTo += '/' + ('0' + space.Available_To__c.month()).right(2);
                avTo += '/' + (space.Available_To__c.year().format()).right(2);
                this.availableDates = avFrom + ' - ' + avTo;
            }
            
            this.ownerName = space.Owner__r.Name;
            this.parkingRecord = space;
            this.isReserved = space.Is_Reserved__c;
            this.reservedBy = space.Reserved_By__r.Name;
            
            if (availableFrom != null && !isReserved){
                this.canBeBooked = TRUE;
            }
        }
    }
    
    public class UserWrapper {
        @AuraEnabled
        public Id userId {get; set;}
        @AuraEnabled
        public String userName {get; set;}
        @AuraEnabled
        public ConnectApi.UserDetail userRecord {get; set;}
        
        public UserWrapper(ConnectApi.UserDetail u){
            this.userRecord = u;
            this.userId = u.Id;
            this.userName = u.Name;
        }
    }

}