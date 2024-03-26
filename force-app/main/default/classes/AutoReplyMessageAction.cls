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
1.3  J Radcliffe  2024-02-05  Bug Fixes. a. Default null booleans to false. b. channelToAutoReplyConfigurations instantiate with String key (instead of Id) c. Null check before for loop. d. messagingTemplateIdToConversationIds & idToMessagingTemplate maps instantiate with String key (instead of Id)
1.4  J Radcliffe  2024-02-06  Enhancements. messagingTemplateId should be the UID__c not SFId.  
1.5  J Radcliffe  2024-02-06  Enhancements. add support for new template type: NewConversationTemplate__c
1.6  J Radcliffe  2024-02-06  Asorted Bug Fixes.
*/
public with sharing class AutoReplyMessageAction {

    @InvocableMethod
    public static List<ActionResult> getAutoReplyMessage(List<ActionRequest> requests){

        Map<Integer,ActionResult> seqToResult = new Map<Integer,ActionResult>();

        try {
            Integer seq=0;
            Map<Integer,ActionRequest> seqToRequest = new Map<Integer,ActionRequest>();
            Map<Id,Conversation__c> idToConversation = new Map<Id,Conversation__c>();
            
            Map<String,Id> businessUnitDeveloperNameToId = new Map<String,Id>();
            Map<Id,Golfbreaks_Business_Unit__c> idToBusinessUnit = new Map<Id,Golfbreaks_Business_Unit__c>([select Id, DeveloperName__c from Golfbreaks_Business_Unit__c]);
            
            Set<String> messagingChannelDeveloperNames = new Set<String>(), messagingTemplateIds = new Set<String>();//1.2~
            Map<Id,MessagingChannel__mdt> idToMessagingChannel = new Map<Id,MessagingChannel__mdt>([select Id, DeveloperName from MessagingChannel__mdt]);   
            
            Map<String,MessagingChannel__mdt> developerNameToMessagingChannel = new Map<String,MessagingChannel__mdt>();//1.2+
            for (MessagingChannel__mdt mc : idToMessagingChannel.values()){ developerNameToMessagingChannel.put(mc.DeveloperName,mc); }//1.2+

            for(ActionRequest request : requests){
                seq++;
                seqToRequest.put(seq,request);    
                seqToResult.put(seq,new ActionResult(request.conversationId));   

                if (request.conversationRecord!=null) idToConversation.put(request.conversationId,request.conversationRecord);//1.1~
                
                if  (request.messagingTemplateId==null || String.isBlank(request.messagingTemplateId)){

                    //1.3a+
                    if(request.isUnrecognisedCustomer == null) request.isUnrecognisedCustomer = false;
                    if(request.isHighVolume == null) request.isHighVolume = false;
                    if(request.isAgentUnavailable == null) request.isAgentUnavailable = false;
                    if(request.isOutsideBusinessHours == null) request.isOutsideBusinessHours = false;
                    if(request.isNew == null) request.isNew = false;//1.5+

                    if (String.IsBlank(request.businessUnitId) || !idToBusinessUnit.containsKey(request.businessUnitId)){
                        seqToResult.get(seq).isSuccess = false;
                        seqToResult.get(seq).errorMessage = 'Invalid Business Unit Id';
                        continue;

                    } else if (!businessUnitDeveloperNameToId.containsKey(idToBusinessUnit.get(request.businessUnitId).DeveloperName__c)) businessUnitDeveloperNameToId.put(idToBusinessUnit.get(request.businessUnitId).DeveloperName__c,request.businessUnitId); system.debug('adding bu > '+idToBusinessUnit.get(request.businessUnitId).DeveloperName__c);

                    if (String.IsBlank(request.messagingChannel) || !developerNameToMessagingChannel.containsKey(request.messagingChannel)){//1.2~
                        seqToResult.get(seq).isSuccess = false;
                        seqToResult.get(seq).errorMessage = 'Invalid Messaging Channel';
                        continue;
                    } else messagingChannelDeveloperNames.add(request.messagingChannel); system.debug('adding channel > '+request.messagingChannel);

                    if (!request.isUnrecognisedCustomer && !request.isHighVolume && !request.isAgentUnavailable && !request.isOutsideBusinessHours && !request.isNew){//1.5~
                        seqToResult.get(seq).isSuccess = false;
                        seqToResult.get(seq).errorMessage = 'Missing Auto Reply Type Flag';
                        continue;
                    }
                    system.debug('passed type check :)');
                
                } else messagingTemplateIds.add(request.messagingTemplateId);
            }

            system.debug('messagingTemplateIds.isEmpty() '+messagingTemplateIds.isEmpty());
            system.debug('businessUnitDeveloperNameToId.isEmpty() '+businessUnitDeveloperNameToId.isEmpty());
            system.debug('messagingChannelDeveloperNames.isEmpty() '+messagingChannelDeveloperNames.isEmpty());

            if (messagingTemplateIds.isEmpty() && businessUnitDeveloperNameToId.isEmpty() && messagingChannelDeveloperNames.isEmpty()) return seqToResult.values();//1.2~
            
            Map<Id, List<AutoReplyConfiguration__mdt>> businessUnitIdToAutoReplyConfigurations = new Map<Id, List<AutoReplyConfiguration__mdt>>();
            Map<String, List<AutoReplyConfiguration__mdt>> channelToAutoReplyConfigurations = new Map<String, List<AutoReplyConfiguration__mdt>>();//1.3b~

            if (!messagingChannelDeveloperNames.isEmpty()){//1.2~

                Id businessUnitId;                
                for (AutoReplyConfiguration__mdt arc : [select Id,DeveloperName,
                                                            MessagingChannel__c,MessagingChannel__r.DeveloperName,
                                                            BusinessUnitDeveloperName__c,WorkItemType__c,
                                                            AgentUnavailableTemplate__c,
                                                            OutsideBusinessHoursTemplate__c,
                                                            HighVolumeTemplate__c,
                                                            UnrecognisedCustomerTemplate__c,

                                                            //1.6+
                                                            HighVolumeAutoRepliesForUpdates__c,
                                                            HighVolumeAutoRepliesForNew__c,
                                                            
                                                            //1.4+
                                                            AgentUnavailableTemplate__r.UID__c,
                                                            OutsideBusinessHoursTemplate__r.UID__c,
                                                            HighVolumeTemplate__r.UID__c,
                                                            UnrecognisedCustomerTemplate__r.UID__c,
                                                            NewConversationTemplate__r.UID__c //1.5+

                                                        from AutoReplyConfiguration__mdt
                                                        where MessagingChannel__r.DeveloperName in:messagingChannelDeveloperNames]){

                    if (String.isNotBlank(arc.BusinessUnitDeveloperName__c) && !businessUnitDeveloperNameToId.isEmpty() && businessUnitDeveloperNameToId.containsKey(arc.BusinessUnitDeveloperName__c)){//1.6~
                        businessUnitId = businessUnitDeveloperNameToId.get(arc.BusinessUnitDeveloperName__c);
                        if (!businessUnitIdToAutoReplyConfigurations.containsKey(businessUnitId)) businessUnitIdToAutoReplyConfigurations.put(businessUnitId,new List<AutoReplyConfiguration__mdt>());                
                        businessUnitIdToAutoReplyConfigurations.get(businessUnitId).add(arc);
                        System.debug('businessUnitIdToAutoReplyConfigurations > '+businessUnitIdToAutoReplyConfigurations);
                    
                    } else {

                        if (!channelToAutoReplyConfigurations.containsKey(arc.MessagingChannel__r.DeveloperName)) channelToAutoReplyConfigurations.put(arc.MessagingChannel__r.DeveloperName,new List<AutoReplyConfiguration__mdt>());                
                        channelToAutoReplyConfigurations.get(arc.MessagingChannel__r.DeveloperName).add(arc);
                    }
                }
            }

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
                for (AutoReplyConfiguration__mdt arc : businessUnitIdToAutoReplyConfigurations.get(request.businessUnitId)){// -- Business Unit
                    if (!arc.MessagingChannel__r.DeveloperName.equalsIgnoreCase(request.messagingChannel)) continue;//1.6~
                    if (!checkAutoReplyConfiguration(arc,request)) continue;

                    if (String.IsNotBlank(arc.WorkItemType__c)
                        && ((arc.WorkItemType__c=='Booking' && request.bookingId!=null)
                            || (arc.WorkItemType__c=='Case' && request.caseId!=null)
                            || (arc.WorkItemType__c=='Opportunity' && request.opportunityId!=null))){

                        seqToResult.get(rseq).messagingTemplateId = getTemplateId(arc,request);                  
                        break;                    
                    }
                }
                
                if (seqToResult.get(rseq).messagingTemplateId!=null){
                    messagingTemplateIds.add(seqToResult.get(rseq).messagingTemplateId);
                    break;
                }

                //Channel+Work Item Type
                if(channelToAutoReplyConfigurations != null && channelToAutoReplyConfigurations.containsKey(request.messagingChannel)){//1.3c+
                    for (AutoReplyConfiguration__mdt arc : channelToAutoReplyConfigurations.get(request.messagingChannel)){// -- Channel
                        if (!checkAutoReplyConfiguration(arc,request)) continue;

                        if (String.IsNotBlank(arc.WorkItemType__c)
                            && ((arc.WorkItemType__c=='Booking' && request.bookingId!=null)
                                || (arc.WorkItemType__c=='Case' && request.caseId!=null)
                                || (arc.WorkItemType__c=='Opportunity' && request.opportunityId!=null))){

                            seqToResult.get(rseq).messagingTemplateId = getTemplateId(arc,request);      
                            break;                    
                        }
                    }
                }

                if (seqToResult.get(rseq).messagingTemplateId!=null){
                    messagingTemplateIds.add(seqToResult.get(rseq).messagingTemplateId);
                    break;
                }
                
                //Channel+BU
                for (AutoReplyConfiguration__mdt arc : businessUnitIdToAutoReplyConfigurations.get(request.businessUnitId)){// -- Business Unit
                    if (arc.MessagingChannel__r.DeveloperName.equalsIgnoreCase(request.messagingChannel)) continue;
                    if (!checkAutoReplyConfiguration(arc,request)) continue;

                    if (String.IsBlank(arc.WorkItemType__c)){  
                                
                        seqToResult.get(rseq).messagingTemplateId = getTemplateId(arc,request);
                        break;
                    }
                }
                
                if (seqToResult.get(rseq).messagingTemplateId!=null){
                    messagingTemplateIds.add(seqToResult.get(rseq).messagingTemplateId);
                    break;
                }

                //Channel
                if(channelToAutoReplyConfigurations != null && channelToAutoReplyConfigurations.containsKey(request.messagingChannel)){//1.3c+
                    for (AutoReplyConfiguration__mdt arc : channelToAutoReplyConfigurations.get(request.messagingChannel)){// -- Channel
                        if (arc.MessagingChannel__r.DeveloperName.equalsIgnoreCase(request.messagingChannel)) continue;
                        if (!checkAutoReplyConfiguration(arc,request)) continue;

                        seqToResult.get(rseq).messagingTemplateId = getTemplateId(arc,request);        
                        break;
                    }  
                }
                
                if (seqToResult.get(rseq).messagingTemplateId!=null) messagingTemplateIds.add(seqToResult.get(rseq).messagingTemplateId);
            }

            //1.3d~
            //Map<Id,MessagingTemplate__mdt> idToMessagingTemplate = new Map<Id,MessagingTemplate__mdt>([select Id,MessageFormat__c,MessageFormatFields__c from MessagingTemplate__mdt where Id in:messagingTemplateIds]);
            Map<String,MessagingTemplate__mdt> idToMessagingTemplate = new Map<String,MessagingTemplate__mdt>();
            for(MessagingTemplate__mdt mt : [select Id,DeveloperName,MessageFormat__c,MessageFormatFields__c from MessagingTemplate__mdt where UID__c in:messagingTemplateIds]){//1.4~
                idToMessagingTemplate.put(mt.DeveloperName,mt);
            }
            
            Map<String,Set<Id>> messagingTemplateIdToConversationIds = new Map<String,Set<Id>>();//1.3d~
            
            for (ActionResult result : seqToResult.values()){
                system.debug('RESULT > '+result);
                if (!messagingTemplateIdToConversationIds.containsKey(result.messagingTemplateId)) messagingTemplateIdToConversationIds.put(result.messagingTemplateId,new Set<Id>());
                messagingTemplateIdToConversationIds.get(result.messagingTemplateId).add(result.conversationId);                                
            }

            Map<Id,String> recordIdToMessage = new Map<Id,String>();
            Map<Id,String> allRecordIdToMessage = new Map<Id,String>();

            for (String messagingTemplateId : messagingTemplateIdToConversationIds.keySet()){//1.3d~       
                recordIdToMessage = buildMessagesForMessagingTemplate(idToMessagingTemplate.get(messagingTemplateId), messagingTemplateIdToConversationIds.get(messagingTemplateId), idToConversation, 'Conversation__c');
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

        @InvocableVariable(label='Messaging Channel' required=false)
        public String messagingChannel;

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
    }

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

        if (request.isAgentUnavailable && arc.AgentUnavailableTemplate__c==null) return false;
        if (request.isHighVolume && (arc.HighVolumeTemplate__c==null || (request.isNew && !arc.HighVolumeAutoRepliesForNew__c) || (!request.isNew && !arc.HighVolumeAutoRepliesForUpdates__c))) return false;//1.1~
        if (request.isOutsideBusinessHours && arc.OutsideBusinessHoursTemplate__c==null) return false;
        if (request.isUnrecognisedCustomer && arc.UnrecognisedCustomerTemplate__c==null) return false;
        if (request.isNew && arc.NewConversationTemplate__c==null) return false;//1.5+
        return true;
    }

    private static String getTemplateId(AutoReplyConfiguration__mdt arc, ActionRequest request){

        //1.4~
        if (request.isAgentUnavailable) return arc.AgentUnavailableTemplate__r.UID__c;
        if (request.isHighVolume) return arc.HighVolumeTemplate__r.UID__c;
        if (request.isOutsideBusinessHours) return arc.OutsideBusinessHoursTemplate__r.UID__c;
        if (request.isUnrecognisedCustomer) return arc.UnrecognisedCustomerTemplate__r.UID__c;
        if (request.isNew) return arc.NewConversationTemplate__r.UID__c;//1.5+
        return null;
    }

    public static Map<Id,String> buildMessagesForMessagingTemplate(MessagingTemplate__mdt mt, Set<Id> recordIds, Map<Id,Conversation__c> idToConversation, String sObjectTypeName){

        Map<Id,String> recordIdToMessage = new Map<Id,String>();

        try {
            if (mt==null || recordIds==null || recordIds.isEmpty() || String.isBlank(sObjectTypeName)) return recordIdToMessage;
            
            Type t = Type.forName('Schema',sObjectTypeName);
            if (t==null) return recordIdToMessage;
            
            Schema.SObjectType sObjectType = ((SObject)t.newInstance()).getSObjectType();
                        
            String idFieldName = 'Id';
            
            List<String> formatStringFields = new List<String>();
            if(mt.MessageFormatFields__c != null){//1.6+
                if (String.isNotBlank(mt.MessageFormatFields__c)) formatStringFields.addAll( mt.MessageFormatFields__c.deleteWhitespace().split(',') );
                if (formatStringFields.isEmpty()) return recordIdToMessage;
            }else{//1.6+
                for(Id recordId : recordIds){
                    recordIdToMessage.put(recordId,mt.MessageFormat__c);
                }
                return recordIdToMessage;
            }

            Boolean isIdFieldOnly = formatStringFields.size()==1 && (new List<String>(formatStringFields)[0].equalsIgnoreCase('Id')) ? true : false;

            Sobject o;
            Map<Id,Sobject> idToSObject;
            Set<String> fieldsAdded = new Set<String>();
            
            if(isIdFieldOnly){                
                idToSObject = new Map<Id,Sobject>();

                for (Id recordId : recordIds){ 
                    o = sObjectType.newSObject();
                    o.put(idFieldName,recordId);
                    idToSObject.put(recordId,o);
                }
                fieldsAdded.add(idFieldName.toUpperCase());

            } else {

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

            for (Id recordId : idToSObject.keySet()){            
                o = idToSObject.get(recordId);
                fieldsMap = new Map<String,Object>(o.getPopulatedFieldsAsMap());//1.6~

                if (idToConversation.containsKey(recordId) && !idToConversation.get(recordId).getPopulatedFieldsAsMap().isEmpty()) fieldsMap.putAll(idToConversation.get(recordId).getPopulatedFieldsAsMap());//1.1~

                recordIdToMessage.put(recordId,formatString(fieldsAdded,formatStringFields,mt.MessageFormat__c,fieldsMap,o,false));
            }//recordId.

        } catch(Exception ex){ Golfbreaks.PlatformLogManager.logExceptions(ex, 'AutoReplyMessageAction', 'buildMessagesForMessagingTemplate'); }
        return recordIdToMessage;
    }    

    private static String formatString(Set<String> validFormatStringFields, List<String> formatStringFields, String formatString, Map<String, Object> populatedFieldsMap, Sobject o, Boolean isUrlEncode){
        if (validFormatStringFields.isEmpty()) return '';

        String formattedString='';
        Boolean isJSON=false;
        List<Object> formatParameters = new List<Object>();

        try {
    
            List<String> pathElements;
            String fv;

            for (String f : formatStringFields){

                if (!validFormatStringFields.contains(f.toUpperCase())) continue;

                try {
                    if (String.isNotBlank(f) && f.contains('.')){

                        pathElements = f.split('\\.');
                        Sobject p = o;

                        for (Integer n=0; n<pathElements.size();n++){
                            if (n==pathElements.size()-1){                                
                                fv = p==null ? '' : getTypeFormattedValue(getSObjectTypeName(p.getSObjectType()),pathElements[n],p);
                            } else p = (pathElements[n].contains('|') && pathElements[n].split('\\|').size()==2) ? p.getSObject(pathElements[n].split('\\|')[0]) : p.getSObject(pathElements[n]);
                        }
                    } else fv = String.isNotBlank(f) && populatedFieldsMap.containsKey(f) ? getTypeFormattedValue(getSObjectTypeName(o.getSObjectType()),f,o) : '';

                    if(isUrlEncode) fv = EncodingUtil.urlEncode(fv, 'UTF-8');
                    formatParameters.add(fv);
                        
                } catch(Exception e){ formatParameters.add(''); }
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
            formattedString = String.format(jsonSafeFormatString,formatParameters);

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
            Type t = Type.forName('Schema',sObjectTypeName);
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