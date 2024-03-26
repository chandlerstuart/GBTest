/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 10/10/2016
@description - Test class for ParkingSpaceTriggerHandler
***************************************************************/
@isTest
private class ParkingSpaceTriggerHandlerTest {
    @testSetup
    public static void setup() {
         OrgSettings__c orgSettings = new OrgSettings__c();
         orgSettings.TriggersActive__c = true;
         insert orgSettings;
         
        List<User> userList = [select Id, Name from User where IsActive = TRUE LIMIT 3];
    
        List<Car_Detail__c> carDetailList = new List<Car_Detail__c>();
        Car_Detail__c cd1 = new Car_Detail__c();
        cd1.Owner__c = userList[0].Id;
        cd1.Name = 'CD01 AAA';
        cd1.Make__c = 'BMW';
        carDetailList.add(cd1); 
        
        Car_Detail__c cd2 = new Car_Detail__c();
        cd2.Owner__c = userList[1].Id;
        cd2.Name = 'CD02 BBB';
        cd2.Make__c = 'BMW';
        carDetailList.add(cd2); 

        Car_Detail__c cd3 = new Car_Detail__c();
        cd3.Owner__c = userList[2].Id;
        cd3.Name = 'CD03 CCC';
        cd3.Make__c = 'BMW';
        carDetailList.add(cd3); 

        insert carDetailList;
    }
    


    static testMethod void testTriggerInsert() {
        
        List<User> userList = [select Id, Name from User where IsActive = TRUE LIMIT 3];
        
        List<Parking_Space__c> psList = new List<Parking_Space__c>();
            
        for (integer i = 0 ; i < userList.size() ; i++){
            User u = userList[i];
            Parking_Space__c ps = new Parking_Space__c();
            ps.Name = i.format();
            ps.Owner__c = u.Id;
            psList.add(ps);    
        } 
         
        test.startTest(); 
            insert psList;
        test.stopTest();
        
        List<Parking_Space__c> checkList = [select Id, Owner__c, Current_User__c from Parking_Space__c];
        system.assertEquals(3, checkList.size());
        for (Parking_Space__c ps : checkList){
            system.assertEquals(ps.Current_User__c, ps.Owner__c);
        }
            
        
    }
    
    static testMethod void testTriggerUpdate(){
    
        List<User> userList = [select Id, Name from User where IsActive = TRUE LIMIT 3];
        
        List<Parking_Space__c> psList = new List<Parking_Space__c>();
            
        for (integer i = 0 ; i < userList.size() ; i++){
            User u = userList[i];
            Parking_Space__c ps = new Parking_Space__c();
            ps.Name = i.format();
            ps.Owner__c = u.Id;
            psList.add(ps);    
        } 
        
        insert psList;
        
        Map<Id, Car_Detail__c> carDetailMap = new Map<Id, Car_Detail__c>();
        
        for (Car_Detail__c cd : [select Id, Owner__c from Car_Detail__c]){
            carDetailMap.put(cd.Owner__c, cd);    
        }
        
        for (integer i = 0 ; i < psList.size() ; i++){
            Parking_Space__c ps = psList[i];
            if (0 == i){
                ps.Current_User__c = userList[1].Id;
                ps.Car_Detail__c = null;
            }
            if (1 == i){
                ps.Current_User__c = userList[0].Id;
                ps.Car_Detail__c = null;
            }
            if (2 == i){
                ps.Current_User__c = null;
                ps.Car_Detail__c = null;
            }
        }
        
        test.startTest();
            update psList;
        test.stopTest();
        
        List<Parking_Space__c> checkList = [select Id, Owner__c, Current_User__c, Car_Detail__c from Parking_Space__c];
        system.assertEquals(3, checkList.size());
        for (Parking_Space__c ps : checkList){
            system.assertEquals(ps.Car_Detail__c, carDetailMap.get(ps.Current_User__c).Id);
        }
           
    
    }

}