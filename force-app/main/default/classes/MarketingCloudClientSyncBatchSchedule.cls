/*
Name:  MarketingCloudClientSyncBatchSchedule.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Enables scheduling for the batch class MarketingCloudClientSyncBatch.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-07-13  Initial development.
*/
public with sharing class MarketingCloudClientSyncBatchSchedule implements Schedulable {
    
    private Integer fromHours;

    public MarketingCloudClientSyncBatchSchedule(){ }
    
    public MarketingCloudClientSyncBatchSchedule(Integer fromHours){ this.fromHours = fromHours; }//<--- EA scheduling with rolling offset parameter i.e. daily+last 24 hours.
    
    public void execute(SchedulableContext sc) {

        if (fromHours==null || fromHours==0){
            Database.executeBatch(new MarketingCloudClientSyncBatch());
        } else Database.executeBatch(new MarketingCloudClientSyncBatch(fromHours));        
    }
}