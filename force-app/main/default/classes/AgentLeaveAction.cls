/*
Name:  AgentLeaveAction.cls
======================================================
======================================================
Purpose:
-------

This action can be called via flow and other sources to:
1. Check whether Agents are unavailable due to approved leave at the current time.
2. Check whether Agents are unavailable due to a company holiday at the current time.

======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  Mark Cane&   2024-01-25  Initial development.
1.1  J Radcliffe  2024-01-30  New output properties: leaveRecord & publicHolidayRecord
*/
public with sharing class AgentLeaveAction {

    @InvocableMethod
    public static List<ActionResult> checkAgentIsOnLeave(List<ActionRequest> requests){

        Map<Integer,ActionResult> seqToResult = new Map<Integer,ActionResult>();

        try {
            Integer seq=0;
            Set<Id> agentIdsToCheck = new Set<Id>(), agentIdsOnLeave;

            for(ActionRequest request : requests){
                seq++;
                seqToResult.put(seq,new ActionResult(request.agentId));
                
                if (String.IsBlank(request.agentId) || !request.agentId.startsWith('005')){
                    seqToResult.get(seq).isSuccess = false;
                    seqToResult.get(seq).errorMessage = 'Invalid Agent Id';
                } else agentIdsToCheck.add(request.agentId);
            }
            if (agentIdsToCheck.isEmpty()) return seqToResult.values();

            WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
            agentIdsOnLeave = alq.getAgentsOnLeave(agentIdsToCheck,false,null);
            if (!agentIdsOnLeave.isEmpty()) agentIdsToCheck.removeAll(agentIdsOnLeave);

            if (!agentIdsToCheck.isEmpty()) agentIdsOnLeave = alq.getAgentsOnCompanyHoliday(agentIdsToCheck,false,null);
            if (!agentIdsOnLeave.isEmpty()) agentIdsToCheck.removeAll(agentIdsOnLeave);

            for (ActionResult result : seqToResult.values()){
                if (agentIdsToCheck.isEmpty() || !agentIdsToCheck.contains(result.agentId)) result.isAgentOnLeave = true;// -- remaining agentIdsToCheck are not on leave.     
                
                //1.1+
                if(result.isAgentOnLeave == true){
                    if(alq.agentsOnLeaveMap?.containsKey(result.agentId)) result.leaveRecord = alq.agentsOnLeaveMap.get(result.agentId);
                    if(alq.agentsOnCompanyLeaveMap?.containsKey(result.agentId)) result.publicHolidayRecord = alq.agentsOnCompanyLeaveMap.get(result.agentId);
                }           
            }

        } catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'AgentLeaveAction','checkAgentIsOnLeave');
            for(ActionResult result : seqToResult.values()){
                result.isSuccess = false;
                result.errorMessage = e.getMessage()+'-'+e.getStackTraceString();
            }
        }
        return seqToResult.values();
    }
        
    public class ActionRequest {
        
        @InvocableVariable(label='Agent Id' required=true)
        public String agentId;
    }

    public class ActionResult {

        private ActionResult(Id agentId){ 
            isSuccess=true;
            isAgentOnLeave=false;//default: agents are not on leave.
            this.agentId = agentId;
        }

        @InvocableVariable
        public String agentId;

        @InvocableVariable
        public Boolean isAgentOnLeave;
        
        @InvocableVariable
        public Boolean isSuccess;

        @InvocableVariable
        public String errorMessage;

        //1.1+
        @InvocableVariable
        public Leave__c leaveRecord;

        //1.1+
        @InvocableVariable
        public PublicHoliday__c publicHolidayRecord;

    }
}