/*
Name:  ParkingSpaceBatchUpdateClass.cls
======================================================
======================================================
Purpose:
-------
Batch class to update Parking Spaces avalability due to annual leave etc.
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2016-10-10   Initial development
1.1  Simon Molloy  2017-11-06   Added processing for AM & PM setting on Parking Space
*/
global class ParkingSpaceBatchUpdateClass implements Database.Batchable<sObject> {
    global static String CLASS_NAME = 'ParkingSpaceBatchUpdateClass';
    global String query {get; set;}
    
    global ParkingSpaceBatchUpdateClass(){
        //query = 'select Id, Phone, PersonHomePhone, PersonMobilePhone from Account where (Phone != null OR PersonMobilePhone != null OR PersonHomePhone != null)';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        if (null == query){
            query = 'Select Id, Name, Owner__c, Current_User__c, Available__c, Available_From__c, Available_To__c, ';
            query += 'Temporary_Use__c, Car_Detail__c, Reserved_From__c, Reserved_To__c, Reserved_Date__c, ';
            query += 'Reserved_By__c, Is_Reserved__c, Visitor_Reserved__c, Visitor__c, AM__c, PM__c ';
            query += ' from Parking_Space__c';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Parking_Space__c> scope){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        system.debug('*** -- Processing ' + scope.size() + ' -- ***');

        Set<Id> psOwnerIdSet = new Set<Id>();
        Map<Id, Leave__c> leaveMap = new Map<Id, Leave__c>();

        for (Parking_Space__c ps : scope){
            psOwnerIdSet.add(ps.Owner__c);
        }

        Map<Id, User> userMap = new Map<Id, User>([select Id, (select Id, StartDate__c, EndDate__c, Status__c, 
                                    AM__c, PMStart__c from Leave_Requests__r where 
                                    StartDate__c >= TODAY AND Status__c = 'Approved' ORDER BY StartDate__c ASC)
                                    from User where Id in :psOwnerIdSet]);

        for (Parking_Space__c ps : scope){
             
            if (ps.Available_From__c != null && ps.Available_To__c < Date.today()){
                ps.Available__c = false;
                ps.Available_From__c = null;
                ps.Available_To__c = null;
                ps.AM__c = false;
                ps.PM__c = false;
                ps.Temporary_Use__c = false;
                ps.Current_User__c = null;
                ps.Car_Detail__c = null;
            }

            if (null != ps.Reserved_From__c && ps.Reserved_To__c < Date.today()){
                ps.Available__c = false;
                ps.Available_From__c = null;
                ps.Available_To__c = null;
                ps.AM__c = false;
                ps.PM__c = false;
                ps.Reserved_From__c = null;
                ps.Reserved_To__c = null;
                ps.Is_Reserved__c = false;
                ps.Reserved_Date__c = null;
                ps.Temporary_Use__c = false;
                ps.Current_User__c = null;
                ps.Car_Detail__c = null;
            }

            User u = userMap.get(ps.Owner__c);
            List<Leave__c> leaveListByUser;
            if (null != u){
                leaveListByUser = userMap.get(ps.Owner__c).Leave_Requests__r;
            }
            if (null != leaveListByUser && !leaveListByUser.isEmpty()){
                Leave__c leaveRecord = leaveListByUser[0];
                if (leaveRecord.StartDate__c == Date.today()){
                    if (ps.Is_Reserved__c){
                        ps.Current_User__c = ps.Reserved_By__c;
                        ps.Temporary_Use__c = true;
                        ps.Is_Reserved__c = false;
                        ps.Reserved_By__c = null;
                    }else if (ps.Visitor_Reserved__c) {
                        ps.Visitor__c = true;
                        ps.Visitor_Reserved__c = false;
                    }else {
                        ps.Available__c = true;
                        ps.Available_From__c = leaveRecord.StartDate__c;
                        ps.Available_To__c = leaveRecord.EndDate__c;
                        ps.AM__c = leaveRecord.AM__c;
                        ps.PM__c = leaveRecord.PMStart__c;
                    }    
                }else {
                    ps.Available_From__c = leaveRecord.StartDate__c;
                    ps.Available_To__c = leaveRecord.EndDate__c;
                    ps.AM__c = leaveRecord.AM__c;
                    ps.PM__c = leaveRecord.PMStart__c;
                }

                if (ps.Available__c && ps.Available_From__c > Date.today()){
                    ps.Available__c = false;
                }
                
            }
            
        }
         
        system.debug('*** -- Update scope -- ***');   
        logs.addAll(getResultLogs(Database.update(scope, false), 'Parking_Space__c', 'Update'));

        if (!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //EMPTY
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String objName, String dmlOp)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, objName, dmlOp));
        return errorLogs;
    }

}