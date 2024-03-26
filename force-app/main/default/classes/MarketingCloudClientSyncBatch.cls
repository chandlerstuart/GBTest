/*
Name:  MarketingCloudClientSyncBatch.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Aligns the flags below to the Account.

Account.IsMarketingCloudClientSync__c (Account SyncDe <-- can't reference Contact fields for PersonAccount)
Contact.IsMarketingCloudContactSync__c (Contact SyncDe <-- can't reference Account fields for PersonAccount)

Run modes: 
-- All 
-- Records modified in the last x hours.
-- Records modified since y date.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-07-13  Initial development.
1.1  J. Radcliffe  2023-07-17  Scope change. Include accounts with changes to the parent (primary) Individual record.
1.2  J. Radcliffe  2023-07-18  Scope change. Only query records where the sync checkboxes and formulas are misaligned.
*/
public with sharing class MarketingCloudClientSyncBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Integer fromHours;
    private Date fromDate;
    @testVisible Integer processedRecCount=0;
    @testVisible Integer updatedRecCount=0;

    public MarketingCloudClientSyncBatch(){ }

    public MarketingCloudClientSyncBatch(Integer fromHours){ this.fromHours = fromHours; }

    public MarketingCloudClientSyncBatch(Date fromDate){ this.fromDate = fromDate; }


    // Batchable - start.
  
    public Database.QueryLocator start(Database.BatchableContext context){
      
        String q='select Id, IsMarketingCloudClient__c, IsMarketingCloudClientSync__c, IsMarketingCloudContactSync__pc';
        q+=' from Account';
        q+=' where IsPersonAccount=true';
        q+=' and ((IsMarketingCloudClient__c = true and IsMarketingCloudClientSync__c = false) or (IsMarketingCloudContact__pc = true and IsMarketingCloudContactSync__pc = false) or (IsMarketingCloudClient__c = false and IsMarketingCloudClientSync__c = true) or (IsMarketingCloudContact__pc = false and IsMarketingCloudContactSync__pc = true))';//1.2+

        Datetime dt;
        if (fromHours!=null && fromHours>0){

            dt = Datetime.now();
            dt = dt.addHours(-fromHours);

        } else if (fromDate!=null && fromDate<=Date.today()){

            dt = Datetime.newInstance(fromDate.year(),fromDate.month(),fromDate.day());

        }
        if (dt!=null) q+=' and (LastModifiedDate>=:dt or PersonIndividual.LastModifiedDate>=:dt) ';//1.1~ 

        return Database.getQueryLocator(q);
    }
  
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try {

            processedRecCount+=scope.size();            

            Map<Id,Account> idToAccountToUpdate = new Map<Id,Account>();
            for (Account a : (List<Account>)scope){

                if ( (Boolean)a.get('IsMarketingCloudClient__c')!=(Boolean)a.get('IsMarketingCloudClientSync__c') ){
                    a.put('IsMarketingCloudClientSync__c',(Boolean)a.get('IsMarketingCloudClient__c'));
                    idToAccountToUpdate.put(a.Id,a);
                }

                if ( (Boolean)a.get('IsMarketingCloudClient__c')!=(Boolean)a.get('IsMarketingCloudContactSync__pc') ){
                    a.put('IsMarketingCloudContactSync__pc',(Boolean)a.get('IsMarketingCloudClient__c'));
                    idToAccountToUpdate.put(a.Id,a);
                }
            }

            if (!idToAccountToUpdate.isEmpty()){

                updatedRecCount+=idToAccountToUpdate.size();

                Database.SaveResult[] results = Database.update(idToAccountToUpdate.values(),false);
                Golfbreaks.PlatformLogManager.logExceptions(results,'MarketingCloudClientSyncBatch','batchable.execute',idToAccountToUpdate.values());
            }

        } catch(Exception e){ Golfbreaks.PlatformLogManager.logExceptions(e,'MarketingCloudClientSyncBatch','batchable.execute'); }
    }
  
    public void finish(Database.BatchableContext bc){

        String summaryText='Parameters: fromHours:'+(fromHours==null ? 'NA' : fromHours.format())+'\n';
        summaryText+='fromDate:'+(fromDate==null ? 'NA' : fromDate.format())+'\n';

        String detailText='Statistics: Processed records:'+processedRecCount+'\n';
        detailText+='Updated records: '+updatedRecCount;

        Golfbreaks.PlatformLogManager.logCustomMessage(summaryText,detailText,'MarketingCloudClientSyncBatch','batchable.execute',null);
    }

    // Batchable - end.
}