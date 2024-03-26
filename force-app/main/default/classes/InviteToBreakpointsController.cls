/*
Name: InviteToBreakpointsController
======================================================
======================================================
Purpose: Controller class for InviteToBreakpoints component
======================================================
======================================================
History

Version		Author			Date		Detail
1.0			J Radcliffe		19-03-21	Initial Development
*/
public class InviteToBreakpointsController {
    
    @AuraEnabled
    public static Boolean sendInvite(String fieldName, String sObjectType, String recordId){
        
        Boolean result;
        
        try{
            String accountId;
            if(sObjectType=='Account'){
                accountId = recordId;
            }else{
                //Query the value
                String query;
                query = 'Select '+fieldName+' From '+sObjectType+' Where Id =:recordId Limit 1'; 
                sObject record = database.query(query)[0];
                accountId = (String)record.get(fieldName);
            }       
            if(accountId != null){
                result = WS01_RebarHTTPCallout.emailBreakpointsInvite(accountId);
            }
            
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'InviteToBreakpointsController', 'sendInvite');
            throw new AuraHandledException(e.getMessage());    
        }   
        return result; 
    }
    
}