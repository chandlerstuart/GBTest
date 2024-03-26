/**
   @Author: Renz Melecotones
   @name: AP16_ExpectedPaymentTriggerBL
   @CreateDate: 04.04.2016
   @Description: Business Logic Class for AP15_ExpectedPaymentTriggerHandler
   @Version <1.0>

History
------- 
Ver. Author        Date         Detail
2.0  J Radcliffe   2021-07-26   Increase trigger selectivity (only update Opps Stage if the Opp Stage is innacurate) + error logging
2.1  J Radcliffe   2022-04-14   Bug fix. Opp Stage Calc. Process the first 0 outstanding balance EP for a Booking Only
*/
public with sharing class AP16_ExpectedPaymentTriggerBL{

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP16_ExpectedPaymentTriggerBL';
            
    /**
       *  This method is used to update the stages on the Opportunity based on Expected Payment Type
       *  @name: updateOpportunityStage
       *  @developer: Abram Vixen Reyes 01.04.2016
       *  @param: caseList - get Trigger.new from CaseTrigger; of List<Case> data type
    **/
    public static void updateOpportunityStage(List<Expected_Payment__c> expectedPaymentList){
        //List<Error_Log__c> logs = new List<Error_Log__c>(); 2.0-
    
        Set<Id> ePayBook = new Set<Id>();
        Map<Id, Booking__c> bookforOpp = new Map<Id, Booking__c>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppsForUpdate = new Map<Id,Opportunity>();//2.0+
        
        try{
            for(Expected_Payment__c epayment : expectedPaymentList){
                ePayBook.add(epayment.Booking__c);
            }

            system.debug('FIND ME > ePayBook > '+ePayBook);
            
            if(!epaybook.isEmpty()){
            	//MC - 2017-02-24 - Error log remediation #SG-445-0. FOR UPDATE added to reduce lock errors.
                bookforOpp = new Map<Id, Booking__c>([SELECT Id, TECH_Opportunity__c, TECH_Opportunity__r.Id, TECH_Opportunity__r.StageName 
                										FROM Booking__c 
                										WHERE Id IN:ePayBook AND TECH_Opportunity__c <> null
                										FOR UPDATE]);
            }
            
            system.debug('FIND ME > bookforOpp > '+bookforOpp);
            
            //2.0 - Previously the Opp was always updated, regardless of changes. 
            //Now the opp is only added to a the (new) oppsForUpdate map if it requires an update

            if(bookforOpp.values().size() > 0){
                for(Booking__c book : bookforOpp.values()){
                    oppMap.put(book.TECH_Opportunity__r.Id, book.TECH_Opportunity__r);
                }

                system.debug('FIND ME > oppMap > '+oppMap);
                
                //2.0+ The problem with evaluating the EPs (if sorting by ExpectedPaymentType ASC) is that you are more likely to update the Opportunity 
                //e.g. you evaluate the first and realise the stage is not correct, so you add to the list. You then evaluate the second and realise that the stage was correct, but you've just changed it (in the map), so you change it back. 
                //Suddenly you are performing a DML operation and starting a chain of events for no reason. These should be evaluated in DESC order and only if the Opp Stage does not match the latest stage should it be updated
                
                //2.1+
                Set<Id> processedBookingIds = new Set<Id>();

                for(Expected_Payment__c epayment : [SELECT Id, Booking__c, ExpectedPaymentType__c FROM Expected_Payment__c WHERE Booking__c IN: bookforOpp.keySet() AND Outstanding_Balance__c = 0.00 ORDER BY ExpectedPaymentType__c DESC]){//2.0~ (Changed to DESC)
                    system.debug('FIND ME > epayment > '+epayment);          
                    system.debug('FIND ME > bookforOpp.containsKey(epayment.Booking__c) > '+bookforOpp.containsKey(epayment.Booking__c));                              
                    if(bookforOpp.containsKey(epayment.Booking__c) && !processedBookingIds.contains(epayment.Booking__c)){//2.1~ check processedBookingIds
                        system.debug('FIND ME > oppMap.containsKey(bookforOpp.get(epayment.Booking__c).TECH_Opportunity__r.Id) > '+oppMap.containsKey(bookforOpp.get(epayment.Booking__c).TECH_Opportunity__r.Id));                    
                        if(oppMap.containsKey(bookforOpp.get(epayment.Booking__c).TECH_Opportunity__r.Id)){
                            Opportunity oppUp = oppMap.get(bookforOpp.get(epayment.Booking__c).TECH_Opportunity__r.Id);
                            system.debug('FIND ME > oppsForUpdate.containsKey(oppUp.Id) > '+oppsForUpdate.containsKey(oppUp.Id));                    
                            if(oppsForUpdate.containsKey(oppUp.Id)) continue;//2.0+ - Don't overwrite previous update
                            system.debug('FIND ME > oppUp.StageName > '+oppUp.StageName);
                            if(oppUp.StageName != ApplicationConstant.OPP_STAGE_TRIPCOMPLETED && oppUp.StageName != ApplicationConstant.BOOKING_STATUS_CANCELLED){
                                if(epayment.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT){
                                    if(oppUp.StageName <> ApplicationConstant.PAIDPARTIALDEPOSITSTAGE){
                                        oppUp.StageName = ApplicationConstant.PAIDPARTIALDEPOSITSTAGE;
                                        system.debug('FIND ME > adding for update > '+oppUp.StageName);
                                        oppsForUpdate.put(oppUp.Id,oppUp);//2.0+
                                        //oppMap.put(oppUp.Id, oppUp);//2.0-
                                    }
                                    processedBookingIds.add(epayment.Booking__c);//2.1+
                                    continue;
                                } else if(epayment.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT){
                                    if(oppUp.StageName <> ApplicationConstant.PAIDFULLDEPOSITSTAGE){
                                        oppUp.StageName = ApplicationConstant.PAIDFULLDEPOSITSTAGE;
                                        system.debug('FIND ME > adding for update > '+oppUp.StageName);
                                        oppsForUpdate.put(oppUp.Id,oppUp);//2.0+
                                        //oppMap.put(oppUp.Id, oppUp);//2.0-
                                    }
                                    processedBookingIds.add(epayment.Booking__c);//2.1+
                                    continue;
                                } else if(epayment.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLBALANCE){
                                    if(oppUp.StageName <> ApplicationConstant.PAIDFULLBALANCESTAGE){
                                        oppUp.StageName = ApplicationConstant.PAIDFULLBALANCESTAGE;
                                        system.debug('FIND ME > adding for update > '+oppUp.StageName);
                                        oppsForUpdate.put(oppUp.Id,oppUp);//2.0+
                                        //oppMap.put(oppUp.Id, oppUp);//2.0-
                                    }
                                    processedBookingIds.add(epayment.Booking__c);//2.1+
                                    continue; 
                                }
                            }
                        } 
                    }        
                }
            }      
        }catch(Exception e){
           //logs.add(ApplicationConstant.getExceptionLog(e, 'updateOpportunityStage()', CLASS_NAME, null));//2.0-
           Golfbreaks.PlatformLogManager.logExceptions(e,CLASS_NAME,'updateOpportunityStage');//2.0+
        }finally{
            //if(logs.isEmpty() && oppMap.size() > 0){ //2.0-
                //if(oppMap.size() > 0){ //2.0-
                if(oppsForUpdate.size()>0){ //2.0+
                    //Database.SaveResult[] updOppMap = Database.update(oppMap.values(), false);//2.0-
                    Database.SaveResult[] updOppMap = Database.update(oppsForUpdate.values(), false);//2.0+
                    //logs.addAll(ApplicationConstant.getSaveResultLog(updOppMap, 'updateOpportunityStage()', CLASS_NAME, 'Opportunity', 'Update')); 2.0- Replace with new logging
                    Golfbreaks.PlatformLogManager.logExceptions(updOppMap,CLASS_NAME,'updateOpportunityStage',oppsForUpdate.values());//2.0+
                }
            //}
        
            //if(!logs.isEmpty()){
                //Database.insert(logs, false);
            //}
        }
    }
}