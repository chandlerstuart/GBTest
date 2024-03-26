/*
Purpose: Apex Controller for SendOppToClubhouse
TO DO - This has been thrown together to support a release. Needs deprecating or refining at a later stage
*/
public class SendOppToClubhouseController {
    
    @TestVisible static Boolean throwError = false;
    
    @AuraEnabled
    public static void queueAction(Opportunity opp){
        try{
            if(throwError) throw new TestCodeException('Test Code Exception');//1.3
            List<Opportunity> oppList = new List<Opportunity>();
            if(opp != null){
                oppList.add(opp);              
                OpportunityToEnquiryAction.SendOppstoClubhouse(oppList);
            }
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'SendOppToClubhouseController', 'queueAction'); 
        }
    }
}