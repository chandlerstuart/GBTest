/*
Name:  AutoReplyMessageAction.cls
======================================================
======================================================
Purpose:
-------

This action can be called via flow and other sources to:
1a. Return the formatted AutoReply Message for a given Conversation and auto-reply type.
1b. Or, specified Messaging Template Id (UseCase:HighVolumeAutoReplyAction returns the Messaging Template Id).

======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  Mark Cane&   2024-01-27  Initial development.
1.1  Mark Cane&   2024-02-04  Enhancements. conversationRecord and isNew request inputs.
1.2  Mark Cane&   2024-02-05  Enhancements. messageChannel should be the DeveloperName not Id.
1.3  J Radcliffe  2024-02-05  Bug Fixes. a. Default null booleans to false. b. channelToAutoReplyConfigurations instantiate with String key (instead of Id) c. Null check before for loop. d. messagingTemplateUIDToConversationIds & idToMessagingTemplate maps instantiate with String key (instead of Id)
1.4  J Radcliffe  2024-02-06  Enhancements. messagingTemplateId should be the UID__c not SFId.  
1.5  J Radcliffe  2024-02-06  Enhancements. add support for new template type: NewConversationTemplate__c
1.6  J Radcliffe  2024-02-06  Assorted Bug Fixes.
1.7  Mark Cane&   2024-02-14  Unit test refactoring.
1.8  J Radcliffe  2024-02-16  Apex Defined Data Type in flow do not support inner classes (moving Custom Param to it's own class)
1.9  J Radcliffe  2024-02-16  Query missing fields to avoid 'SObject row was retrieved via SOQL without querying the requested field' error
*/
public with sharing class AutoReplyMessageAction2 {

    @testVisible static List<AutoReplyConfiguration__mdt> autoReplyConfigurations {//1.7+ -- set with in-memory records for unit tests.
        get {
            if (autoReplyConfigurations==null){
                autoReplyConfigurations = [select Id,DeveloperName,
                                                MessagingChannel__c,BusinessUnitDeveloperName__c,WorkItemType__c,
                                                HighVolumeAutoRepliesForNew__c,HighVolumeAutoRepliesForUpdates__c,HighVolumeTemplate__c,

                                                //1.9+
                                                MessagingChannel__r.DeveloperName,
                                                AgentUnavailableTemplate__c,
                                                OutsideBusinessHoursTemplate__c,
                                                UnrecognisedCustomerTemplate__c,
                                                AgentUnavailableTemplate__r.UID__c,
                                                OutsideBusinessHoursTemplate__r.UID__c,
                                                HighVolumeTemplate__r.UID__c,
                                                UnrecognisedCustomerTemplate__r.UID__c,
                                                NewConversationTemplate__r.UID__c


                                            from AutoReplyConfiguration__mdt];
            }
            return autoReplyConfigurations==null ? new List<AutoReplyConfiguration__mdt>() : autoReplyConfigurations;
        } set;
    }

    @testVisible static List<MessagingChannel__mdt> messagingChannels {//1.7+
        get {
            if (messagingChannels==null){ messagingChannels = [select Id,DeveloperName from MessagingChannel__mdt]; }
            return messagingChannels==null ? new List<MessagingChannel__mdt>() : messagingChannels;
        } set;
    }

    @testVisible static List<MessagingTemplate__mdt> messagingTemplates {//1.7+
        get {
            if (messagingTemplates==null){ messagingTemplates = [select Id,UID__c,DeveloperName,MessageFormat__c,MessageFormatFields__c from MessagingTemplate__mdt]; }
            return messagingTemplates==null ? new List<MessagingTemplate__mdt>() : messagingTemplates;
        } set;
    }     

    @InvocableMethod
    public static List<ActionResult> getAutoReplyMessage(List<ActionRequest> requests){

        Map<Integer,ActionResult> seqToResult = new Map<Integer,ActionResult>();

        try {
            Integer seq=0;
            Map<Integer,ActionRequest> seqToRequest = new Map<Integer,ActionRequest>();
            Map<Id,List<CustomParameter>> conversationIdToCustomParameters = new Map<Id,List<CustomParameter>>();//1.7+
            Map<Id,Conversation__c> idToConversation = new Map<Id,Conversation__c>();

            Map<Id,Golfbreaks_Business_Unit__c> idToBusinessUnit = new Map<Id,Golfbreaks_Business_Unit__c>([select Id, DeveloperName__c from Golfbreaks_Business_Unit__c]);
            Map<String,Id> businessUnitDeveloperNameToId = new Map<String,Id>();
            for (Golfbreaks_Business_Unit__c bu : idToBusinessUnit.values()){ businessUnitDeveloperNameToId.put(bu.DeveloperName__c,bu.Id); }
            
            Map<Id,String> idToMessagingChannelDeveloperName = new Map<Id,String>();
            Map<String,MessagingChannel__mdt> developerNameToMessagingChannel = new Map<String,MessagingChannel__mdt>();            
            for (MessagingChannel__mdt mc : messagingChannels){ 
                idToMessagingChannelDeveloperName.put(mc.Id,mc.DeveloperName);
                developerNameToMessagingChannel.put(mc.DeveloperName,mc);
            }

            Map<Id,MessagingTemplate__mdt> idToMessagingTemplate = new Map<Id,MessagingTemplate__mdt>();
            Map<String,MessagingTemplate__mdt> uidToMessagingTemplate = new Map<String,MessagingTemplate__mdt>();
            for (MessagingTemplate__mdt mt : messagingTemplates){ 
                idToMessagingTemplate.put(mt.Id,mt);
                uidToMessagingTemplate.put(mt.UID__c,mt);
            }
            
            Integer validRequestCount=0;

            for(ActionRequest request : requests){
                seq++;
                seqToRequest.put(seq,request);    
                seqToResult.put(seq,new ActionResult(request.conversationId));   
                
                if (request.conversationRecord!=null) idToConversation.put(request.conversationId,request.conversationRecord);//1.1~ -- the last request for a given conversatiom wins.
                if (request.customParameters!=null && !request.customParameters.isEmpty()) conversationIdToCustomParameters.put(request.conversationId,request.customParameters);//1.7~ -- the last request for a given conversatiom wins.                
                
                if  (String.isNotBlank(request.messagingTemplateId)){                    
                    if (!uidToMessagingTemplate.containsKey(request.messagingTemplateId)){
                        seqToResult.get(seq).isSuccess = false;
                        seqToResult.get(seq).errorMessage = 'Invalid Messaging Template UID';
                    } else validRequestCount++;
                    continue;
                }

                //1.3a+
                if(request.isUnrecognisedCustomer == null) request.isUnrecognisedCustomer = false;
                if(request.isHighVolume == null) request.isHighVolume = false;
                if(request.isAgentUnavailable == null) request.isAgentUnavailable = false;
                if(request.isOutsideBusinessHours == null) request.isOutsideBusinessHours = false;
                if(request.isNew == null) request.isNew = false;//1.5+
                
                if ((String.IsNotBlank(request.businessUnitDeveloperName) && !businessUnitDeveloperNameToId.containsKey(request.businessUnitDeveloperName))
                    || (String.IsNotBlank(request.businessUnitId) && !idToBusinessUnit.containsKey(request.businessUnitId))){
                    seqToResult.get(seq).isSuccess = false;
                    seqToResult.get(seq).errorMessage = 'A Valid Business Unit ID or Developer Name is Required';
                    continue;
                } else if (String.IsBlank(request.businessUnitDeveloperName) && String.IsNotBlank(request.businessUnitId) && idToBusinessUnit.containsKey(request.businessUnitId)){
                    request.businessUnitDeveloperName = idToBusinessUnit.get(request.businessUnitId).DeveloperName__c;
                }

                if (String.IsBlank(request.messagingChannel) || !developerNameToMessagingChannel.containsKey(request.messagingChannel)){
                    seqToResult.get(seq).isSuccess = false;
                    seqToResult.get(seq).errorMessage = 'Invalid Messaging Channel Developer Name';
                    continue;
                }
                                
                validRequestCount++;
            }
            if (validRequestCount==0) return seqToResult.values();
            
            Map<String, List<AutoReplyConfiguration__mdt>> businessUnitToAutoReplyConfigurations = new Map<String, List<AutoReplyConfiguration__mdt>>(), channelToAutoReplyConfigurations = new Map<String, List<AutoReplyConfiguration__mdt>>();

            String messagingChannelDeveloperName;

            if (autoReplyConfigurations!=null){//1.7~
                for (AutoReplyConfiguration__mdt arc : autoReplyConfigurations){

                    if (String.isNotBlank(arc.BusinessUnitDeveloperName__c) && businessUnitDeveloperNameToId.containsKey(arc.BusinessUnitDeveloperName__c)){                        
                        if (!businessUnitToAutoReplyConfigurations.containsKey(arc.BusinessUnitDeveloperName__c)) businessUnitToAutoReplyConfigurations.put(arc.BusinessUnitDeveloperName__c,new List<AutoReplyConfiguration__mdt>());                
                        businessUnitToAutoReplyConfigurations.get(arc.BusinessUnitDeveloperName__c).add(arc);                    
                    }

                    messagingChannelDeveloperName = idToMessagingChannelDeveloperName.get(arc.MessagingChannel__c);

                    if (!channelToAutoReplyConfigurations.containsKey(messagingChannelDeveloperName)) channelToAutoReplyConfigurations.put(messagingChannelDeveloperName,new List<AutoReplyConfiguration__mdt>());
                    channelToAutoReplyConfigurations.get(messagingChannelDeveloperName).add(arc);
                }
            }//arc

            ActionRequest request;
            for (Integer rseq : seqToRequest.keySet()){// -- assign messaging template by AutoReplyConfiguration.

                request = seqToRequest.get(rseq);

                if (request.messagingTemplateId!=null && !String.isBlank(request.messagingTemplateId)){
                    seqToResult.get(rseq).messagingTemplateId = request.messagingTemplateId;
                    continue;
                }

                // Order:
                //Channel+BU+Work Item Type
                //Channel+Work Item Type
                //Channel+BU
                //Channel
                
                //Channel+BU+Work Item Type
                if (String.isNotBlank(request.businessUnitDeveloperName) && !businessUnitToAutoReplyConfigurations.isEmpty() && businessUnitToAutoReplyConfigurations.containsKey(request.businessUnitDeveloperName)){
                    for (AutoReplyConfiguration__mdt arc : businessUnitToAutoReplyConfigurations.get(request.businessUnitDeveloperName)){// -- Business Unit
                        if (!idToMessagingChannelDeveloperName.get(arc.MessagingChannel__c).equalsIgnoreCase(request.messagingChannel)) continue;                        
                        if (!checkAutoReplyConfiguration(arc,request)) continue;

                        if (String.IsNotBlank(arc.WorkItemType__c)
                            && ((arc.WorkItemType__c=='Booking' && request.bookingId!=null)
                                || (arc.WorkItemType__c=='Case' && request.caseId!=null)
                                || (arc.WorkItemType__c=='Opportunity' && request.opportunityId!=null))){

                            seqToResult.get(rseq).messagingTemplateId = getTemplateUID(arc,request,idToMessagingTemplate);                  
                            break;                    
                        }
                    }
                }                
                if (seqToResult.get(rseq).messagingTemplateId!=null) continue;

                //Channel+Work Item Type
                if (!channelToAutoReplyConfigurations.isEmpty() && channelToAutoReplyConfigurations.containsKey(request.messagingChannel)){
                    for (AutoReplyConfiguration__mdt arc : channelToAutoReplyConfigurations.get(request.messagingChannel)){// -- Channel
                        if (!checkAutoReplyConfiguration(arc,request)) continue;

                        if (String.IsNotBlank(arc.WorkItemType__c)
                            && ((arc.WorkItemType__c=='Booking' && request.bookingId!=null)
                                || (arc.WorkItemType__c=='Case' && request.caseId!=null)
                                || (arc.WorkItemType__c=='Opportunity' && request.opportunityId!=null))){

                            seqToResult.get(rseq).messagingTemplateId = getTemplateUID(arc,request,idToMessagingTemplate);      
                            break;                    
                        }
                    }
                }
                if (seqToResult.get(rseq).messagingTemplateId!=null) continue;
                
                //Channel+BU
                if (String.isNotBlank(request.businessUnitDeveloperName) && !businessUnitToAutoReplyConfigurations.isEmpty() && businessUnitToAutoReplyConfigurations.containsKey(request.businessUnitDeveloperName)){
                    for (AutoReplyConfiguration__mdt arc : businessUnitToAutoReplyConfigurations.get(request.businessUnitDeveloperName)){// -- Business Unit
                        if (!idToMessagingChannelDeveloperName.get(arc.MessagingChannel__c).equalsIgnoreCase(request.messagingChannel)) continue;//1.1+
                        if (!checkAutoReplyConfiguration(arc,request)) continue;

                        if (String.IsBlank(arc.WorkItemType__c)){                                    
                            seqToResult.get(rseq).messagingTemplateId = getTemplateUID(arc,request,idToMessagingTemplate);
                            break;
                        }
                    }
                }                
                if (seqToResult.get(rseq).messagingTemplateId!=null) continue;

                //Channel
                if (!channelToAutoReplyConfigurations.isEmpty() && channelToAutoReplyConfigurations.containsKey(request.messagingChannel)){                
                    for (AutoReplyConfiguration__mdt arc : channelToAutoReplyConfigurations.get(request.messagingChannel)){// -- Channel
                        if (!checkAutoReplyConfiguration(arc,request)) continue;

                        seqToResult.get(rseq).messagingTemplateId = getTemplateUID(arc,request,idToMessagingTemplate);        
                        break;
                    }
                }
            }// -- request
            
            Map<String,Set<Id>> messagingTemplateUIDToConversationIds = new Map<String,Set<Id>>();//1.3d~
            
            for (ActionResult result : seqToResult.values()){
                if (!messagingTemplateUIDToConversationIds.containsKey(result.messagingTemplateId)) messagingTemplateUIDToConversationIds.put(result.messagingTemplateId,new Set<Id>());
                messagingTemplateUIDToConversationIds.get(result.messagingTemplateId).add(result.conversationId);                                
            }

            Map<Id,String> recordIdToMessage = new Map<Id,String>();
            Map<Id,String> allRecordIdToMessage = new Map<Id,String>();

            for (String messagingTemplateUID : messagingTemplateUIDToConversationIds.keySet()){//1.3d~       
                recordIdToMessage = buildMessagesForMessagingTemplate(uidToMessagingTemplate.get(messagingTemplateUID),messagingTemplateUIDToConversationIds.get(messagingTemplateUID),idToConversation,conversationIdToCustomParameters);//1.7~
                if (recordIdToMessage!=null) allRecordIdToMessage.putAll(recordIdToMessage);
            }

            for (ActionResult result : seqToResult.values()){
                if (recordIdToMessage.containsKey(result.conversationId)) result.autoReplyMessage = recordIdToMessage.get(result.conversationId);
            }

        } catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'AutoReplyMessageAction','getAutoReplyMessage');
            for(ActionResult result : seqToResult.values()){
                result.isSuccess = false;
                result.errorMessage = e.getMessage()+'-'+e.getStackTraceString();
            }
        }
        return seqToResult.values();
    }

    public class ActionRequest {

        public ActionRequest(){ customParameters=new List<CustomParameter>(); }
        
        @InvocableVariable(label='Conversation Id' required=true)
        public String conversationId;

        @InvocableVariable(label='Conversation Record' required=false)
        public Conversation__c conversationRecord;//1.1+

        @InvocableVariable(label='Messaging Template Id' required=false)
        public String messagingTemplateId;

        @InvocableVariable(label='Is Unrecognised Customer?' required=false)
        public Boolean isUnrecognisedCustomer;

        @InvocableVariable(label='Is High Volume?' required=false)
        public Boolean isHighVolume;

        @InvocableVariable(label='Is Agent Unavailable?' required=false)
        public Boolean isAgentUnavailable;

        @InvocableVariable(label='Is Outside Business Hours?' required=false)
        public Boolean isOutsideBusinessHours;

        @InvocableVariable(label='Messaging Channel Developer Name' required=false)
        public String messagingChannel;

        @InvocableVariable(label='Business Unit DeveloperName' required=false)
        public String businessUnitDeveloperName;

        @InvocableVariable(label='Business Unit Id' required=false)
        public String businessUnitId;

        @InvocableVariable(label='Case Id' required=false)
        public String caseId;

        @InvocableVariable(label='Booking Id' required=false)
        public String bookingId;

        @InvocableVariable(label='Opportunity Id' required=false)
        public String opportunityId;

        @InvocableVariable(label='Is New Conversation?' required=false)
        public Boolean isNew;//1.1+

        @InvocableVariable(label='Custom Parameters' required=false)
        public List<CustomParameter> customParameters;
    }

    //1.8-
    /*public class CustomParameter {//1.7+

        public CustomParameter(String parameterName, String parameterValue){
            this.parameterName = parameterName;
            this.parameterValue = parameterValue;
        }

        @InvocableVariable(label='Parameter Name' required=true)
        public String parameterName;

        @InvocableVariable(label='Parameter Value' required=true)
        public String parameterValue;// -- InvocableVariable fields do not support type of Object. Inputs should be pre-formatted.
    }*/

    public class ActionResult {

        private ActionResult(Id conversationId){ 
            isSuccess=true;  
            this.conversationId = conversationId;
        }

        @InvocableVariable
        public String conversationId;

        @InvocableVariable
        public String autoReplyMessage;
        
        @InvocableVariable
        public String messagingTemplateId;

        @InvocableVariable
        public Boolean isSuccess;

        @InvocableVariable
        public String errorMessage;
    }

    // Helper methods.
    private static Boolean checkAutoReplyConfiguration(AutoReplyConfiguration__mdt arc, ActionRequest request){

        if (request.isAgentUnavailable && arc.AgentUnavailableTemplate__c!=null) return true;
        if (request.isHighVolume && (arc.HighVolumeTemplate__c!=null && ((request.isNew && arc.HighVolumeAutoRepliesForNew__c) || (!request.isNew && arc.HighVolumeAutoRepliesForUpdates__c)))) return true;//1.1~
        if (request.isOutsideBusinessHours && arc.OutsideBusinessHoursTemplate__c!=null) return true;
        if (request.isUnrecognisedCustomer && arc.UnrecognisedCustomerTemplate__c!=null) return true;
        if (request.isNew && arc.NewConversationTemplate__c!=null) return true;//1.5+
        return false;
    }

    private static String getTemplateUID(AutoReplyConfiguration__mdt arc, ActionRequest request, Map<Id,MessagingTemplate__mdt> idToMessagingTemplate){
        Id messagingTemplateId;

        //1.4~
        if (request.isAgentUnavailable) messagingTemplateId = arc.AgentUnavailableTemplate__c;
        else if (request.isHighVolume) messagingTemplateId = arc.HighVolumeTemplate__c;
        else if (request.isOutsideBusinessHours) messagingTemplateId = arc.OutsideBusinessHoursTemplate__c;
        else if (request.isUnrecognisedCustomer) messagingTemplateId = arc.UnrecognisedCustomerTemplate__c;
        else if (request.isNew) messagingTemplateId = arc.NewConversationTemplate__c;//1.5+
        
        if (messagingTemplateId!=null && idToMessagingTemplate.containsKey(messagingTemplateId)) return idToMessagingTemplate.get(messagingTemplateId).UID__c;
        return null;
    }

    public static Map<Id,String> buildMessagesForMessagingTemplate(MessagingTemplate__mdt mt, Set<Id> recordIds, Map<Id,Conversation__c> idToConversation, Map<Id,List<CustomParameter>> conversationIdToCustomParameters){//1.7~

        Map<Id,String> recordIdToMessage = new Map<Id,String>();

        try {
            if (mt==null || recordIds==null || recordIds.isEmpty()) return recordIdToMessage;
            
            String sObjectTypeName = 'Conversation__c';
            Type t = Type.forName('',sObjectTypeName);
            if (t==null) return recordIdToMessage;
            
            Schema.SObjectType sObjectType = ((SObject)t.newInstance()).getSObjectType();
                        
            String idFieldName = 'Id';
            
            List<String> formatStringArguments = new List<String>();//1.7+ -- could be SObject fields or Custom Parameters, which are specified by the name enclosed in square brackets.
            List<String> formatStringFields = new List<String>();//1.7~ -- Id,AccountName__c,[customParam1Name],Booking__r.Name,[customParam1Name].

            if (String.isNotBlank(mt.MessageFormatFields__c)){
                
                for (String mff : mt.MessageFormatFields__c.deleteWhitespace().split(',')){
                    formatStringArguments.add(mff);//1.7+

                    if (!mff.contains('[') && !mff.contains(']')) formatStringFields.add(mff);
                }                     
                if (formatStringArguments.isEmpty()) return recordIdToMessage;//1.7~
            } else {//1.6+ -- no format to be evaluated, just return the MessageFormat.
                for (Id recordId : recordIds){ recordIdToMessage.put(recordId,mt.MessageFormat__c); }
                return recordIdToMessage;
            }

            Boolean isIdFieldOnly = formatStringFields.size()==1 && (new List<String>(formatStringFields)[0].equalsIgnoreCase('Id')) ? true : false;

            Sobject o;
            Map<Id,Sobject> idToSObject;
            Set<String> fieldsAdded = new Set<String>();
            
            if(isIdFieldOnly || (formatStringFields.isEmpty() && !formatStringArguments.isEmpty())){//1.7~ -- Id field only or Custom Parameters only.
                idToSObject = new Map<Id,Sobject>();

                for (Id recordId : recordIds){ 
                    o = sObjectType.newSObject();
                    o.put(idFieldName,recordId);
                    idToSObject.put(recordId,o);
                }
                fieldsAdded.add(idFieldName.toUpperCase());

            } else if (!formatStringFields.isEmpty()){//1.7~ -- only query if formatStringFields exist.

                String q='select Id';
                fieldsAdded.add('ID'); 
                
                for (String f : formatStringFields){

                    if (f.contains('.')){//Parent relationship field reference.

                        // E.g. ParentAccount.CreatedBy.Email

                        // Start - SobjectType = e.g. Account.
                        // index 0 - get parentrelationship map for Sobject and containsKey check on index, get the next SobjectType.
                        // index n - if not last index - set SobjectType and repeat 0
                        // index n - if last index - get field map for SobjectType and containsKey check.

                        String parentRelationshipName, parentSobjectTypeName = sObjectTypeName;
                        Boolean isPolymorphic=false;

                        List<String> pathElements = f.split('\\.');

                        for (Integer n=0; n<pathElements.size(); n++){

                            if (n==pathElements.size()-1){//last index -- validate field name.
                                
                                if (!fieldsAdded.contains(f.toUpperCase()) && getObjectFieldMap(parentSobjectTypeName).containsKey(pathElements[n])){
                                    
                                    if (String.isNotBlank(parentRelationshipName) && isPolymorphic){
                                        q+=',TYPEOF '+String.escapeSingleQuotes(parentRelationshipName)+' WHEN '+String.escapeSingleQuotes(parentSobjectTypeName)+' THEN '+String.escapeSingleQuotes(pathElements[n])+' END';

                                    } else q+=','+String.escapeSingleQuotes(f);                                    
                                    
                                    fieldsAdded.add(f.toUpperCase());//add the full field path.
                                }
                                
                            } else {// -- validate parent relationship name.

                                isPolymorphic = pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2;
                                                                
                                parentRelationshipName = isPolymorphic ? pathElements[n].split('\\|')[0] : pathElements[n];

                                if (!getObjectParentRelationshipMap(parentSobjectTypeName).containsKey(parentRelationshipName)) break;// -- parent relationship name doesn't exist.
                                
                                if (isPolymorphic 
                                    && getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName).size()>1
                                    && getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName).contains(pathElements[n].split('\\|')[1])){
                                    
                                    parentSobjectTypeName = pathElements[n].split('\\|')[1];

                                } else {

                                    isPolymorphic=false;
                                    parentSobjectTypeName = getObjectParentRelationshipMap(parentSobjectTypeName).get(parentRelationshipName)[0];
                                }
                            }
                        }
                    } else {
                        
                        if (getObjectFieldMap(sObjectTypeName).containsKey(f) && !fieldsAdded.contains(f.toUpperCase())){
                            q+=','+String.escapeSingleQuotes(f);
                            fieldsAdded.add(f.toUpperCase()); 
                        }
                    }
                }
                q+=' from '+String.escapeSingleQuotes(sObjectTypeName);
                q+=' where '+idFieldName+' in :recordIds';

                idToSObject = new Map<Id,SObject>(Database.query(q));                
            }
            if (idToSObject.isEmpty()) return recordIdToMessage;

            Map<String, Object> fieldsMap;
            Map<String, String> customParameterMap;

            for (Id recordId : idToSObject.keySet()){            
                o = idToSObject.get(recordId);
                fieldsMap = new Map<String,Object>(o.getPopulatedFieldsAsMap());//1.6~
                
                customParameterMap = new Map<String, String>();
                if (conversationIdToCustomParameters.containsKey(recordId) && !conversationIdToCustomParameters.get(recordId).isEmpty()){
                    for (CustomParameter cp : conversationIdToCustomParameters.get(recordId)){
                        if (String.isBlank(cp.parameterName) || cp.parameterValue==null) continue;
                        customParameterMap.put(cp.parameterName.toUpperCase(),cp.parameterValue);
                    }
                }
                if (idToConversation.containsKey(recordId) && !idToConversation.get(recordId).getPopulatedFieldsAsMap().isEmpty()) fieldsMap.putAll(idToConversation.get(recordId).getPopulatedFieldsAsMap());//1.1~

                recordIdToMessage.put(recordId,formatString(fieldsAdded,formatStringArguments,mt.MessageFormat__c,fieldsMap,customParameterMap,o,false));//1.7~
            }//recordId.

        } catch(Exception ex){ Golfbreaks.PlatformLogManager.logExceptions(ex, 'AutoReplyMessageAction', 'buildMessagesForMessagingTemplate'); }
        return recordIdToMessage;
    }    

    private static String formatString(Set<String> validFormatStringFields, List<String> formatStringArguments, String formatString, Map<String, Object> populatedFieldsMap, Map<String, String> customParameterMap, Sobject o, Boolean isUrlEncode){//1.7~
        if (formatStringArguments.isEmpty()) return '';//1.7~

        String formattedString='';
        Boolean isJSON=false;
        List<Object> formatParameters = new List<Object>();

        try {
    
            List<String> pathElements;
            String fv;
            String customParameterName;

            for (String fsa : formatStringArguments){//1.7~ -- each argument may be a field or a custom parameter.

                fv=null;//1.7+

                if (validFormatStringFields.contains(fsa.toUpperCase())){

                    try {
                        if (String.isNotBlank(fsa) && fsa.contains('.')){

                            pathElements = fsa.split('\\.');
                            Sobject p = o;

                            for (Integer n=0; n<pathElements.size();n++){
                                if (n==pathElements.size()-1){                                
                                    fv = p==null ? '' : getTypeFormattedValue(getSObjectTypeName(p.getSObjectType()),pathElements[n],p);
                                } else p = (pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2) ? p.getSObject(pathElements[n].split('\\|')[0]) : p.getSObject(pathElements[n]);
                            }
                        } else fv = String.isNotBlank(fsa) && populatedFieldsMap.containsKey(fsa) ? getTypeFormattedValue(getSObjectTypeName(o.getSObjectType()),fsa,o) : '';

                        if(isUrlEncode) fv = EncodingUtil.urlEncode(fv, 'UTF-8');
                        formatParameters.add(fv);

                    } catch(Exception e){ formatParameters.add(''); }
                
                } else {

                    customParameterName = fsa.removeStart('[').removeEnd(']').toUpperCase();
                    if (customParameterMap.containsKey(customParameterName)) fv = customParameterMap.get(customParameterName);
                    formatParameters.add(fv==null ? '' : fv);//1.7~ -- use an empty string to maintain the sequence where no value can be found for the custom parameter.
                }
            }
            formattedString = getJSONSafeFormatString(formatString,formatParameters);

        } catch(Exception ex){ Golfbreaks.PlatformLogManager.logExceptions(ex, 'AutoReplyMessageAction', 'formatString');}
        return formattedString;
    }

    private static String getJSONSafeFormatString(String formatString, List<Object> formatParameters){
        String formattedString='',jsonSafeFormatString='';

        try {
            for (Integer i=0; i<formatString.length(); i++){// escape { not succeeded by a numeric char, or } not preceded by a numeric char.
                if (formatString.substring(i,i+1)=='{'){
            
                    if (i==formatString.length()-1 || !formatString.substring(i+1,i+2).isNumeric()){
                        jsonSafeFormatString+='\'{\'';
                    } else jsonSafeFormatString+='{';                    
                } else if (formatString.substring(i,i+1)=='}'){
            
                    if (i==0 || !formatString.substring(i-1,i).isNumeric() && formatString.substring(i-1,i)!='}'){
                        jsonSafeFormatString+='\'}\'';
                    } else jsonSafeFormatString+='}';
                } else jsonSafeFormatString+=formatString.substring(i,i+1); 
            }            
            formattedString = String.format(jsonSafeFormatString,formatParameters);// - 'Hello {0} from {1}.'=>'John','London'.

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'AutoReplyMessageAction', 'getJSONSafeFormatString'); }
        return formattedString;
    }

    private static String getTypeFormattedValue(String sObjectTypeName, String f, SObject o){
        
        if (!o.getPopulatedFieldsAsMap().containsKey(f)) return '';

        Schema.DisplayType dt = getFieldDisplayType(sObjectTypeName, f);
        if (dt==null ) return '';
        else {
            
            switch on dt {
                when INTEGER {
                    Decimal d = (Decimal)o.get(f);
                    return String.valueOf(d.intValue());//1.0 => 1.
                }
                when DATE {
                    Date d = Date.valueOf(o.get(f));
                    Datetime convertedDt = Datetime.newInstance(d.year(), d.month(), d.day());
                    return convertedDt.format('yyyy-MM-dd');//<-- ISO format output.
                }
                when DATETIME {
                    DateTime valDT = DateTime.valueOf(o.get(f)); //Expected Format = 'yyyy-mm-dd hh:mm:ss'
                    return valDT.formatGMT('yyyy-MM-dd\'T\'HH:mm:ssXXX');//<-- ISO GMT format output.
                }
                when else {
                    return String.valueOf(o.get(f));
                }
            }
        }
    }
    // End Helper methods.

    // Members to be moved to a Helper class or SUP.

    private static Map<String, Map<String,Schema.SObjectField>> sotToFieldTokenMap = new Map<String, Map<String,Schema.SObjectField>>();
    private static Map<String, Map<String,List<String>>> sotToParentRelationshipMap = new Map<String, Map<String,List<String>>>();
    private static Map<String, Map<String,Schema.DisplayType>> sotToFieldTypeMap = new Map<String, Map<String,Schema.DisplayType>>();
    private static Map<Schema.SObjectType,String> sObjectTypeToName = new Map<Schema.SObjectType,String>();

    private static String getSObjectTypeName(Schema.SObjectType sObjectType){
        if (!sObjectTypeToName.containsKey(sObjectType)) sObjectTypeToName.put(sObjectType,sObjectType.getDescribe().getName());
        return sObjectTypeToName.get(sObjectType);
    }

    private static Map<String,Schema.SObjectField> getObjectFieldMap(String sObjectTypeName){

        if (!sotToFieldTokenMap.containsKey(sObjectTypeName)){
            Type t = Type.forName('',sObjectTypeName);
            if (t==null) return null;
            
            Schema.SObjectType sObjectType = ((SObject)t.newInstance()).getSObjectType();
            sotToFieldTokenMap.put(sObjectTypeName,sObjectType.getDescribe().fields.getMap());            
        }
        return sotToFieldTokenMap.get(sObjectTypeName);
    }    

    public static Schema.DisplayType getFieldDisplayType(String sObjectTypeName, String fieldName){

        if (sotToFieldTypeMap.containsKey(sObjectTypeName) && sotToFieldTypeMap.get(sObjectTypeName).containsKey(fieldName)) return sotToFieldTypeMap.get(sObjectTypeName).get(fieldName);
        if (!sotToFieldTokenMap.containsKey(sObjectTypeName)) getObjectFieldMap(sObjectTypeName);
        if (sotToFieldTokenMap==null || !sotToFieldTokenMap.containsKey(sObjectTypeName) || !sotToFieldTokenMap.get(sObjectTypeName).containsKey(fieldName)) return null;

        Schema.DescribeFieldResult fd =  sotToFieldTokenMap.get(sObjectTypeName).get(fieldName).getDescribe();

        if (!sotToFieldTypeMap.containsKey(sObjectTypeName)) sotToFieldTypeMap.put(sObjectTypeName, new Map<String,Schema.DisplayType>());
        sotToFieldTypeMap.get(sObjectTypeName).put(fieldName,fd.getType());

        return fd.getType();
    }
  
	public static Map<String,List<String>> getObjectParentRelationshipMap(String sObjectTypeName){
        if (sotToParentRelationshipMap.containsKey(sObjectTypeName)) return sotToParentRelationshipMap.get(sObjectTypeName);

        sotToParentRelationshipMap.put(sObjectTypeName, new Map<String,List<String>>());

        Schema.DescribeFieldResult fd;
        for (Schema.SObjectField f : getObjectFieldMap(sObjectTypeName).values()){
            try{
                fd = f.getDescribe();
            } catch(Exception e){ continue; }
            if (fd.getType()!=Schema.Displaytype.Reference) continue;

            sotToParentRelationshipMap.get(sObjectTypeName).put(fd.getRelationshipName(),new List<String>());

            for(Schema.sObjectType refToSOT : fd.getReferenceTo()){ sotToParentRelationshipMap.get(sObjectTypeName).get(fd.getRelationshipName()).add(refToSOT.getDescribe().getName()); }
        }
        return sotToParentRelationshipMap.get(sObjectTypeName);
    }    
    // End Members to be moved to a Helper class or SUP.
}