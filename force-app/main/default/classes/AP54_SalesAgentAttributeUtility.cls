/*
Name:  AP54_SalesAgentAttributeUtility.cls
Copyright © 2016  Golf Breaks Offshore Team
======================================================
======================================================
Purpose:
-------
Utility Class for Sales Agent Attribute
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Merari Cebrian  2016-05-19  Initial development.
1.1  Simon M         2017-08-09  Excluded Opportunity Record Type 'Sales Shadow Opportunity' from all calculations
*/  
public with sharing class AP54_SalesAgentAttributeUtility {
    public static final String CLASS_NAME = 'AP54_SalesAgentAttributeUtility';
    /**
     ** @Author: Merari Cebrian
     ** @Method Name: updateCorrespodingSAAofLeadowners
     ** @Description: updates Current_Number_of_Open_Leads_Opps__c of corresponding SAA records
     **
     **/   
    public static void updateCorrespodingSAAofRecOwners(List<Lead> newLeadList, List<Opportunity> newOppList){
        system.debug('>>>>> updateCorrespodingSAAofLeadowners <<<<<<');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> currentOwnerIdSet = new Set<Id>();        
        Map<Id, List<Opportunity>> oppOwnerMap = new Map<Id, List<Opportunity>>{};
        Map<Id, List<Lead>> leadOwnerMap = new Map<Id, List<Lead>>{};
        Map<Id, Integer> leadOwnerDiarised = new Map<Id, Integer>();
        Map<Id, Integer> oppOwnerDiarised = new Map<Id, Integer>();
        List<Sales_Agent_Attributes__c> leadOwnerSAA = new List<Sales_Agent_Attributes__c>();
        Integer counter = 0;
        Integer diarisedSum = 0;
        try{
            //get lead owners
            if(!newLeadList.isEmpty()) {
                for(Lead leadRec: newLeadList) {
                    ownerIdSet.add(leadRec.OwnerId);
                }
            }
            //get opp owners
            if(!newOppList.isEmpty()) {
                for(Opportunity oppRec: newOppList) {
                    ownerIdSet.add(oppRec.OwnerId);
                }
            }
            system.debug('>>>>> ownerIdSet'+ownerIdSet);
            
                        
            //MC - 2017-02-24 - Error log remediation #SG-339-2. 
            //Maximum 10 ownerIds passed to the Lead and Opportunity queries below to reduce risk of non-selective queries caused by bulk integration tasks.
            // Note, SOQL queries in for loops is a deviation from best practice necessary here to avoid re-designing the code entirely.
            // Scenario : Integration updates 200 Opportunities from CH - this code gathers the record owners and queries the leads and opps to update SAA.
            // It is possible that the number of record owner results in the OwnerId filter not being selective as the volume of records exceeds the threshold.
            // As the remaining filters are non-selective the query fails. The remediation is to break down the ownerIds into groups to reduce the risk.            
            // Worst case = 200 ownerIds and 40 soql queries issued (from 100 limit).
            if (ownerIdSet.isEmpty()) return;
                        
            Id currentChunkId;
            Map<Id,Set<Id>> chunkedOwnerIds = new Map<Id,Set<Id>>();
            final Integer MAX_OWNERID_SIZE_PER_QUERY = 10;
            
            for (Id ownerId : ownerIdSet){
                
                if (currentChunkId==null || chunkedOwnerIds.get(currentChunkId).size()==MAX_OWNERID_SIZE_PER_QUERY){
                    currentChunkId = ownerId;
                    chunkedOwnerIds.put(currentChunkId, new Set<Id>());
                }
                chunkedOwnerIds.get(currentChunkId).add(ownerId);
            }
            
            for (Id chunkId : chunkedOwnerIds.keySet()){
                
                currentOwnerIdSet = chunkedOwnerIds.get(chunkId);           
                if (currentOwnerIdSet.isEmpty()) continue;
                
                //MC - 2017-02-24 - Error log remediation #SG-441. Query moved closer to the point of use to minise lock duration.
                //get SAA of lead owners
                //leadOwnerSAA = [SELECT Id, Sales_Rep__c, Current_Number_of_Open_Leads_Opps__c, Current_Items_Diarised_Today__c FROM Sales_Agent_Attributes__c WHERE Sales_Rep__c IN: currentOwnerIdSet AND (RecordType.Name =: ApplicationConstant.USP_SALES_AGENT OR RecordType.Name =: ApplicationConstant.USP_SALES_MANAGER)];
                
                //get leads of lead owners map<opp.owner, List<List>>
                for(Lead leadtoMap: [SELECT Id, OwnerId, Status, Diarydate__c FROM Lead WHERE (Status =: ApplicationConstant.LEAD_STATUS_NEW OR Status =: ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED) 
                                                                    AND OwnerId IN :currentOwnerIdSet]) {
                    if(leadtoMap.Status == ApplicationConstant.LEAD_STATUS_NEW) {
                        
                        if(leadOwnerMap.containsKey(leadtoMap.OwnerId)) leadOwnerMap.get(leadtoMap.OwnerId).add(leadtoMap);
                        else leadOwnerMap.put(leadtoMap.OwnerId, new List<Lead>{leadtoMap});
                    }
                    
                    if(ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equals(leadtoMap.Status) && leadtoMap.Diarydate__c != null && 
                            ApplicationConstant.setStringToDateFormat(String.valueOf(leadtoMap.Diarydate__c)) <= Date.today()){
                        
                        if(!leadOwnerDiarised.containsKey(leadtoMap.OwnerId)){
                            leadOwnerDiarised.put(leadtoMap.OwnerId, 0);
                        }
                        
                        leadOwnerDiarised.put(leadtoMap.OwnerId, leadOwnerDiarised.get(leadtoMap.OwnerId)+1);
                        
                    }
                }
                system.debug('>>>>> leadOwnerMap'+leadOwnerMap);
                //get opp of lead owners map<opp.owner, List<Opp>>
                //for(Opportunity opptoMap: [SELECT Id, OwnerId FROM Opportunity WHERE StageName =: ApplicationConstant.RECOMMENDATIONSTAGE AND OwnerId IN: currentOwnerIdSet]) {
                    //if(oppOwnerMap.containsKey(opptoMap.OwnerId)) oppOwnerMap.get(opptoMap.OwnerId).add(opptoMap);
                    //else oppOwnerMap.put(opptoMap.OwnerId, new List<Opportunity>{opptoMap});
                //}
                
                for(Opportunity oppToMap: [SELECT Id, OwnerId FROM Opportunity WHERE RecordTypeId = :ApplicationConstant.getRecordTypeId('Opportunity','NewSalesOpportunity') 
                                        AND OwnerId IN :currentOwnerIdSet AND DiaryDate__c <= TODAY AND 
                                        (StageName =: ApplicationConstant.RECOMMENDATIONSTAGE OR StageName =: ApplicationConstant.QUOTESENTSTAGE OR 
                                        StageName =: ApplicationConstant.CLOSESALESTAGE OR StageName =: ApplicationConstant.CUSTOMERACCEPTEDSTAGE)]) {
                    
                    if(!oppOwnerDiarised.containsKey(opptoMap.OwnerId)){
                        oppOwnerDiarised.put(opptoMap.OwnerId, 0);
                    }
                    
                    oppOwnerDiarised.put(opptoMap.OwnerId, oppOwnerDiarised.get(opptoMap.OwnerId) + 1);
                }
                system.debug('>>>>> oppOwnerMap'+oppOwnerMap);
                    
            } // end chunk loop    
                    
            //MC - 2017-02-24 - Error log remediation #SG-441. FOR UPDATE added to reduce lock errors. 
            //get SAA of lead owners
            leadOwnerSAA = [SELECT Id, Sales_Rep__c, Current_Number_of_Open_Leads_Opps__c, Current_Items_Diarised_Today__c 
                                FROM Sales_Agent_Attributes__c 
                                WHERE Sales_Rep__c IN: ownerIdSet AND (RecordType.Name =: ApplicationConstant.USP_SALES_AGENT OR RecordType.Name =: ApplicationConstant.USP_SALES_MANAGER)
                            FOR UPDATE];                
            
            //count
            for(Sales_Agent_Attributes__c saa : leadOwnerSAA){
                counter = 0;
                diarisedSum = 0;
                
                //if(oppOwnerMap.containsKey(saa.Sales_Rep__c)){
                    //counter += oppOwnerMap.get(saa.Sales_Rep__c).size();
                    //system.debug('>>>>> counter'+counter);
                //}
                if(leadOwnerMap.containsKey(saa.Sales_Rep__c)){
                    counter += leadOwnerMap.get(saa.Sales_Rep__c).size();
                    system.debug('>>>>> counter'+counter);
                }
                if(leadOwnerDiarised.containsKey(saa.Sales_Rep__c)){
                    diarisedSum += leadOwnerDiarised.get(saa.Sales_Rep__c);
                }
                if(oppOwnerDiarised.containsKey(saa.Sales_Rep__c)){
                    diarisedSum += oppOwnerDiarised.get(saa.Sales_Rep__c);
                }
                saa.Current_Number_of_Open_Leads_Opps__c = counter;
                saa.Current_Items_Diarised_Today__c = diarisedSum;
                system.debug('>>>>> counter'+counter);
            }
            system.debug('>>>>> leadOwnerSAA'+leadOwnerSAA);
            
        } catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateCorrespodingSAAofRecOwners', CLASS_NAME, null));
        }finally{
            // update SAA
            if(logs.isEmpty() && !leadOwnerSAA.isEmpty()){
                Database.SaveResult[] updatedsalesAgentList = database.update(leadOwnerSAA, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updatedsalesAgentList, 'updateCorrespodingSAAofRecOwners', CLASS_NAME, 'Sales Agent Attribute', 'Update'));
            }
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
}