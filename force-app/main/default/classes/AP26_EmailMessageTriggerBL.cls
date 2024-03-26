/**
   @Author: Renz Melecotones
   @name: AP26_EmailMessageTriggerBL
   @CreateDate: 04.13.2016
   @Description: Business Logic Class for AP25_EmailMessageTriggerHandler
   @Version <1.0>
 */
public with sharing class AP26_EmailMessageTriggerBL {

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP26_EmailMessageTriggerBL';
    
    /**
       *  This method is used to Update CaseMilestone
       *  @name: updateCaseMileStone
       *  @developer: Aldric Seril 04/13/2016/ -- S.Hajinoor 5/11/2016 -- Renz Melecotones 05/19/2016
       *  @param: newEmailMessageMap - get Trigger.new from EmailMessageTrigger of Map<Id, EmailMessage> Data Type
       *  @history: S.Hajinoor 5/11/2016 - Code Review update: This method will be used instead of the above code since this is more optimized
       *            S.Hajinoor 5/11/2016 - renamed this to updateCaseMilestone from BS_updateCaseMilestone
       *            Renz Melecotones 05/19/2016 - D-0557 - Updated the Code because it is not working.
    **/
    public static void updateCaseMilestone(Map<Id, EmailMessage> newEmailMessageMap) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<CaseMilestone> caseMilestoneUpdateList = new List<CaseMilestone>();
        
        Set<Id> milestoneTypeIdSet = new Set<Id>();     
        Set<Id> caseIdSet = new Set<Id>();
        
        try{
            for(EmailMessage emailRec : newEmailMessageMap.values()) {
                if (!String.isBlank(emailRec.ParentId) && !caseIdSet.contains(emailRec.ParentId)) {
                    caseIdSet.add(emailRec.ParentId);
                }
            }
            
            for(MilestoneType msType : [SELECT Id FROM MileStoneType WHERE Name =: ApplicationConstant.MILESTONE_FIRST_RESPONSE
                                        OR Name =: ApplicationConstant.MILESTONE_INITIAL_RESPONSE_ABTA]){
                milestoneTypeIdSet.add(msType.Id);
            }
            
            if(!caseIdSet.isEmpty() && !milestoneTypeIdSet.isEmpty()){
                for(CaseMilestone caseMilestoneRec : [SELECT Id, CompletionDate FROM CaseMilestone WHERE CaseId IN: caseIdSet AND MilestoneTypeId IN: milestoneTypeIdSet] ){
                    caseMilestoneRec.CompletionDate = System.Now();
                    caseMilestoneUpdateList.add(caseMilestoneRec);
                }
            }
            
        }catch(Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateCaseMilestone', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && !caseMilestoneUpdateList.isEmpty()){
                Database.SaveResult[] cmList = Database.update(caseMilestoneUpdateList, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(cmList, 'updateCaseMilestone', CLASS_NAME, 'CaseMilestone', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }       
    }
}