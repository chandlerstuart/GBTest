public with sharing class ChangeRequestStatusAlertExtension {


    //TODO - Move to Application Constants.
        /***************************************************************************************
    Developer -    J Radcliffe
    Date -         April 4, 2017
    Version -      1.0
    Change Request Status Values
    #############Change Log#############    
    Modified by     Version     Change Date
    S Molloy        1.1         24/04/2017   Added @AuraEnabled method for Lighting component
    ****************************************************************************************/    
    public static final String CHANGE_REQUEST_NEW = 'New (Not Submitted)';
    public static final String CHANGE_REQUEST_CANCELLED = 'Cancelled By User';
    public static final String CHANGE_REQUEST_REJECTED_BUSINESS_OWNER = 'Rejected by Business Owner';
    public static final String CHANGE_REQUEST_APPROVED_BUSINESS_OWNER = 'Approved by Business Owner';
    public static final String CHANGE_REQUEST_SUBMITTED_BUSINESS_OWNER = 'Submitted to Business Owner';    
    public static final String CHANGE_REQUEST_SUBMITTED_IT = 'Submitted to IT';    
    public static final String CHANGE_REQUEST_REJECTED_IT = 'Rejected by IT';    
    public static final String CHANGE_REQUEST_APPROVED_IT = 'Approved for Development';    
    public static final String CHANGE_REQUEST_IN_PROGRESS = 'In Development';    
    public static final String CHANGE_REQUEST_TESTING = 'In Test';
    public static final String CHANGE_REQUEST_USER_ACCEPTANCE_TESTING = 'In UAT';    
    public static final String CHANGE_REQUEST_RELEASE_READY = 'Approved for Release';     
    public static final String CHANGE_REQUEST_DEPLOYED = 'Deployed/Complete';      

    public static Map<String,ApexPages.Severity> statusAndSeverity{
    
        get{
            if(statusAndSeverity == null){
                statusAndSeverity = new Map<String,ApexPages.Severity>(); 
                statusAndSeverity.put(CHANGE_REQUEST_NEW, ApexPages.Severity.WARNING);    
                statusAndSeverity.put(CHANGE_REQUEST_CANCELLED, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_REJECTED_BUSINESS_OWNER, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_APPROVED_BUSINESS_OWNER, ApexPages.Severity.INFO);                                 
                statusAndSeverity.put(CHANGE_REQUEST_SUBMITTED_BUSINESS_OWNER, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_SUBMITTED_IT, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_REJECTED_IT, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_APPROVED_IT, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_IN_PROGRESS, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_TESTING, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_USER_ACCEPTANCE_TESTING, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_RELEASE_READY, ApexPages.Severity.INFO); 
                statusAndSeverity.put(CHANGE_REQUEST_DEPLOYED, ApexPages.Severity.INFO);                            
            }
            return statusAndSeverity;
        }
        set{
        }    
    } 
    
    public static Map<ApexPages.Severity, String> severityToString {
        get {
            if (null == severityToString){
                severityToString = new Map<ApexPages.Severity, String>();
                severityToString.put(ApexPages.Severity.INFO,'info');
                severityToString.put(ApexPages.Severity.WARNING,'warning');
                severityToString.put(ApexPages.Severity.ERROR,'error');
            }
            
            return severityToString;
            
        }
        
        set;
    }
    
    public static Map<String,String> statusAndLabel{
    
        get{
            if(statusAndLabel== null){
                statusAndLabel= new Map<String,String>(); 
                statusAndLabel.put(CHANGE_REQUEST_NEW, system.label.Change_Request_Status_New);    
                statusAndLabel.put(CHANGE_REQUEST_CANCELLED, system.label.Change_Request_Status_Cancelled_By_User);    
                statusAndLabel.put(CHANGE_REQUEST_REJECTED_BUSINESS_OWNER, system.label.Change_Request_Status_Rejected_by_Business_Owner);    
                statusAndLabel.put(CHANGE_REQUEST_APPROVED_BUSINESS_OWNER, system.label.Change_Request_Status_Approved_by_Business_Owner);    
                statusAndLabel.put(CHANGE_REQUEST_SUBMITTED_BUSINESS_OWNER, system.label.Change_Request_Status_Submitted_to_Business_Owner);    
                statusAndLabel.put(CHANGE_REQUEST_SUBMITTED_IT, system.label.Change_Request_Status_Submitted_to_IT);    
                statusAndLabel.put(CHANGE_REQUEST_REJECTED_IT, system.label.Change_Request_Status_Rejected_by_IT);    
                statusAndLabel.put(CHANGE_REQUEST_APPROVED_IT, system.label.Change_Request_Status_Approved_for_Development);    
                statusAndLabel.put(CHANGE_REQUEST_IN_PROGRESS, system.label.Change_Request_Status_In_Development);    
                statusAndLabel.put(CHANGE_REQUEST_TESTING, system.label.Change_Request_Status_In_Test);    
                statusAndLabel.put(CHANGE_REQUEST_USER_ACCEPTANCE_TESTING, system.label.Change_Request_Status_In_UAT);    
                statusAndLabel.put(CHANGE_REQUEST_RELEASE_READY, system.label.Change_Request_Status_Approved_for_Release);    
                statusAndLabel.put(CHANGE_REQUEST_DEPLOYED, system.label.Change_Request_Status_Deployed_Complete);                                                                                                                                                                                                               
                statusAndLabel.put('NO_RECORD_FOUND',system.label.No_Change_Request_parameter_found);
            }
            return statusAndLabel;
        }
        set{
        }    
    } 

    public ChangeRequestStatusAlertExtension(ApexPages.StandardController controller) {

    }
    
    @AuraEnabled
    public static List<String> getStatusAlertMsg(String recId){
        List<String> returnList = new List<String>();
        if (null == recId){
            returnList.add(severityToString.get(ApexPages.Severity.ERROR));
            returnList.add(statusAndLabel.get('NO_RECORD_FOUND'));
        }else {
            List<Change_Request__c> crList = [Select Id, Status__c FROM Change_Request__c WHERE Id = :recId]; 
        
            if (!crList.isEmpty()){
                returnList.add(severityToString.get(statusAndSeverity.get(crList[0].Status__c)));
                returnList.add(crList[0].Status__c + ': ' + statusAndLabel.get(crList[0].Status__c));
            }else{
                returnList.add(severityToString.get(ApexPages.Severity.ERROR));
                returnList.add(statusAndLabel.get('NO_RECORD_FOUND'));
            }    
        }
        
        return returnList;
    }
    
    public PageReference getCR(){
    
        List<Change_Request__c> crList = [Select Id, Status__c FROM Change_Request__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')]; 
        if (!crList.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(statusAndSeverity.get(crList[0].Status__c),crList[0].Status__c+': '+statusAndLabel.get(crList[0].Status__c)));
            return null;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Change Request parameter found'));
            return null;
        }
    }
}