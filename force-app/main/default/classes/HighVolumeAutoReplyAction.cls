/*
Name:  HighVolumeAutoReplyAction.cls
======================================================
======================================================
Purpose:
-------

This action can be called via flow and other sources to:
1. Check whether High Volume Auto Replies are on for a given Conversation.

======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  Mark Cane&   2024-01-27  Initial development.
1.1  Mark Cane&   2024-02-04  Unit test refactoring.
1.2  Mark Cane&   2024-02-05  Bug fixes. CMT SOQL constraint mitigation.
*/
public with sharing class HighVolumeAutoReplyAction {

    @testVisible static List<AutoReplyConfiguration__mdt> autoReplyConfigurations {//1.1+
        get {
            if (autoReplyConfigurations==null){
                autoReplyConfigurations = [select Id,DeveloperName,
                                                MessagingChannel__c,BusinessUnitDeveloperName__c,WorkItemType__c,
                                                HighVolumeAutoRepliesForNew__c,HighVolumeAutoRepliesForUpdates__c,HighVolumeTemplate__c
                                            from AutoReplyConfiguration__mdt];//1.2~
            }
            return autoReplyConfigurations==null ? new List<AutoReplyConfiguration__mdt>() : autoReplyConfigurations;
        } set;
    }

    @testVisible static List<MessagingChannel__mdt> messagingChannels {//1.1+
        get {
            if (messagingChannels==null){ messagingChannels = [select Id,DeveloperName from MessagingChannel__mdt]; }
            return messagingChannels==null ? new List<MessagingChannel__mdt>() : messagingChannels;
        } set;
    }    

    @InvocableMethod
    public static List<ActionResult> checkHighVolumeAutoReply(List<ActionRequest> requests){

        Map<Integer,ActionResult> seqToResult = new Map<Integer,ActionResult>();

        try {
            Integer seq=0;
            Map<Integer,ActionRequest> seqToRequest = new Map<Integer,ActionRequest>();
            
            Map<Id,Golfbreaks_Business_Unit__c> idToBusinessUnit = new Map<Id,Golfbreaks_Business_Unit__c>([select Id, DeveloperName__c from Golfbreaks_Business_Unit__c]);
            Map<String,Id> businessUnitDeveloperNameToId = new Map<String,Id>();
            for (Golfbreaks_Business_Unit__c bu : idToBusinessUnit.values()){ businessUnitDeveloperNameToId.put(bu.DeveloperName__c,bu.Id); }
            
            Map<Id,String> idToMessagingChannelDeveloperName = new Map<Id,String>();
            Map<String,MessagingChannel__mdt> developerNameToMessagingChannel = new Map<String,MessagingChannel__mdt>();            
            for (MessagingChannel__mdt mc : messagingChannels){ 
                idToMessagingChannelDeveloperName.put(mc.Id,mc.DeveloperName);
                developerNameToMessagingChannel.put(mc.DeveloperName,mc);
            }

            Integer validRequestCount=0;
            for(ActionRequest request : requests){
                seq++;
                seqToRequest.put(seq,request);    
                seqToResult.put(seq,new ActionResult(request.conversationId));    

                if (String.IsBlank(request.businessUnitDeveloperName) || !businessUnitDeveloperNameToId.containsKey(request.businessUnitDeveloperName)){
                    seqToResult.get(seq).isSuccess = false;
                    seqToResult.get(seq).errorMessage = 'Invalid Business Unit Id';
                    continue;
                }

                if (String.IsBlank(request.messagingChannel) || !developerNameToMessagingChannel.containsKey(request.messagingChannel)){
                    seqToResult.get(seq).isSuccess = false;
                    seqToResult.get(seq).errorMessage = 'Invalid Messaging Channel';
                    continue;
                }
                validRequestCount++;
            }
            if (validRequestCount==0) return seqToResult.values();
            
            Map<String, List<AutoReplyConfiguration__mdt>> businessUnitToAutoReplyConfigurations = new Map<String, List<AutoReplyConfiguration__mdt>>(), channelToAutoReplyConfigurations = new Map<String, List<AutoReplyConfiguration__mdt>>();

            String messagingChannelDeveloperName;

            if (autoReplyConfigurations!=null){//1.1+
                for (AutoReplyConfiguration__mdt arc : autoReplyConfigurations){//1.1~
                    if (!arc.HighVolumeAutoRepliesForNew__c && !arc.HighVolumeAutoRepliesForUpdates__c) continue;//1.2+

                    if (String.isNotBlank(arc.BusinessUnitDeveloperName__c) && businessUnitDeveloperNameToId.containsKey(arc.BusinessUnitDeveloperName__c)){                        
                        if (!businessUnitToAutoReplyConfigurations.containsKey(arc.BusinessUnitDeveloperName__c)) businessUnitToAutoReplyConfigurations.put(arc.BusinessUnitDeveloperName__c,new List<AutoReplyConfiguration__mdt>());                
                        businessUnitToAutoReplyConfigurations.get(arc.BusinessUnitDeveloperName__c).add(arc);
                    
                    }

                    messagingChannelDeveloperName = idToMessagingChannelDeveloperName.get(arc.MessagingChannel__c);

                    if (!channelToAutoReplyConfigurations.containsKey(messagingChannelDeveloperName)) channelToAutoReplyConfigurations.put(messagingChannelDeveloperName,new List<AutoReplyConfiguration__mdt>());
                    channelToAutoReplyConfigurations.get(messagingChannelDeveloperName).add(arc);
                }
            }//arc

            ActionRequest ar;
            for (Integer rseq : seqToRequest.keySet()){
                ar = seqToRequest.get(rseq);

                // Order:
                //Channel+BU+Work Item Type
                //Channel+Work Item Type
                //Channel+BU
                //Channel
                
                //Channel+BU+Work Item Type
                if (!businessUnitToAutoReplyConfigurations.isEmpty() && businessUnitToAutoReplyConfigurations.containsKey(ar.businessUnitDeveloperName)){
                    for (AutoReplyConfiguration__mdt arc : businessUnitToAutoReplyConfigurations.get(ar.businessUnitDeveloperName)){
                        //1.1- if (arc.MessagingChannel__r.DeveloperName.equalsIgnoreCase(ar.messagingChannel)) continue;
                        if (!idToMessagingChannelDeveloperName.get(arc.MessagingChannel__c).equalsIgnoreCase(ar.messagingChannel)) continue;//1.1+

                        if (arc.HighVolumeTemplate__c==null) continue;

                        if (((ar.isNew && arc.HighVolumeAutoRepliesForNew__c)
                            || (!ar.isNew && arc.HighVolumeAutoRepliesForUpdates__c))
                            && (String.IsNotBlank(arc.WorkItemType__c)
                                && ((arc.WorkItemType__c=='Booking' && ar.bookingId!=null)
                                    || (arc.WorkItemType__c=='Case' && ar.caseId!=null)
                                    || (arc.WorkItemType__c=='Opportunity' && ar.opportunityId!=null)))){

                            seqToResult.get(rseq).messagingTemplateId = arc.HighVolumeTemplate__c;
                            seqToResult.get(rseq).isHighVolumeAutoReply = true;            
                            break;                    
                        }
                    }
                    if (seqToResult.get(rseq).messagingTemplateId!=null) continue;
                }

                //Channel+Work Item Type
                if (!channelToAutoReplyConfigurations.isEmpty() && channelToAutoReplyConfigurations.containsKey(ar.messagingChannel)){
                    for (AutoReplyConfiguration__mdt arc : channelToAutoReplyConfigurations.get(ar.messagingChannel)){
                        if (arc.HighVolumeTemplate__c==null) continue;

                        if (((ar.isNew && arc.HighVolumeAutoRepliesForNew__c)
                            || (!ar.isNew && arc.HighVolumeAutoRepliesForUpdates__c))
                            && (String.IsNotBlank(arc.WorkItemType__c)
                                && ((arc.WorkItemType__c=='Booking' && ar.bookingId!=null)
                                    || (arc.WorkItemType__c=='Case' && ar.caseId!=null)
                                    || (arc.WorkItemType__c=='Opportunity' && ar.opportunityId!=null)))){

                            seqToResult.get(rseq).messagingTemplateId = arc.HighVolumeTemplate__c;
                            seqToResult.get(rseq).isHighVolumeAutoReply = true;            
                            break;                    
                        }
                    }
                    if (seqToResult.get(rseq).messagingTemplateId!=null) continue;
                }
                
                //Channel+BU
                if (!businessUnitToAutoReplyConfigurations.isEmpty() && businessUnitToAutoReplyConfigurations.containsKey(ar.businessUnitDeveloperName)){
                    for (AutoReplyConfiguration__mdt arc : businessUnitToAutoReplyConfigurations.get(ar.businessUnitDeveloperName)){
                        //1.1- if (arc.MessagingChannel__r.DeveloperName.equalsIgnoreCase(ar.messagingChannel)) continue;
                        if (!idToMessagingChannelDeveloperName.get(arc.MessagingChannel__c).equalsIgnoreCase(ar.messagingChannel)) continue;//1.1+
                        if (arc.HighVolumeTemplate__c==null) continue;

                        if (((ar.isNew && arc.HighVolumeAutoRepliesForNew__c)
                                || (!ar.isNew && arc.HighVolumeAutoRepliesForUpdates__c))
                                && (String.IsBlank(arc.WorkItemType__c))){ 
                                    
                            seqToResult.get(rseq).messagingTemplateId = arc.HighVolumeTemplate__c;
                            seqToResult.get(rseq).isHighVolumeAutoReply = true;
                            break;
                        }
                    }
                    if (seqToResult.get(rseq).messagingTemplateId!=null) continue;
                }           

                //Channel
                if (!channelToAutoReplyConfigurations.isEmpty() && channelToAutoReplyConfigurations.containsKey(ar.messagingChannel)){
                    for (AutoReplyConfiguration__mdt arc : channelToAutoReplyConfigurations.get(ar.messagingChannel)){
                        if (arc.HighVolumeTemplate__c==null) continue;

                        if (((ar.isNew && arc.HighVolumeAutoRepliesForNew__c)
                            || (!ar.isNew && arc.HighVolumeAutoRepliesForUpdates__c))
                            && (String.IsBlank(arc.WorkItemType__c))){

                            seqToResult.get(rseq).messagingTemplateId = arc.HighVolumeTemplate__c;
                            seqToResult.get(rseq).isHighVolumeAutoReply = true;            
                            break;                    
                        }
                    }      
                }          
            }

        } catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'HighVolumeAutoReplyAction','checkHighVolumeAutoReply');
            for(ActionResult result : seqToResult.values()){
                result.isSuccess = false;
                result.errorMessage = e.getMessage()+'-'+e.getStackTraceString();
            }
        }
        return seqToResult.values();
    }
        
    public class ActionRequest {
        
        @InvocableVariable(label='Conversation Id' required=true)
        public String conversationId;

        @InvocableVariable(label='Messaging Channel Developer Name' required=true)
        public String messagingChannel;

        @InvocableVariable(label='Business Unit Developer Name' required=false)
        public String businessUnitDeveloperName;

        @InvocableVariable(label='Case Id' required=false)
        public String caseId;

        @InvocableVariable(label='Booking Id' required=false)
        public String bookingId;

        @InvocableVariable(label='Opportunity Id' required=false)
        public String opportunityId;

        @InvocableVariable(label='Is New Conversation?' required=false)
        public Boolean isNew;
    }

    public class ActionResult {

        private ActionResult(Id conversationId){ 
            isSuccess=true;
            isHighVolumeAutoReply=false;//default: high volume auto-replies are not on.
            this.conversationId = conversationId;
        }

        @InvocableVariable
        public String conversationId;

        @InvocableVariable
        public Boolean isHighVolumeAutoReply;
        
        @InvocableVariable
        public String messagingTemplateId;

        @InvocableVariable
        public Boolean isSuccess;

        @InvocableVariable
        public String errorMessage;
    }
}