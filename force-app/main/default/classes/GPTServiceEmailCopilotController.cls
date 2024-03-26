/*
Name:  GPTServiceEmailCopilotController
======================================================
======================================================
Purpose:
-------
Controller for GPTServiceEmailCopilot lwc. This cmp 
leverages OpenAI's apis to generate intelligent response
emails to guide agents and streamline email composition.

Note - This controller utilises the security method within 
the GPTAPIManager class to remove all PII data from Case emails
before calling the apis, for added security.
======================================================
======================================================


History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-10  Initial development.
*/
public with sharing class GPTServiceEmailCopilotController {

    @TestVisible public static Boolean throwError = false;
    public static final String aiPromptCategory = 'Customer Service Email Copilot';
    public class CustomException extends Exception{}

    public class PageData{
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<SelectOption> promptOptions;
        @AuraEnabled public Map<String,List<SelectOption>> subPromptOptionsMap;
        @AuraEnabled public Map<String,String> promptIdToPromptMessageMap;
        @AuraEnabled public List<SelectOption> contentSelectOptions;
        @AuraEnabled public Map<Id,String> idToHTMLEmailContentMap;
        @AuraEnabled public Map<Id,String> idToTextEmailContentMap;
        @AuraEnabled public Id bookingId;
        @AuraEnabled public Id clientId;

        public PageData(){
            this.promptOptions = new List<SelectOption>();
            this.subPromptOptionsMap = new Map<String,List<SelectOption>>();
            this.promptIdToPromptMessageMap = new Map<String,String>();
            this.contentSelectOptions = new List<SelectOption>();
            this.idToHTMLEmailContentMap = new Map<Id,String>();
            this.idToTextEmailContentMap = new Map<Id,String>();
        }
    }

    public class SelectOption{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String description;
        public SelectOption(String label, String value){
            this.label = label;
            this.value = value;
        }
        public SelectOption(String label, String value, String description){
            this.label = label;
            this.value = value;
            this.description = description;
        }
    }

    public Class AskGPTSuccessResponse{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public List<GPTAPIManager.GPTMessage> messages;
        @AuraEnabled public String output;
    }
    
    
    @AuraEnabled 
    public static PageData loadComponent(String recordId){

        PageData data = new PageData();

        try{
            //Retrieve prompt actions for quick changes to the output.
            List<AIPrompt__mdt> promptsWithSubprompts = [Select Id, (Select Id, AIPrompt__c, DisplayName__c, PromptMessage__c, Description__c From AISubprompts__r), DisplayName__c, PromptMessage__c, Description__c From AIPrompt__mdt Where Category__c = :aiPromptCategory];
            for(AIPrompt__mdt prompt : promptsWithSubprompts){
                data.promptIdToPromptMessageMap.put(prompt.Id,prompt.PromptMessage__c);
                data.promptOptions.add(new SelectOption(prompt.DisplayName__c,prompt.Id, prompt.Description__c));
                if(prompt.AISubprompts__r.size()>0){
                    for(AISubPrompt__mdt subPrompt : prompt.AISubprompts__r){
                        data.promptIdToPromptMessageMap.put(subPrompt.Id,subPrompt.PromptMessage__c);
                        if(!data.subPromptOptionsMap.containsKey(subPrompt.AIPrompt__c)) data.subPromptOptionsMap.put(subPrompt.AIPrompt__c,new List<SelectOption>());
                        data.subPromptOptionsMap.get(subPrompt.AIPrompt__c).add(new SelectOption(subPrompt.DisplayName__c,subPrompt.Id,subPrompt.Description__c)); 
                    }
                }
            }

            //Retrieve the case and related inbound email messages
            Case cse = [Select Id, Description, Booking__c, AccountId, (Select Id, Subject, ToAddress, FromAddress, TextBody, HTMLBody, Incoming, Format(CreatedDate) From EmailMessages Where Incoming = true Order by CreatedDate desc) From Case Where Id =:recordId];
            if(cse.EmailMessages.size()>0){
                for(EmailMessage email : cse.EmailMessages){
                    String prefix = (email.Incoming)?'Received from '+email.FromAddress+' ['+email.CreatedDate+'] > ':'Sent to '+email.ToAddress+' ['+email.CreatedDate+'] > ';
                    data.idToHTMLEmailContentMap.put(email.Id,email.HTMLBody);
                    data.idToTextEmailContentMap.put(email.Id,email.TextBody);
                    data.contentSelectOptions.add(new SelectOption(prefix+' '+email.Subject,email.Id));
                }
            }
            data.idToHTMLEmailContentMap.put(cse.Id,cse.Description);
            data.idToTextEmailContentMap.put(cse.Id,cse.Description);
            data.contentSelectOptions.add(new SelectOption('Case Description',cse.Id));
            data.clientId = cse.AccountId;
            data.bookingId = cse.Booking__c;

            if(throwError) throw new CustomException('Whoops! Something went wrong');

            return data;

        }catch(Exception e){
            system.debug(e.getMessage()+'-'+e.getStackTraceString());
            data.errorMessage = e.getMessage()+'-'+e.getStackTraceString();
            return data;
        }
    }

    @AuraEnabled
    public static AskGPTSuccessResponse askGPT(String messagesJSON, 
                                                String prompt, 
                                                String bookingId, 
                                                String clientId,
                                                String focusContent){
        List<GPTAPIManager.GPTMessage> messages = (messagesJSON != null)?(List<GPTAPIManager.GPTMessage>)JSON.deserialize(messagesJSON, List<GPTAPIManager.GPTMessage>.class):new List<GPTAPIManager.GPTMessage>();
        
        Boolean isNewConversation = (messages == null || messages.size()==0 )?true:false;
        system.debug('isNewConversation > '+isNewConversation);
        system.debug('messages > '+messages);

        if(isNewConversation){

            messages = new List<GPTAPIManager.GPTMessage>();

            focusContent = condenseEmailContent(focusContent);

            Account acc = [Select Id, FirstName, LastName From Account Where Id = :clientId];

            GPTAPIManager.GPTMessage message1 = new GPTAPIManager.GPTMessage();
            message1.role = 'system';
            message1.content = 'You are a friendly and profesional service assistant. Your role is to help '+UserInfo.getFirstName()+' respond to '+acc.FirstName+' who contacted Golfbreaks about their trip. Please follow the instructions to help '+UserInfo.getFirstName()+' politely tackle any questions or requests.';
            messages.add(message1);

            GPTAPIManager.GPTMessage message2 = new GPTAPIManager.GPTMessage();
            prompt = 'Please review this email chain, considering the top email is the most recent and works back chronologically, ignoring details that are not related to the core message (e.g. the company): "'+GPTAPIManager.de_identifyContent(focusContent)+'". Compose a polite and professional email response message on behalf of '+UserInfo.getFirstName()+' to the sender of the most recent email message. If you are not sure who the sender is, assume it is '+acc.FirstName+'. Be sensitive to the sentiment of the email.';
            message2.role = 'user';
            message2.content = prompt;
            messages.add(message2);
        }else{

            //Continue conversation
            GPTAPIManager.GPTMessage message = new GPTAPIManager.GPTMessage();
            message.role = 'user';
            message.content = GPTAPIManager.de_identifyContent(prompt);
            messages.add(message);
        }

        AskGPTSuccessResponse response = new AskGPTSuccessResponse();
        response.messages = GPTAPIManager.askGPT(messages,true);
        response.isSuccess = (response.messages != null)?true:false;
        if(response.isSuccess) response.output = response.messages[response.messages.size()-1].content; 
        
        return response;
    }

    public static String condenseEmailContent(String emailContent) {

        if(emailContent == null || String.isBlank(emailContent)) return '';

        // Split the email content into lines
        List<String> lines = emailContent.split('\n');

        // Create a new list to store condensed lines
        List<String> condensedLines = new List<String>();

        for (String line : lines) {
            if (line.trim() == '') continue; // Skip entirely blank lines
            if (line.startsWith('>') && line.replace('>','').trim()=='') continue;
            condensedLines.add(line);
        }

        // Join the condensed lines back into a single string
        String condensedEmailContent = String.join(condensedLines, '\n');

        return condensedEmailContent;
    }

}