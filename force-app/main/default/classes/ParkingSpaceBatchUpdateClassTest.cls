/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 10/10/2016
@description - Test class for ParkingSpaceBatchUpdateClass
***************************************************************/
@isTest
private class ParkingSpaceBatchUpdateClassTest {
    @testSetup
    public static void setup() {
      List<User> userList = [select Id, Name from User where IsActive = TRUE LIMIT 3];
    
      List<Parking_Space__c> psList = new List<Parking_Space__c>();
      
      List<Car_Detail__c> cdList = new List<Car_Detail__c>();

      for (integer i = 0 ; i < userList.size() ; i++){      
          User u = userList[i];
          Car_Detail__c cd = new Car_Detail__c();
          cd.Owner__c = u.Id;
          cd.Make__c = 'BMW';
          cd.Model__c = 'BMW Car';
          cd.Name = 'BM0' + i + 'CAR';
          cdList.add(cd);
      }

      insert cdList;

      for (integer i = 0 ; i < userList.size() ; i++){
          User u = userList[i];
          Parking_Space__c ps = new Parking_Space__c();
          ps.Name = i.format();
          ps.Owner__c = u.Id;
          psList.add(ps);    
      }
      
      insert psList;
      
      List<EmployeeLeaveYear__c> leaveYearList = new List<EmployeeLeaveYear__c>();

      for (integer i = 0 ; i < userList.size() ; i++){
          EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c();
          leaveYear.Employee__c = userList[i].Id;
          leaveYear.StandardDays__c = 20;
          leaveYear.Name = userList[i].Name + (Date.today().year().format()).replace(',','');    
          leaveYearList.add(leaveYear);
      }

      insert leaveYearList;

    }

    static testMethod void testBatchRun() {

        ParkingSpaceBatchUpdateClass psbuc = new ParkingSpaceBatchUpdateClass();
        User updateUser;
        
        List<Parking_Space__c> psList = [select Id, Available_From__c, Available_To__c, Owner__c from Parking_Space__c LIMIT 1];
        
        psList[0].Available_From__c = Date.today().addDays(-8);
        psList[0].Available_To__c = Date.today().addDays(-1);

        updateUser = [select Id from User where Id = :pslist[0].Owner__c LIMIT 1];
        List<EmployeeLeaveYear__c> empLeaveYearList = [select Id from EmployeeLeaveYear__c where Employee__c = :updateUser.Id LIMIT 1];

        Leave__c leave = new Leave__c();
        leave.StartDate__c = Date.today();
        leave.EndDate__c = Date.today().addDays(14);
        leave.Employee__c = updateUser.Id;
        leave.Status__c = 'Approved';
        leave.HR_Comments__c = 'Approved';
        leave.EmployeeLeaveYear__c = empLeaveYearList[0].Id;
      
        insert leave;

        update psList;
        
        test.startTest();
        
        Database.executeBatch(psbuc,100);
        
        test.stopTest();     
        
        List<Parking_Space__c> checkList = [select Id, Available_From__c, Available_To__c, Owner__c,
                                            Available__c from Parking_Space__c];
                                            
        List<Leave__c> leaveList = [select Id, Employee__c from Leave__c LIMIT 1];
        
        for (Parking_Space__c ps : checkList){
            if (ps.Owner__c == leaveList[0].Employee__c){
                system.assertNotEquals(null, ps.Available_From__c);
                system.assertNotEquals(null, ps.Available_To__c); 
                system.assertEquals(true, ps.Available__c);               
            }else {
                system.assertEquals(null, ps.Available_From__c);
                system.assertEquals(null, ps.Available_From__c);                                
            }
        }

    }

    static testMethod void testBatchRunReserved() {

        ParkingSpaceBatchUpdateClass psbuc = new ParkingSpaceBatchUpdateClass();
        User updateUser, reservedUser;
        
        List<Parking_Space__c> psList = [select Id, Available_From__c, Available_To__c, Owner__c,
                                        Reserved_Date__c, Reserved_From__c, Reserved_To__c, Reserved_By__c, 
                                        Is_Reserved__c from Parking_Space__c LIMIT 2];

        updateUser = [select Id from User where Id = :pslist[0].Owner__c LIMIT 1];
        reservedUser = [select Id from User where Id != :psList[0].Owner__c and IsActive = TRUE LIMIT 1];

        system.assertNotEquals(updateUser.Id, reservedUser.Id);

        List<EmployeeLeaveYear__c> empLeaveYearList = [select Id from EmployeeLeaveYear__c where Employee__c = :updateUser.Id LIMIT 1];

        Leave__c leave = new Leave__c();
        leave.StartDate__c = Date.today();
        leave.EndDate__c = Date.today().addDays(14);
        leave.Employee__c = updateUser.Id;
        leave.Status__c = 'Waiting for approval';
        leave.HR_Comments__c = 'Holiday';
        leave.EmployeeLeaveYear__c = empLeaveYearList[0].Id;
      
        insert leave;

        leave.Status__c = 'Approved';
        leave.HR_Comments__c = 'Approved';
        update leave;

        psList[0].Is_Reserved__c = TRUE;
        psList[0].Reserved_Date__c = Date.today();
        psList[0].Reserved_From__c = Date.today();
        psList[0].Reserved_To__c = Date.today().addDays(7);
        psList[0].Reserved_By__c = reservedUser.Id;

        psList[1].Is_Reserved__c = TRUE;
        psList[1].Reserved_Date__c = Date.today().addDays(-7);
        psList[1].Reserved_From__c = Date.today().addDays(-7);
        psList[1].Reserved_To__c = Date.today().addDays(-5);
        psList[1].Reserved_By__c = reservedUser.Id;        


        update psList;
        
        test.startTest();
        
        Database.executeBatch(psbuc,100);
        
        test.stopTest();     
        
        List<Parking_Space__c> checkList = [select Id, Available_From__c, Available_To__c, Owner__c,
                                            Available__c, Current_User__c, Temporary_Use__c from Parking_Space__c];
                                            
        List<Leave__c> leaveList = [select Id, Employee__c from Leave__c LIMIT 1];
        
        for (Parking_Space__c ps : checkList){
            if (ps.Owner__c == leaveList[0].Employee__c){
                system.assertEquals(null, ps.Available_From__c);
                system.assertEquals(null, ps.Available_To__c); 
                system.assertEquals(false, ps.Available__c);   
                system.assertEquals(reservedUser.Id, ps.Current_User__c);            
                system.assertEquals(true, ps.Temporary_Use__c);   

            }
        }

    }

}