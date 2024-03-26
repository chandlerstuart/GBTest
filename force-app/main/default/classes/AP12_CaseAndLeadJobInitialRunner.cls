/**
   @Author: Patrick Villarica
   @name: AP12_CaseAndLeadJobInitialRunner
   @CreateDate: 08.06.2016
   @Description: Scheduled batch for AP12_CaseAndLeadJobRunner
   @Version <1.0>
 */ 
global class AP12_CaseAndLeadJobInitialRunner implements Schedulable {
    Integer intervalMinutes;
    DateTime now;
    
    public AP12_CaseAndLeadJobInitialRunner() {
        this.intervalMinutes = 10;
    }
    
    public void execute(SchedulableContext sc) {
        if(this.intervalMinutes == null){
            this.intervalMinutes = 10;
        }
        
        // Re-schedule ourself to run again in "intervalMinutes" time
        now  = DateTime.now();
        DateTime nextRunTime = now.addMinutes(intervalMinutes);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
            nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        
        
        System.schedule(AP12_CaseAndLeadJobRunner.class.getName() + '-' + now.format(), cronString, new AP12_CaseAndLeadJobRunner());
        
        Database.executeBatch(new AP30_ScheduledLeadAssignmentBatch(), 200);
        Database.executeBatch(new AP39_AssignSpecialistSalesBatch(), 200);
        
    }
}