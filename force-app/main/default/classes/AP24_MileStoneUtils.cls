/**
   @Author: Aldric Seril
   @name: AP24_MileStoneUtils
   @CreateDate: 04.13.2016
   @Description: Update CaseMileStone
   @Version <1.0>
 */ 


public with sharing class AP24_MileStoneUtils{

     /**
       *  This method is used to update the Completion date of the CaseMileStone   
       *  @name: CompleteCaseMileStone
       *  @developer: Aldric Seril 04/13/2016
       *  @param: caseList - get List ID of Case and Set ID of CaseMileStone
       */
       
    
    public static void CompleteCaseMileStone(Set<ID> MilestoneSet, List<Case> caseID ) {
    
        List<CaseMileStone> caseMileStoneList = new List<CaseMileStone>();
        Map<String, String> mapcaseAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        Map<ID, String> CaseMap = new Map<ID, String>();
        
        //START[Milestone Status for reopened cases/ D-0372][Aldric Seril][05/06/2016]-[Add status to include in the milestoneupdate]
        List<ID> caseNewID = new List<ID>();
        
        for(Case casrec : caseID){//caseNew){
                        if(casrec.status <> ApplicationConstant.CASE_STATUS_CLOSED){
                CaseMap.put(casrec.ID, casrec.status);
            }
        }
        //END[Milestone Status for reopened cases/ D-0372][Aldric Seril][05/06/2016]-[Add status to include in the milestoneupdate]
        for(case casID : CaseID){
            caseNewID.add(casID.ID);
        }
            
        List<Id> caseMileStoneReopenedList = new List<Id>();
        
        for(CaseMileStone caseMile : [Select CaseID,  CompletionDate, MilestoneTypeId from CaseMileStone where CaseId IN: caseNewID]){
            if(MilestoneSet.contains(caseMile.MilestonetypeId)){// && (!CaseMap.containskey(caseMile.CaseID)) ){
                caseMile.CompletionDate = System.Now();
                caseMileStoneList.add(caseMile);
            }
            
            if((CaseMap.containskey(caseMile.CaseID))){
                caseMileStoneReopenedList.add(caseMile.Id);
            }
            
        }
        
        reopenMilestones(caseMileStoneReopenedList);
        
        if(caseMileStoneList.size() > 0){         
            Database.SaveResult[] updateCaseMilestoneList = Database.update(caseMileStoneList, false);

                for(Integer i=0; i< updateCaseMilestoneList.size(); i++){
                    Database.SaveResult result = updateCaseMilestoneList[i];
                    // SUCCESS
                    if(updateCaseMilestoneList.get(i).isSuccess()){
                        System.Debug('>>SUCCESS : updateCaseMilestoneList.get(i).getId()<<'+updateCaseMilestoneList.get(i).getId());
                    }
                    // ERROR
                    else{
                        List<Database.Error> lstErrors = result.getErrors();
                        for(Integer j=0; j< lstErrors.size(); j++){        
                            System.Debug('>>ERROR : updateCaseMilestoneList.get(i).Id<<'+updateCaseMilestoneList.get(i).Id);
                        
                            errorLogDescription = '';
                            errorLogDescription += errorLogDescription + ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE + lstErrors.get(j).getMessage() + '\n';
                        
                            mapcaseAndErrors.put( updateCaseMilestoneList.get(i).Id, errorLogDescription);
                        }
                    }
                }
  
            
            if( mapcaseAndErrors <> null && caseMileStoneList <> null ){
                for(caseMilestone cas : caseMileStoneList){
                    if( mapcaseAndErrors.containsKey(cas.Id) ){
                        cas.addError( mapcaseAndErrors.get(cas.Id) );                    
                    }
                }
            }
        }
    
    }
   
    @future
    public static void reopenMilestones(List<ID> milestoneIdList){
        List<CaseMilestone> caseMilestoneList = new List<CaseMileStone>();
        for(Id mId: milestoneIdList){
            caseMilestoneList.add(new CaseMilestone(Id=mId,CompletionDate=null));
        }
        update caseMileStonelist;
    }
}