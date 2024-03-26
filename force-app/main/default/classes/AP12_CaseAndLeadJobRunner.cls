/**
   @Author: Recuerdo Bregente
   @name: AP12_CaseAndLeadJobRunner
   @CreateDate: 13.04.2016
   @Description: Scheduled batch for AP11_CaseScoringBatch and AP30_ScheduledLeadAssignmentBatch
   @Version <1.0>
 */ 
global class AP12_CaseAndLeadJobRunner implements Schedulable {
    Integer intervalMinutes;
    DateTime dateToStop;
    DateTime now;
    
    public AP12_CaseAndLeadJobRunner() {
        this.intervalMinutes = 10;
        this.dateToStop = DateTime.now().addDays(1);
    }
    
    public AP12_CaseAndLeadJobRunner(Integer intervalMinutes, DateTime dateToStop) {
        this.intervalMinutes = intervalMinutes;
        this.dateToStop = dateToStop;
    }
    
    public void execute(SchedulableContext sc) {
        if(this.intervalMinutes == null && this.dateToStop == null){
            this.intervalMinutes = 10;
            this.dateToStop = DateTime.now().addDays(1);
        }
        
        // Re-schedule ourself to run again in "intervalMinutes" time
        now  = DateTime.now();
        DateTime nextRunTime = now.addMinutes(intervalMinutes);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
            '9-20' + ' ' + nextRunTime.day() + ' ' + 
            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        
        if(now.hour() < 20){
            System.schedule(AP12_CaseAndLeadJobRunner.class.getName() + '-' + now.format(), cronString, new AP12_CaseAndLeadJobRunner(intervalMinutes, dateToStop));
        }
        
        // Abort the current job
        Id jobId = sc.getTriggerId();
        System.abortJob(jobId);     
            
            // Launch a batch job or call a future method to do the actual work
            //2017-03-10 : SM : Reducing scope size from 200 to 100 as per MC's recommendation - SG-581

            Database.executeBatch(new AP30_ScheduledLeadAssignmentBatch(), 100);
            Database.executeBatch(new AP39_AssignSpecialistSalesBatch(), 100);
    }
}