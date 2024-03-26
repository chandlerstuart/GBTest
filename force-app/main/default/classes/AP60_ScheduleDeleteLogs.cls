/**
   @Author: Recuerdo Bregente
   @name: AP60_ScheduleDeleteLogs
   @CreateDate: 05.07.2016
   @Description: Scheduled batch for deleting old logs
   @Modification: 2017-01-23 : Simon M : Added in re-scheduling code for mass deletion of logs
   @Version <2.0>
 */ 

global with sharing class AP60_ScheduleDeleteLogs implements Schedulable{

	public AP60_ScheduleDeleteLogs() {}
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AP59_DeleteErrorLog(), 2000); 
    }
}