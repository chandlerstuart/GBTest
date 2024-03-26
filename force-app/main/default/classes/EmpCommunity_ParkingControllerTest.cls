/*
Name:  EmpCommunity_ParkingControllerTest.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test class for EmpCommunity_ParkingController
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2016-10-25  Initial development.
*/
@isTest(seeAllData=true)
private class EmpCommunity_ParkingControllerTest {
    
    @isTest
    static void testGetUser() {
        test.startTest();
            User testUser = EmpCommunity_ParkingController.getUser();        
        test.stopTest();
        
        system.assertNotEquals(null, testUser);
    }
    
    @isTest
    static void testGetSpaces(){
        Map<integer, User> userMap = new Map<integer, User>();
        List<User> userList = [select Id from User where IsActive = TRUE LIMIT 5];
        for (integer i = 0 ; i < userList.size() ; i++){
            userMap.put(i,userList[i]);
        }
        
        Map<integer, Car_Detail__c> carMap = new Map<integer, Car_Detail__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Car_Detail__c cd = new Car_Detail__c();
            cd.Owner__c = userMap.get(i).Id;
            cd.Name = 'CD'+i+' CAR';
            cd.Make__c = 'BMW';
            cd.Model__c = 'Model1';
            carMap.put(i,cd);
        }
        
        insert carMap.values();
        
        List<Parking_Space__c> psList = new List<Parking_Space__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Parking_Space__c ps = new Parking_Space__c();
            ps.Name = i.format();
            ps.Owner__c = userMap.get(i).Id;
            ps.Car_Detail__c = carMap.get(i).Id;
            psList.add(ps);   
        }
        
        insert psList;
        
        List<EmpCommunity_ParkingController.ParkingWrapper> parkingList;
        test.startTest();
            parkingList = EmpCommunity_ParkingController.getSpaces();       
        test.stopTest();    
        
        //system.assertEquals(5, parkingList.size());
    }
    
    @isTest
    static void testGetAssignSpace(){
        Map<integer, User> userMap = new Map<integer, User>();
        List<User> userList = [select Id from User where IsActive = TRUE LIMIT 5];
        for (integer i = 0 ; i < userList.size() ; i++){
            userMap.put(i,userList[i]);
        }
        
        Map<integer, Car_Detail__c> carMap = new Map<integer, Car_Detail__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Car_Detail__c cd = new Car_Detail__c();
            cd.Owner__c = userMap.get(i).Id;
            cd.Name = 'CD'+i+' CAR';
            cd.Make__c = 'BMW';
            cd.Model__c = 'Model1';
            carMap.put(i,cd);
        }
        
        insert carMap.values();
        
        List<Parking_Space__c> psList = new List<Parking_Space__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Parking_Space__c ps = new Parking_Space__c();
            ps.Name = i.format();
            ps.Owner__c = userMap.get(i).Id;
            ps.Car_Detail__c = carMap.get(i).Id;
            psList.add(ps);   
        }
        
        insert psList;
        EmpCommunity_ParkingController.ParkingWrapper assignWrapper;
        EmpCommunity_ParkingController.ParkingWrapper newAssignWrapper;
        test.startTest();
        
            assignWrapper = EmpCommunity_ParkingController.getAssignSpace('0');
            newAssignWrapper = EmpCommunity_ParkingController.getAssignSpace('10');
        
        test.stopTest();
        
        system.assertNotEquals(null, assignWrapper);
        system.assertNotEquals(null, newAssignWrapper);
    }
    
    @isTest
    static void testGetUsersForAssignment(){
        List<EmpCommunity_ParkingController.UserWrapper> userWrapperList;
        test.startTest();
            userWrapperList = EmpCommunity_ParkingController.getUsersForAssignment();
        test.stopTest();
        
        system.assertNotEquals(null, userWrapperList);
    }
    
    @isTest
    static void testAssignSpaceToUser(){
        Map<integer, User> userMap = new Map<integer, User>();
        List<User> uList = [select Id from User where IsActive = TRUE LIMIT 5];
        for (integer i = 0 ; i < uList.size() ; i++){
            userMap.put(i,uList[i]);
        }
        
        Map<integer, Car_Detail__c> carMap = new Map<integer, Car_Detail__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Car_Detail__c cd = new Car_Detail__c();
            cd.Owner__c = userMap.get(i).Id;
            cd.Name = 'CD'+i+' CAR';
            cd.Make__c = 'BMW';
            cd.Model__c = 'Model1';
            carMap.put(i,cd);
        }
        
        insert carMap.values();
        
        List<Parking_Space__c> psList = new List<Parking_Space__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Parking_Space__c ps = new Parking_Space__c();
            ps.Name = i.format();
            ps.Owner__c = userMap.get(i).Id;
            ps.Car_Detail__c = carMap.get(i).Id;
            psList.add(ps);   
        }
        
        insert psList;
        List<User> userList = [select Id from User];
        Map<Id, Parking_Space__c> psMap = new Map<Id, Parking_Space__c>();
        for (Parking_Space__c ps : [select Id, Current_User__c, Owner__c, Name from Parking_Space__c]){
            psMap.put(ps.Owner__c, ps);
        }
            
        test.startTest();
            
            Parking_Space__c psChange = psMap.get(userList[0].Id);
            String psChangeName = psChange.Name;
            EmpCommunity_ParkingController.assignSpaceToUser(userList[1].Id, psChange.Name);
            
        test.stopTest();
        
        Parking_Space__c psCheck = [select Current_User__c from Parking_Space__c where Name = :psChangeName];
        
        system.assertEquals(userList[1].Id, psCheck.Current_User__c);
    }
    
}