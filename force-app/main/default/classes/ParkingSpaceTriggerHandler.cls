/*
Name:  ParkingSpaceTriggerHandler.cls
Copyright © 2016  GolfBreaks
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the Parking Space object
======================================================
======================================================
History
------- 
Ver. Author                Date                 Detail
1.0  Simon Molloy         2016-10-10    Initial development.

*/
public class ParkingSpaceTriggerHandler 
{
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;
    private OrgSettings__c orgSettings;

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;

    public ParkingSpaceTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
        orgSettings = OrgSettings__c.getInstance();
    }
            
    //& trigger action methods.    
    public void onBeforeInsert(Parking_Space__c[] insertedRecords){ 
        populateCurrentUser(insertedRecords, null);
    }
    
    public void onAfterInsert(Parking_Space__c[] insertedRecords, Map<Id, Parking_Space__c> newMap){
        
    }
    
    public void onBeforeUpdate(Parking_Space__c[] updatedRecords, Map<Id, Parking_Space__c> newMap, Map<Id, Parking_Space__c> oldMap){
        if (firstBeforeUpdateRun){
            firstBeforeUpdateRun = false; // prevent recursive updates within applied logic. 
            populateCurrentUser(updatedRecords,oldMap);
            //populateCarDetails(updatedRecords, oldMap);
        }
    }
    
    /*
    //TODO: This needs to be uncommented when the code is ready
    public void onAfterUpdate(Parking_Space__c[] updatedRecords, Map<Id, Parking_Space__c> newMap, Map<Id, Parking_Space__c> oldMap){
        if (firstAfterUpdateRun){

        }        
    }
    */
    //public void onBeforeDelete(List<Parking_Space__c> deletedRecords, Map<Id, Parking_Space__c> oldMap){}
    //public void onAfterDelete(List<Parking_Space__c> deletedRecords, Map<Id, Parking_Space__c> oldMap){}
    //public void onAfterUndelete(List<Parking_Space__c> undeletedRecords, Map<Id, Parking_Space__c> newMap){}
    
    //& helper methods.
    
    

    /*
    populateCurrentUser
    ------------------------
    Purpose: Updates Current User details to be the same as the Owner, if Current User is null
    Input: List of Parking Space records (NEW) and Map of Parking Space records (OLD)
    Output: none
    */
    private void populateCurrentUser(List<Parking_Space__c> newRecords, Map<Id, Parking_Space__c> oldMap){
        Set<Id> userIdSet = new Set<Id>();
        Map<Id, Car_Detail__c> carDetailMap = new Map<Id, Car_Detail__c>();
        
        if (null == oldMap){
            //Its an insert
            for (Parking_Space__c ps : newRecords){
                if (ps.Current_User__c == null && !ps.Available__c && !ps.Visitor__c){
                    ps.Current_User__c = ps.Owner__c;
                    userIdSet.add(ps.Current_User__c);
                }
            }
            for (Car_Detail__c cd : [select Id, Name, Owner__c from Car_Detail__c where Owner__c in :userIdSet]){
                carDetailMap.put(cd.Owner__c, cd);
            }
            
            for (Parking_Space__c ps : newRecords){
                if (null != ps.Current_User__c){
                    if (carDetailMap.get(ps.Current_User__c) != null){
                        ps.Car_Detail__c = carDetailMap.get(ps.Current_User__c).Id;
                    }
                }
            }
            
        }else {
            
            for (Parking_Space__c ps : newRecords){
                Parking_Space__c oldPS = oldMap.get(ps.Id);
                if (ps.Current_User__c == null && !ps.Available__c && !ps.Visitor__c){
                    ps.Current_User__c = ps.Owner__c;
                    userIdSet.add(ps.Current_User__c);
                    
                }else if (ps.Current_User__c != null && ps.Visitor__c){
                    ps.Current_User__c = null;
                    ps.Car_Detail__c = null;
                
                }else if (ps.Current_User__c != null && ps.Current_User__c != oldPS.Current_User__c){
                    userIdSet.add(ps.Current_User__c);
                }
            }
            
            for (Car_Detail__c cd : [select Id, Name, Owner__c from Car_Detail__c where Owner__c in :userIdSet]){
                carDetailMap.put(cd.Owner__c, cd);
            }
            
            for (Parking_Space__c ps : newRecords){
                if (null != ps.Current_User__c){
                    if (carDetailMap.get(ps.Current_User__c) != null){
                        ps.Car_Detail__c = carDetailMap.get(ps.Current_User__c).Id;
                    }
                }
            }
            
        }
        
    }
    
  //& End helper methods.
}