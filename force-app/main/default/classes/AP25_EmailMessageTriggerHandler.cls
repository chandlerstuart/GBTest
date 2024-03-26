/**
   @Author: Renz Melecotones
   @name: AP25_EmailMessageTriggerHandler
   @CreateDate: 04.13.2016
   @Description: Handler Class for EmailMessageTrigger
   @Version <1.0>
 */ 
public with sharing class AP25_EmailMessageTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    public AP25_EmailMessageTriggerHandler(){
        
    }

    public void OnBeforeInsert(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
    
    }   
    
    public void OnBeforeUpdate(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){

    }
    
    public void OnAfterInsert(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
        if(!isAfterInsertTriggerCalled){
            AP26_EmailMessageTriggerBL.updateCaseMileStone(newEmailMessageMap);
            
            isAfterInsertTriggerCalled = TRUE;
        }    
    }
    
    public void OnAfterUpdate(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
        
    }
    
    public void OnBeforeDelete(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
        
    }
    
    public void OnAfterDelete(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
        
    }
     
    public void OnAfterUnDelete(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
        
    }
    
    public void OnUndelete(List<EmailMessage> newEmailMessageList, Map<Id,EmailMessage> newEmailMessageMap, List<EmailMessage> oldEmailMessageList, Map<Id,EmailMessage> oldEmailMessageMap){
        
    }
}