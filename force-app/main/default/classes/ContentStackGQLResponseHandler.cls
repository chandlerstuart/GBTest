/*
Name:  ContentStackGQLResponseHandler.cls
Copyright © 2021  Golfbreaks
======================================================
======================================================
Purpose:
-------
Response handler responsible for reshaping data returned
from content stack and populating the local content cache
(Generic Content & Generic Content Items Objects)
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-07-12  Initial development.
1.1  Mark Cane     2021-09-14  Enhancement. Support for child=>Parent relationships via Generic Content Reference.
1.2  Mark Cane     2021-09-15  Enhancement. Connection name prefix added to node level attributes.
1.3  Mark Cane     2021-09-20  Enhancement. Remove references from parent level cached content.
1.4  J Radcliffe   2021-10-22  Bug Fix. Replace content body references of ’ with '
1.5  Mark Cane&    2021-10-27  Bug fixes. Fix to exception where assumed system=>uid map does not exist for child entries (i.e. Venue).
1.6  J Radcliffe   2021-12-03  Enhancement. Replacing insert with upsert - Updating content reserved because it is referenced by Email Content Configuration (object)
1.7  Mark Cane&    2021-12-15  Enhancement. Location Type cache extension.
1.8  Mark Cane&    2021-12-23  Enhancement. Salesforce Id cache extension.
1.9  Mark Cane&    2022-01-16  WIP Enhancement. Content Type Field Mapping support.
1.10 Mark Cane&    2022-01-20  Bug fixes. Data Type Cast for Content Type Field Mappings.
1.11 Mark Cane&    2022-03-09  Bug fixes. W-001932.
1.12 J Radcliffe   2022-06-06  Bug fixes. Allow for blank parsing instructions (accept response body as is)
1.13 J Radcliffe   2022-06-06  Enhancement. Copy Locale (to Generic Content) from corresponding Content Stack Content Configuration for global email personalisation
1.14 Mark Cane&    2023-08-21  Note. Addeded explicit field truncation=false to dml operations to ensure truncate errors are reported.
1.15 Mark Cane&    2024-03-07  Enhancement. GQLFilterInstructions__c.
1.16 Mark Cane&    2024-03-20  Enhancement. GQLFilterInstructions__c Sub-filter support.
*/
global with sharing class ContentStackGQLResponseHandler implements IDataEventTypeResponseHandler2 {

    @TestVisible public static Map<String,String> connectionNameToParsingInstructions = new Map<String,String>();
    @TestVisible public static Map<String,String> listNameToCachingInstructions = new Map<String,String>();
    @TestVisible public static Map<String,String> listNameToFilterInstructions = new Map<String,String>();//1.15+
    @TestVisible public static List<ContentTypeFieldMapping__mdt> contentTypeFieldMappings = new List<ContentTypeFieldMapping__mdt>();//1.9+

    private static final String genericListType = 'Generic List';
    private static Schema.DescribeSObjectResult genericContentObjDescribe;//1.9+

    global Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId){
        try {

            //Lookup parsing instructions (Outbound Callout > DET > Content Stack Type)
            if(outboundCalloutId==null) return false;//Return failure - OC is expected by this handler

            OutboundCallout__c oc = [select Id, DataEventType__c from OutboundCallout__c where Id=:outboundCalloutId];
            
            ContentStackContentType__mdt csct = [select Id, ContentType__c, Locale__c, ContentSubtype__c, GQLParsingInstructions__c, GQLCachingInstructions__c, GQLFilterInstructions__c,//1.15~ 1.13~ Locale__c
                                                        (select Id, MasterLabel, DeveloperName, FieldName__c, FieldValuePath__c from ContentTypeFieldMappings__r)
                                                    from ContentStackContentType__mdt where DataEventType__r.DeveloperName=:oc.DataEventType__c];//1.9~

            List<String> connectionInstructions, filterInstructions;//1.15~

            if(csct.GQLParsingInstructions__c != null){//1.12+
                for (String pi : csct.GQLParsingInstructions__c.split('\\|')){ 
                    connectionInstructions = pi?.split(',');
                    if (connectionInstructions.size()<2) continue;
        
                    connectionNameToParsingInstructions.put(connectionInstructions[0], connectionInstructions[1]);
                }
            }

            Object o = (csct.GQLParsingInstructions__c != null)?parseObject(JSON.deserializeUntyped(r.getBody())):JSON.deserializeUntyped(r.getBody());//Reshape and return JSON response //1.12~ 

            String c;
            for (String ci : csct.GQLCachingInstructions__c.split('\\|')){ 

                connectionInstructions = ci.split(',');
                if (connectionInstructions.size()<2) continue;
    
                c = connectionInstructions[1];
                if (connectionInstructions.size()>=3) c+=','+connectionInstructions[2];
                if (connectionInstructions.size()==4) c+=','+connectionInstructions[3];
    
                listNameToCachingInstructions.put(connectionInstructions[0],c);
            }

            String f;
            if (String.isNotBlank(csct.GQLFilterInstructions__c)){// -- items,,~promotions.offers[visible_to][<=][TODAY]|items2...

                for (String fi : csct.GQLFilterInstructions__c.split('\\|')){//1.15+ -- filters for specific lists are pipe delimited.

                    filterInstructions = fi.split(',');// -- listName,parentFilter,childFilter
                    if (filterInstructions.size()<2) continue;
        
                    f = filterInstructions[1];
                    if (filterInstructions.size()==3) f+=','+filterInstructions[2];
        
                    listNameToFilterInstructions.put(filterInstructions[0],f);
                }
            }

            //List contains three maps (All Maps use the Generic Content Id as the key):
            List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();            
            //[0] = Generic Content Map
            cacheData.add(new Map<String,List<SObject>>());
             //[1] = Generic Content Item Map
            cacheData.add(new Map<String,List<SObject>>());
             //[2] = Generic Content Reference Map
            cacheData.add(new Map<String,List<SObject>>());

            cacheData = parseToCacheObject(o,cacheData,csct);

            //1.6+
            Set<Id> defaultsAndOverrideContentIds = new Set<Id>();
            for(EmailContentConfiguration__c config : [Select DefaultContent__c, ContentOverride__c From EmailContentConfiguration__c]){
                if(config.DefaultContent__c != null && !defaultsAndOverrideContentIds.contains(config.DefaultContent__c)) defaultsAndOverrideContentIds.add(config.DefaultContent__c);
                if(config.ContentOverride__c != null && !defaultsAndOverrideContentIds.contains(config.ContentOverride__c)) defaultsAndOverrideContentIds.add(config.ContentOverride__c);
            }
            Map<String,GenericContent__c> defaultAndOverrideContentDataMap = new Map<String,GenericContent__c>();
            String contentKey;//<-- ContentStackId-Type-Subtype
            for(GenericContent__c content : [Select Id, ContentId__c, ContentType__c, ContentSubtype__c From GenericContent__c Where Id In:defaultsAndOverrideContentIds]){//Retrieved records retained because they are referenced by email config setting (for update)
                contentKey = content.ContentId__c+'-'+content.ContentType__c+'-'+content.ContentSubtype__c;
                defaultAndOverrideContentDataMap.put(contentKey,content);
            }

            Map<String,SObject> genericContentUpsertMap = new Map<String,SObject>();
            for(String contentId : cacheData[0].keySet()){
                //Only add to cache if it is a list with items or not a list
                if(csct.ContentType__c!=genericListType ||
                    (cacheData[1].containsKey(contentId) && cacheData[1].get(contentId)!=null && cacheData[1].get(contentId).size()>0 )){
                    //1.6+ Add Id to SObject if the record is identified as one of the existing records
                    SObject record = cacheData[0].get(contentId)[0];
                    if(defaultAndOverrideContentDataMap.containsKey(record.get('ContentId__c')+'-'+record.get('ContentType__c')+'-'+record.get('ContentSubtype__c'))){
                        record.put('Id',defaultAndOverrideContentDataMap.get(record.get('ContentId__c')+'-'+record.get('ContentType__c')+'-'+record.get('ContentSubtype__c')).Id);
                    }
                    //genericContentUpsertMap.put(contentId,cacheData[0].get(contentId)[0]); 1.6-
                    genericContentUpsertMap.put(contentId,record);//1.6+
                }
            }

			Database.DMLOptions dmo = new Database.DMLOptions();//1.14+
			dmo.allowFieldTruncation = false;//1.14+ -- do not truncate oversized text data, report field truncation exceptions. Truncation may cause content cache mismatches.
			dmo.optAllOrNone=false;//1.14+

            //Database.SaveResult[] results = Database.insert(genericContentUpsertMap.values(),false);//1.6- all or none is false (better to have some than none), but we need to log failures FAO tech team
            Database.UpsertResult[] upsertResults = Database.upsert(genericContentUpsertMap.values(),false);//1.6+
            Golfbreaks.PlatformLogManager.logExceptions(upsertResults,'ContentStackGQLResponseHandler', 'handleOutboundResponse', genericContentUpsertMap.values());
            
            List<SObject> genericContentItemsForInsert = new List<SObject>();

            Database.SaveResult[] results;
            if(cacheData[1]!=null && cacheData[1].values()!=null && cacheData[1].values().size()>0 && cacheData[1].values()[0].size()>0){
                for(String contentId : cacheData[1].keySet()){
                    if(genericContentUpsertMap.containsKey(contentId) && genericContentUpsertMap.get(contentId)!=null
                        && genericContentUpsertMap.get(contentId).get('Id')!=null){
                        
                        for(SObject item : cacheData[1].get(contentId)){
                            item.put('GenericContent__c',genericContentUpsertMap.get(contentId).get('Id'));
                            genericContentItemsForInsert.add(item);
                        }
                    }
                }
                results = Database.insert(genericContentItemsForInsert,dmo);//1.14~ -- all or none is false (better to have some than none), but we need to log failures FAO tech team
                Golfbreaks.PlatformLogManager.logExceptions(results,'ContentStackGQLResponseHandler', 'handleOutboundResponse', genericContentItemsForInsert);
            }

            List<SObject> genericContentReferencesForInsert = new List<SObject>();//1.1+

            if(cacheData[2]!=null && cacheData[2].values()!=null && cacheData[2].values().size()>0 && cacheData[2].values()[0].size()>0){
                for(String contentId : cacheData[2].keySet()){
                    if(genericContentUpsertMap.containsKey(contentId) && genericContentUpsertMap.get(contentId)!=null
                        && genericContentUpsertMap.get(contentId).get('Id')!=null){
                        
                        for(SObject item : cacheData[2].get(contentId)){
                            item.put('GenericContent__c',genericContentUpsertMap.get(contentId).get('Id'));
                            genericContentReferencesForInsert.add(item);
                        }
                    }
                }
                results = Database.insert(genericContentReferencesForInsert,dmo);//1.14~ -- all or none is false (better to have some than none), but we need to log failures FAO tech team
                Golfbreaks.PlatformLogManager.logExceptions(results,'ContentStackGQLResponseHandler', 'handleOutboundResponse', genericContentReferencesForInsert);
            }
            return true;

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'ContentStackGQLResponseHandler','handleOutboundResponse');
            return false;
        }
    }

    public static Object parseObject(Object o){//<-- method is called recursively to traverse the hierarchical JSON structure.

        if (o instanceof Map<String,Object>){
            // -- [removed for release] System.debug(LoggingLevel.ERROR,'Parse Map object='+o);

            Map<String,Object> currentMap = (Map<String,Object>)o;
            String connectionName;//1.2+
    
            for (String k : currentMap.keySet().clone()){

                if (currentMap.get(k) instanceof Map<String,Object> 
                        && k.endswith('Connection')
                        && connectionNameToParsingInstructions.containsKey(k)){

                    connectionName = k.removeEnd('Connection');//1.2+

                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'Connection Map Found='+k);
                    parseObject(currentMap.get(k));         
                    
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'Connection Map Processing Start='+currentMap);

                    Map<String,Object> connectionMap = (Map<String,Object>)currentMap.get(k);

                    currentMap.remove(k);
                    
                    if (connectionMap.containsKey('edges') && connectionMap.get('edges') instanceof List<Object>){//<-- parsing is GraphQL specific so literal reference to edges is ok.
                        List<Object> edgesList = (List<Object>)connectionMap.get('edges');

                        connectionMap.remove('edges');

                        if (connectionNameToParsingInstructions.get(k).equalsIgnoreCase('promote')){// Promote - the first node in the edges list without the node parent.

                            if (edgesList.size()>0){
                                Object e = edgesList[0];
                                
                                if (e instanceof Map<String,Object> && ((Map<String,Object>)e).containsKey('node')){//<-- parsing is GraphQL specific so literal reference to node is ok.
                                    e = ((Map<String,Object>)e).get('node');
                                }
                                Map<String,Object> nodeMap = (Map<String,Object>)e;//1.2+
                                for (String nma : nodeMap.keySet()){//1.2+

                                    if (nodeMap.get(nma) instanceof List<Object> || nodeMap.get(nma) instanceof Map<String,Object>){
                                        connectionMap.put(nma,nodeMap.get(nma));
                                    } else connectionMap.put(connectionName+'_'+nma,nodeMap.get(nma));                                    
                                }
                            }

                        } else {// Rename - the edges list, removing the node parent from each entry.
                            
                            Map<String,Object> innerMap;
                            
                            for (Object e : edgesList){
                         
                                innerMap = (Map<String,Object>)e;

                                if (innerMap.containsKey('node') && innerMap.get('node') instanceof Map<String,Object>){
                                    Map<String,Object> n = (Map<String,Object>)innerMap.get('node');
                                    
                                    innerMap.remove('node');
                                    innerMap.putAll(n);
                                }
                            }
                            connectionMap.put(connectionNameToParsingInstructions.get(k).removeStart('rename=>'),edgesList);                    
                        }

                        currentMap.putAll(connectionMap);

                        // -- [removed for release] System.debug(LoggingLevel.ERROR,'Connection Map Processing End='+currentMap);
                    }                

                } else if (currentMap.get(k) instanceof Map<String,Object>){
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'Map Found='+k);
                    parseObject(currentMap.get(k));

                } else if (currentMap.get(k) instanceof List<Object>){
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'List Found='+k);
                    for (Object o2 : (List<Object>)currentMap.get(k)){  parseObject(o2); }

                } else {
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'Attribute Found='+k+'=>'+currentMap.get(k));                
                }
            }
    
        } else if (o instanceof List<Object>){
            // -- [removed for release] System.debug(LoggingLevel.ERROR,'Parse List object='+o);

            for (Object o2 : (List<Object>)o){ parseObject(o2); }
        
        } else {
            // -- [removed for release] System.debug(LoggingLevel.ERROR,'Unknown Found='+o);
        }
        return o;
    }

    public static List<Map<String,List<SObject>>> parseToCacheObject(Object o, List<Map<String,List<SObject>>> cacheData, ContentStackContentType__mdt csct){//<-- method is called recursively to traverse the hierarchical JSON structure.        
        
        if (o instanceof Map<String,Object>){
            // -- [removed for release] System.debug(LoggingLevel.ERROR,'Parse Map object='+o);

            Map<String,Object> currentMap = (Map<String,Object>)o;
            
            Map<String,Object> itemMap = new Map<String,Object>(), subItemMap = new Map<String,Object>();//1.1+
            Map<String,Object> childItemMap = new Map<String,Object>(), childSubItemMap = new Map<String,Object>();//1.15+

            String idAttribute,salesforceIdAttribute,nameAttribute,typeAttribute,filterAttribute,childListPath,referenceListPath;//1.15~ 1.1+ 1.7~ 1.8~            
            String idValue,salesforceIdValue,nameValue,typeValue,filterOperator,filterValue,parentIdValue;//1.15~ 1.1+ 1.7~ 1.8~            
            String subFilterObject,subFilterList,subFilterAttribute,subFilterOperator,subFilterValue;//1.16+
            Object filterCheckValue;//1.15+
            String jsonBody;//1.4+
            List<String> cacheInstructionParts;//1.8+
            
            for (String k : currentMap.keySet().clone()){

                if (currentMap.get(k) instanceof List<Object> && listNameToCachingInstructions.containsKey(k)){

                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'List to Cache Found='+k);

                    //Example 1: items,system.uid=>title,,email_display_options=>references:system.uid=>full_name;location_name
                    //Key=items value="system.uid=>title,,email_display_options=>references:system.uid=>full_name;location_name"  
                    
                    //Example 2: items,uid=>location_name,overview=>venues
                    //Key=items value="uid=>location_name,overview=>venues"        
                    
                    //Example 3: items,uid=>location_name=>type,overview=>venues
                    //Key=items value="uid=>location_name=>type,overview=>venues"
                    
                    // Index 0 = Content Id => Name => Location Type => Salesforce Record Id
                    // Index 1 = Child List path
                    // Index 2 = Reference List path

                    cacheInstructionParts = listNameToCachingInstructions.get(k).split(',');//1.8+

                    idAttribute=null;
                    nameAttribute=null;
                    typeAttribute=null;//1.7+
                    salesforceIdAttribute=null;//1.8+
                    filterAttribute=null;//1.15+
                    filterOperator=null;//1.15+
                    filterValue=null;//1.15+
                    filterCheckValue=null;//1.15+                    
                    subFilterObject=null;//1.16+
                    subFilterList=null;//1.16+
                    subFilterAttribute=null;//1.16+
                    subFilterOperator=null;//1.16+
                    subFilterValue=null;//1.16+

                    if (cacheInstructionParts!=null && !cacheInstructionParts.isEmpty() && cacheInstructionParts[0].contains('=>')){//1.1+
                        idAttribute = cacheInstructionParts[0].split('=>')[0];
                        nameAttribute = cacheInstructionParts[0].split('=>')[1];
                        if (cacheInstructionParts[0].split('=>').size()==3) typeAttribute = String.isNotBlank(cacheInstructionParts[0].split('=>')[2]) ? cacheInstructionParts[0].split('=>')[2] : null;//1.7+
                        if (cacheInstructionParts[0].split('=>').size()==4) salesforceIdAttribute = String.isNotBlank(cacheInstructionParts[0].split('=>')[3]) ? cacheInstructionParts[0].split('=>')[3] : null;//1.8+
                        
                    } else {
                        idAttribute = 'system.uid';//no uid path set so apply default.
                        nameAttribute = cacheInstructionParts!=null && !cacheInstructionParts.isEmpty() ? cacheInstructionParts[0].split(',')[0] : null;//1.1+ 1.8~
                    }

                    if (listNameToFilterInstructions.containsKey(k)                        
                        && listNameToFilterInstructions.get(k).split(',')[0].split('~')[0].split('\\[').size()==4){//1.15+ 1.16~ -- Generic Content filter.

                        //GQLFilterInstructions__c: [listName],[GenericContentFilter],[GenericContentItemFilter]|[listName2],[GenericContentFilter2],[GenericContentItemFilter2]
                        //Filter Syntax: [property][operator][value],[property][operator][value]
                        //operators: = <> > < >= <= (Text: = <> Datetime: = <> > < >= <=)
                        //date filter value must be the relative value TODAY
                        //text filter values must be unquoted literals.
                        //E.g. promotions[visible_to][>=][TODAY],[venue.location][=][London]
                        //E.g. [system.uid][=][blt30139685d1bbcf4e]~promotions.offers[visible_to][<=][TODAY]                        
                        filterAttribute=listNameToFilterInstructions.get(k).split(',')[0].split('~')[0].split('\\[')[1].removeEnd(']');//1.16~
                        filterOperator=listNameToFilterInstructions.get(k).split(',')[0].split('~')[0].split('\\[')[2].removeEnd(']');//1.16~
                        filterValue=listNameToFilterInstructions.get(k).split(',')[0].split('~')[0].split('\\[')[3].removeEnd(']');//1.16~
                    } else {
                        filterAttribute=null;
                        filterOperator=null;
                        filterValue=null;
                    }

                    if (listNameToFilterInstructions.containsKey(k)
                        && listNameToFilterInstructions.get(k).split(',')[0].split('~').size()==2
                        && listNameToFilterInstructions.get(k).split(',')[0].split('~')[1].split('\\[').size()==4){//1.16+

                        subFilterList=listNameToFilterInstructions.get(k).split(',')[0].split('~')[1].split('\\[')[0].removeEnd(']');
                        if (subFilterList.split('\\.').size()==2){
                            subFilterObject = subFilterList.split('\\.')[0];
                            subFilterList = subFilterList.split('\\.')[1];
                        }
                        subFilterAttribute=listNameToFilterInstructions.get(k).split(',')[0].split('~')[1].split('\\[')[1].removeEnd(']');
                        subFilterOperator=listNameToFilterInstructions.get(k).split(',')[0].split('~')[1].split('\\[')[2].removeEnd(']');
                        subFilterValue=listNameToFilterInstructions.get(k).split(',')[0].split('~')[1].split('\\[')[3].removeEnd(']');
                                    
                    } else {//1.16+
                        subFilterObject=null;
                        subFilterList=null;
                        subFilterAttribute=null;
                        subFilterOperator=null;
                        subFilterValue=null;
                    }

                    childListPath = (cacheInstructionParts.size()>=2) ? cacheInstructionParts[1] : null;//1.1+
                    referenceListPath = (cacheInstructionParts.size()==3) ? cacheInstructionParts[2] : null;//1.1+

                    //1.1- nameAttribute = cacheInstructionParts[0].split(',')[0];                
                    //1.1- childListPath =  (cacheInstructionParts[0].split(',').size()==2) ? cacheInstructionParts[0].split(',')[1] : null;

                    for (Object li : (List<Object>)currentMap.get(k)){//<-- list enumeration.

                        idValue=null;
                        nameValue=null;
                        typeValue=null;
                        parentIdValue=null;
                        salesforceIdValue=null;
                        filterCheckValue=null;//1.15+

                        if (li instanceof Map<String,Object>){

                            itemMap = (Map<String,Object>)li;

                            if (String.isNotBlank(filterAttribute) && String.isNotBlank(filterOperator) && String.isNotBlank(filterValue)){//1.15~
                                filterCheckValue=null;

                                if (filterAttribute.contains('.')){
                                    if (itemMap.containsKey(filterAttribute.split('\\.')[0]) && itemMap.get(filterAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                        
                                        subItemMap = (Map<String,Object>)itemMap.get(filterAttribute.split('\\.')[0]);
                            
                                        if (subItemMap.containsKey(filterAttribute.split('\\.')[1])) filterCheckValue = subItemMap.get(filterAttribute.split('\\.')[1]);
                                    }
                                } else if (itemMap.containsKey(filterAttribute)) filterCheckValue = itemMap.get(filterAttribute);                                
                                    
                                if (filterCheckValue==null || excludeDueToFilter(filterOperator,filterValue,filterCheckValue)) continue;//next item in the list.
                            }

                            if (idAttribute.contains('.')){
                                if (itemMap.containsKey(idAttribute.split('\\.')[0]) && itemMap.get(idAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                    
                                    subItemMap = (Map<String,Object>)itemMap.get(idAttribute.split('\\.')[0]);
                        
                                    if (subItemMap.containsKey(idAttribute.split('\\.')[1])) idValue = (String)subItemMap.get(idAttribute.split('\\.')[1]);
                                }
                            } else if (itemMap.containsKey(idAttribute)) idValue = (String)itemMap.get(idAttribute);
                        
                            if (nameAttribute.contains('.')){
                                if (itemMap.containsKey(nameAttribute.split('\\.')[0]) && itemMap.get(nameAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                    
                                    subItemMap = (Map<String,Object>)itemMap.get(nameAttribute.split('\\.')[0]);
                        
                                    if (subItemMap.containsKey(nameAttribute.split('\\.')[1])) nameValue = (String)subItemMap.get(nameAttribute.split('\\.')[0]);
                                }
                            } else if (itemMap.containsKey(nameAttribute)) nameValue = (String)itemMap.get(nameAttribute);
                        
                            if (String.isBlank(idValue) || String.isBlank(nameValue)) continue;

                            if (typeAttribute!=null && typeAttribute.contains('.')){//1.7+
                                if (itemMap.containsKey(typeAttribute.split('\\.')[0]) && itemMap.get(typeAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                    
                                    subItemMap = (Map<String,Object>)itemMap.get(typeAttribute.split('\\.')[0]);
                        
                                    if (subItemMap.containsKey(typeAttribute.split('\\.')[1])) typeValue = (String)subItemMap.get(typeAttribute.split('\\.')[0]);
                                }
                            } else if (typeAttribute!=null && itemMap.containsKey(typeAttribute)) typeValue = (String)itemMap.get(typeAttribute);
                                                        
                            if (salesforceIdAttribute!=null && salesforceIdAttribute.contains('.')){//1.8+
                                if (itemMap.containsKey(idAttribute.split('\\.')[0]) && itemMap.get(idAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                    
                                    subItemMap = (Map<String,Object>)itemMap.get(salesforceIdAttribute.split('\\.')[0]);
                        
                                    if (subItemMap.containsKey(salesforceIdAttribute.split('\\.')[1])) salesforceIdValue = (String)subItemMap.get(salesforceIdAttribute.split('\\.')[1]);
                                }
                            } else if (salesforceIdAttribute!=null && itemMap.containsKey(salesforceIdAttribute)) salesforceIdValue = (String)itemMap.get(salesforceIdAttribute);


                            //1.1- if (itemMap.containsKey('system') && itemMap.containsKey(nameAttribute)){

                            //1.1-     idValue = (String)((Map<String,Object>)itemMap.get('system')).get('uid');
                            //1.1-     parentIdValue = (String)((Map<String,Object>)itemMap.get('system')).get('uid');
                            //1.1-     nameValue = (String)itemMap.get(nameAttribute);

                            parentIdValue = idValue;//1.1~

                            GenericContent__c parentContent = new GenericContent__c(ContentId__c=idValue,Name=nameValue,ContentType__c=csct.ContentType__c,ContentSubtype__c=csct.ContentSubtype__c,SalesforceId__c=salesforceIdValue,Locale__c=csct.Locale__c);//1.13~ Locale__c
                            if (String.isNotBlank(typeValue)) parentContent.LocationType__c=typeValue;//1.7+

                            //1.9 -- enumerate csct.ContentTypeFieldMappings__r for the current object (li)
                            //1.9 -- populate parentContent fields.

                            if (csct.ContentTypeFieldMappings__r!=null && csct.ContentTypeFieldMappings__r.size()>0){//1.9+
                                contentTypeFieldMappings = csct.ContentTypeFieldMappings__r;
                            }

                            if (contentTypeFieldMappings!=null && !contentTypeFieldMappings.isEmpty()){
                                Object fieldValue;
                                Schema.DisplayType fieldDisplayType;
                                
                                for (ContentTypeFieldMapping__mdt ctfm : contentTypeFieldMappings){
                                    if (genericContentObjDescribe==null) genericContentObjDescribe = GenericContent__c.getSObjectType().getDescribe();                                    
                                    if (genericContentObjDescribe==null || !genericContentObjDescribe.fields.getMap().containsKey(ctfm.FieldName__c)) continue;                                    

                                    fieldValue = queryContentTypeFieldMapping(li,ctfm.FieldValuePath__c);
                                    if (fieldValue!=null){

                                        fieldDisplayType = genericContentObjDescribe.fields.getMap().get(ctfm.FieldName__c).getDescribe().getType();   

                                        copyFieldValue(parentContent,ctfm.FieldName__c,fieldDisplayType,fieldValue);//1.10+
                                    }
                                }
                            }

                            //NLR - GenericContent__c parentContentReference = new GenericContent__c(ContentId__c=idValue); //Create content reference for assigning child content foreign key
                            
                            if (String.isBlank(childListPath)){//1.16~
                                if (subFilterList!=null && subFilterAttribute!=null && subFilterOperator!=null && subFilterValue!=null) applySubFilter(itemMap, subFilterList,subFilterObject,subFilterAttribute,subFilterOperator,subFilterValue);//1.16+                                
                                parentContent.ContentJSON__c = JSON.serialize(itemMap).replace('’','\'');//1.16~ 1.4~
                            }
                                
                            cacheData[0].put(idValue,new List<SObject>{ parentContent });

                            if (String.isNotBlank(childListPath)){

                                if (listNameToFilterInstructions.containsKey(k)   
                                    && listNameToFilterInstructions.get(k).split(',').size()==2                     
                                    && listNameToFilterInstructions.get(k).split(',')[1].split('~')[0].split('\\[').size()==4){//1.15+ 1.16~ -- Generic Content Item filter.

                                    filterAttribute=listNameToFilterInstructions.get(k).split(',')[1].split('~')[0].split('\\[')[1].removeEnd(']');//1.16~
                                    filterOperator=listNameToFilterInstructions.get(k).split(',')[1].split('~')[0].split('\\[')[2].removeEnd(']');//1.16~
                                    filterValue=listNameToFilterInstructions.get(k).split(',')[1].split('~')[0].split('\\[')[3].removeEnd(']');//1.16~
                                } else {
                                    filterAttribute=null;
                                    filterOperator=null;
                                    filterValue=null;
                                }
            
                                if (listNameToFilterInstructions.containsKey(k)   
                                    && listNameToFilterInstructions.get(k).split(',').size()==2                                    
                                    && listNameToFilterInstructions.get(k).split(',')[1].split('~').size()==2
                                    && listNameToFilterInstructions.get(k).split(',')[1].split('~')[1].split('\\[').size()==4){//1.16+

                                    // -- ,~promotions.offer[visible_to][<][TODAY]
        
                                    subFilterList=listNameToFilterInstructions.get(k).split(',')[1].split('~')[1].split('\\[')[0].removeEnd(']');
                                    if (subFilterList.split('\\.').size()==2){
                                        subFilterObject = subFilterList.split('\\.')[0];
                                        subFilterList = subFilterList.split('\\.')[1];
                                    }
                                    subFilterAttribute=listNameToFilterInstructions.get(k).split(',')[1].split('~')[1].split('\\[')[1].removeEnd(']');
                                    subFilterOperator=listNameToFilterInstructions.get(k).split(',')[1].split('~')[1].split('\\[')[2].removeEnd(']');
                                    subFilterValue=listNameToFilterInstructions.get(k).split(',')[1].split('~')[1].split('\\[')[3].removeEnd(']');
                                                
                                } else {//1.16+
                                    subFilterObject=null;
                                    subFilterList=null;
                                    subFilterAttribute=null;
                                    subFilterOperator=null;
                                    subFilterValue=null;
                                }                             

                                // if (listNameToFilterInstructions.containsKey(k)                        
                                //     && listNameToFilterInstructions.get(k).split(',').size()==2
                                //     && listNameToFilterInstructions.get(k).split(',')[1].split('\\[').size()==4){//1.15+ -- Generic Content Item filter.

                                //     //1.15. -- note split returns with an empty string first index.
                
                                //     filterAttribute=listNameToFilterInstructions.get(k).split(',')[1].split('\\[')[1].removeEnd(']');
                                //     filterOperator=listNameToFilterInstructions.get(k).split(',')[1].split('\\[')[2].removeEnd(']');
                                //     filterValue=listNameToFilterInstructions.get(k).split(',')[1].split('\\[')[3].removeEnd(']');
                                // } else {
                                //     filterAttribute=null;
                                //     filterOperator=null;
                                //     filterValue=null;
                                // }                                               

                                //<-- constraint. child list is either direct descendant or a parent map away (e.g. overview=>vemues).

                                if (childListPath.split('=>').size()==1){

                                    if (itemMap.containsKey(childListPath) && itemMap.get(childListPath) instanceof List<Object>){

                                        for (Object ci : (List<Object>)itemMap.get(childListPath)){ 

                                            if (!(ci instanceof Map<String, Object>)
                                                || !((Map<String,Object>)ci).containsKey('system')
                                                || !((Map<String,Object>)((Map<String,Object>)ci).get('system')).containsKey('uid')) continue;//1.5+

                                            childItemMap = (Map<String,Object>)ci;//1.15+

                                            if (String.isNotBlank(filterAttribute) && String.isNotBlank(filterOperator) && String.isNotBlank(filterValue)){//1.15~
                                                filterCheckValue=null;

                                                if (filterAttribute.contains('.')){
                                                    if (childItemMap.containsKey(filterAttribute.split('\\.')[0]) && childItemMap.get(filterAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                                        
                                                        childSubItemMap = (Map<String,Object>)childItemMap.get(filterAttribute.split('\\.')[0]);
                                            
                                                        if (childSubItemMap.containsKey(filterAttribute.split('\\.')[1])) filterCheckValue = childSubItemMap.get(filterAttribute.split('\\.')[1]);
                                                    }
                                                } else if (childItemMap.containsKey(filterAttribute)) filterCheckValue = childItemMap.get(filterAttribute);                                
                                                    
                                                if (filterCheckValue==null || excludeDueToFilter(filterOperator,filterValue,filterCheckValue)) continue;//next item in the list.
                                            }
                                            
                                            if(!cacheData[1].containsKey(parentIdValue)) cacheData[1].put(parentIdValue,new List<SObject>());

                                            if (subFilterList!=null && subFilterAttribute!=null && subFilterOperator!=null && subFilterValue!=null) applySubFilter(childItemMap,subFilterList,subFilterObject,subFilterAttribute,subFilterOperator,subFilterValue);//1.16+

                                            idValue = (String)((Map<String,Object>)((Map<String,Object>)ci).get('system')).get('uid');//1.1. Hard-coded uid reference.
                                            jsonBody = JSON.serialize(childItemMap);//1.16~ 1.4+
                                            jsonBody = (jsonBody != null)?jsonBody.replace('’', '\''):null;//1.4+                       
                                            //cacheData[1].get(parentIdValue).add( new GenericContentItem__c(ContentId__c=idValue,ContentJSON__c=JSON.serialize(ci)) );//1.4+
                                            cacheData[1].get(parentIdValue).add( new GenericContentItem__c(ContentId__c=idValue,ContentJSON__c=jsonBody) );//1.4+
                                        }
                                    }
                                    
                                } else if (childListPath.split('=>').size()==2){

                                    String childListParentMapName = childListPath.split('=>')[0];
                                    String childListName = childListPath.split('=>')[1];
                                    
                                    if (itemMap.containsKey(childListParentMapName) && itemMap.get(childListParentMapName) instanceof Map<String, Object>){

                                        Map<String,Object> childListParentMap = (Map<String, Object>)itemMap.get(childListParentMapName);

                                        if (childListParentMap.containsKey(childListName) && childListParentMap.get(childListName) instanceof List<Object>){

                                            for (Object ci : (List<Object>)childListParentMap.get(childListName)){
                                                
                                                if (!(ci instanceof Map<String, Object>)
                                                    || !((Map<String,Object>)ci).containsKey('system')
                                                    || !((Map<String,Object>)((Map<String,Object>)ci).get('system')).containsKey('uid')) continue;//1.5+

                                                childItemMap = (Map<String,Object>)ci;//1.15+

                                                if (String.isNotBlank(filterAttribute) && String.isNotBlank(filterOperator) && String.isNotBlank(filterValue)){//1.15~
                                                    filterCheckValue=null;
                    
                                                    if (filterAttribute.contains('.')){
                                                        if (childItemMap.containsKey(filterAttribute.split('\\.')[0]) && childItemMap.get(filterAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                                                            
                                                            childSubItemMap = (Map<String,Object>)childItemMap.get(filterAttribute.split('\\.')[0]);
                                                
                                                            if (childSubItemMap.containsKey(filterAttribute.split('\\.')[1])) filterCheckValue = childSubItemMap.get(filterAttribute.split('\\.')[1]);
                                                        }
                                                    } else if (childItemMap.containsKey(filterAttribute)) filterCheckValue = childItemMap.get(filterAttribute);                                
                                                        
                                                    if (filterCheckValue==null || excludeDueToFilter(filterOperator,filterValue,filterCheckValue)) continue;//next item in the list.
                                                }                                                

                                                if(!cacheData[1].containsKey(parentIdValue)) cacheData[1].put(parentIdValue,new List<SObject>());
                                                
                                                if (subFilterList!=null && subFilterAttribute!=null && subFilterOperator!=null && subFilterValue!=null) applySubFilter(childItemMap,subFilterList,subFilterObject,subFilterAttribute,subFilterOperator,subFilterValue);//1.16+

                                                idValue = (String)((Map<String,Object>)((Map<String,Object>)ci).get('system')).get('uid');//1.1. Hard-coded uid reference.

                                                jsonBody = JSON.serialize(childItemMap);//1.16~ 1.4+
                                                jsonBody = (jsonBody != null)?jsonBody.replace('’', '\''):null;//1.4+ 
                                                //cacheData[1].get(parentIdValue).add( new GenericContentItem__c(ContentId__c=idValue,ContentJSON__c=JSON.serialize(ci)) );//1.4-
                                                cacheData[1].get(parentIdValue).add( new GenericContentItem__c(ContentId__c=idValue,ContentJSON__c=jsonBody) );//1.4+
                                            }
                                        }
                                    }                                    
                                }
                                // -- [removed for release] System.debug(LoggingLevel.ERROR,'parentContent='+parentContent);
                            }

                            if (String.isNotBlank(referenceListPath) && referenceListPath.split(':').size()==2){//1.1+
                                
                                //<-- constraint. reference list is either direct descendant or a parent map away (e.g. email_display_options=>references).

                                String refListPath = referenceListPath.split(':')[0];
                                String refIdAttribute = referenceListPath.split(':')[1].split('=>')[0];
                                String refTypeAttribute = referenceListPath.split(':')[1].split('=>')[1];
                                String refNameAttributes = referenceListPath.split(':')[1].split('=>')[2];

                                if (refListPath.split('=>').size()==1){

                                    if (itemMap.containsKey(refListPath) && String.isNotBlank(parentContent.ContentJSON__c)){//1.3+
                                        Map<String,Object> clonedItemMap =  itemMap.clone();
                                        clonedItemMap.remove(refListPath);

                                        parentContent.ContentJSON__c = JSON.serialize(clonedItemMap).replace('’','\'');//1.4~
                                    }

                                    if (itemMap.containsKey(refListPath) && itemMap.get(refListPath) instanceof List<Object>){

                                        for (Object cr : (List<Object>)itemMap.get(refListPath)){  

                                            if (cr instanceof Map<String,Object>){

                                                GenericContentReference__c gcr = buildGenericContentReference((Map<String,Object>)cr,refIdAttribute,refTypeAttribute,refNameAttributes);
                                                    
                                                if (gcr!=null){                                                
                                                    if(!cacheData[2].containsKey(parentIdValue)) cacheData[2].put(parentIdValue,new List<SObject>());
                                                    cacheData[2].get(parentIdValue).add(gcr);    
                                                }
                                            }
                                        }
                                    }
                                } else if (refListPath.split('=>').size()==2){

                                    String refListParentMapName = refListPath.split('=>')[0];
                                    String refListName = refListPath.split('=>')[1];

                                    if (String.isNotBlank(parentContent.ContentJSON__c)){//1.3+
                                        Map<String,Object> clonedItemMap =  itemMap.clone();
                                        clonedItemMap.remove(refListParentMapName);

                                        parentContent.ContentJSON__c = JSON.serialize(clonedItemMap).replace('’','\'');//1.4~
                                    }

                                    if (itemMap.containsKey(refListParentMapName) && itemMap.get(refListParentMapName) instanceof Map<String, Object>){
                                        
                                        Map<String,Object> refListParentMap = (Map<String, Object>)itemMap.get(refListParentMapName);

                                        if (refListParentMap.containsKey(refListName) && refListParentMap.get(refListName) instanceof List<Object>){

                                            for (Object cr : (List<Object>)refListParentMap.get(refListName)){

                                                if (cr instanceof Map<String,Object>){

                                                    GenericContentReference__c gcr = buildGenericContentReference((Map<String,Object>)cr,refIdAttribute,refTypeAttribute,refNameAttributes);
                                                    
                                                    if (gcr!=null){                                                
                                                        if(!cacheData[2].containsKey(parentIdValue)) cacheData[2].put(parentIdValue,new List<SObject>());
                                                        cacheData[2].get(parentIdValue).add(gcr);    
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }                            
                        }//li is map
                    }//li

                } else if (currentMap.get(k) instanceof Map<String,Object>){
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'Map Found='+k);
                    parseToCacheObject(currentMap.get(k),cacheData,csct);

                } else if (currentMap.get(k) instanceof List<Object>){
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'List Found='+k);
                    for (Object o2 : (List<Object>)currentMap.get(k)){  parseToCacheObject(o2,cacheData,csct); }

                } else {
                    // -- [removed for release] System.debug(LoggingLevel.ERROR,'Attribute Found='+k+'=>'+currentMap.get(k));                
                }
            }
    
        } else if (o instanceof List<Object>){
            // -- [removed for release] System.debug(LoggingLevel.ERROR,'Parse List object='+o);

            for (Object o2 : (List<Object>)o){ parseToCacheObject(o2,cacheData,csct); }
        
        } else {
            // -- [removed for release] System.debug(LoggingLevel.ERROR,'Unknown Found='+o);
        }
        
        return cacheData;
    }    

    private static GenericContentReference__c buildGenericContentReference(Map<String,Object> referenceItemMap, String refIdAttribute, String refTypeAttribute, String refNameAttributes){//1.1+

        Map<String,Object> subItemMap;
        String refIdValue,refNameValue,refTypeValue;
                        
        if (refIdAttribute.contains('.')){
            if (referenceItemMap.containsKey(refIdAttribute.split('\\.')[0]) && referenceItemMap.get(refIdAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                
                subItemMap = (Map<String,Object>)referenceItemMap.get(refIdAttribute.split('\\.')[0]);
    
                if (subItemMap.containsKey(refIdAttribute.split('\\.')[1])) refIdValue = (String)subItemMap.get(refIdAttribute.split('\\.')[1]);
            }
        } else if (referenceItemMap.containsKey(refIdAttribute)) refIdValue = (String)referenceItemMap.get(refIdAttribute);

        if (refTypeAttribute.contains('.')){
            if (referenceItemMap.containsKey(refTypeAttribute.split('\\.')[0]) && referenceItemMap.get(refTypeAttribute.split('\\.')[0]) instanceof Map<String,Object>){
                
                subItemMap = (Map<String,Object>)referenceItemMap.get(refTypeAttribute.split('\\.')[0]);
    
                if (subItemMap.containsKey(refTypeAttribute.split('\\.')[1])) refTypeValue = (String)subItemMap.get(refTypeAttribute.split('\\.')[1]);
            }
        } else if (referenceItemMap.containsKey(refTypeAttribute)) refTypeValue = (String)referenceItemMap.get(refTypeAttribute);                                                    
    
        for (String possibleRefName : refNameAttributes.split(';')){
            if (referenceItemMap.containsKey(possibleRefName)){
                refNameValue = (String)referenceItemMap.get(possibleRefName);
                break;
            }
        }
        if (String.isBlank(refIdValue) || String.isBlank(refNameValue) || String.isBlank(refTypeValue)) return null;

         return new GenericContentReference__c(ContentId__c=refIdValue,ContentName__c=refNameValue,ContentType__c=refTypeValue);
    }

    private static Object queryContentTypeFieldMapping(Object originalObject, String fieldValuePath){//1.9+ <--- fieldValuePath syntax as per response reshaped payload mapping.
        //[get>data>Map],[get>all_locations>Map],[get>items>end]
        //[get>records>list],[index>0>Map],[get>RecordType>Map],[get>DeveloperName>end]
        //[get>itineraryBookingId>end]
        Object currentObject = originalObject;

        List<String> tokens = new List<String>();
        Map<String,Object> currentMap;
        List<Object> currentList;
        String actionToken,nameOrIndexToken,typeToken;

        for (String valuePathElem : fieldValuePath.split(',')){// .. [get>records>list]
            
            tokens = valuePathElem.split('>');// .. [0]=get|index [1]=[index]|[name] [2]=list|map|end
            if (tokens.size()<>3) break;

            actionToken = tokens[0].removeStart('[');
            nameOrIndexToken = tokens[1];
            typeToken = tokens[2].removeEnd(']');
            
            if ((actionToken.equalsIgnoreCase('get') &&
                currentObject instanceof Map<String,Object>) ||
                (actionToken.equalsIgnoreCase('index') &&
                currentObject instanceof List<Object>)){

                currentMap = (actionToken.equalsIgnoreCase('get')) ? (Map<String,Object>)currentObject : null;
                currentList = (actionToken.equalsIgnoreCase('index')) ? (List<Object>)currentObject : null;
                
                switch on typeToken {
                    when 'list','LIST','List' {
                        if (currentMap!=null) currentObject = currentMap.containsKey(nameOrIndexToken) ? (List<Object>)currentMap.get(nameOrIndexToken) : null;//1.11~
                        else if (currentList!=null) currentObject = currentList.size()>(Integer.valueOf(nameOrIndexToken)) ? (List<Object>)currentList.get(Integer.valueOf(nameOrIndexToken)) : null;//1.11~
                    }
                    when 'map','MAP','Map' {
                        if (currentMap!=null) currentObject = currentMap.containsKey(nameOrIndexToken) ? (Map<String,Object>)currentMap.get(nameOrIndexToken) : null;//1.11~
                        else if (currentList!=null) currentObject = currentList.size()>(Integer.valueOf(nameOrIndexToken)) ? (Map<String,Object>)currentList.get(Integer.valueOf(nameOrIndexToken)) : null;//1.11~
                    }
                    when 'end','END','End' {
                        if (currentMap!=null) currentObject = currentMap.containsKey(nameOrIndexToken) ? (Object)currentMap.get(nameOrIndexToken) : null;//1.11~
                        else if (currentList!=null) currentObject = currentList.size()>(Integer.valueOf(nameOrIndexToken)) ? (Object)currentList.get(Integer.valueOf(nameOrIndexToken)) : null;//1.11~

                        return currentObject;
                    }
                }
            }
        }                                                               
        return null;
    }

    private static void copyFieldValue(SObject targetRecord, String targetFieldName, Schema.DisplayType targetFieldDisplayType, Object fieldValue){//1.10+
        try {		    

            if (targetFieldDisplayType==Schema.DisplayType.TEXTAREA 
                    || targetFieldDisplayType==Schema.DisplayType.URL 
                    || targetFieldDisplayType==Schema.DisplayType.PICKLIST 
                    || targetFieldDisplayType==Schema.DisplayType.PHONE 
                    || targetFieldDisplayType==Schema.DisplayType.MULTIPICKLIST
                    || targetFieldDisplayType==Schema.DisplayType.EMAIL
                    || targetFieldDisplayType==Schema.DisplayType.COMBOBOX
                    || targetFieldDisplayType==Schema.DisplayType.ANYTYPE
                    || targetFieldDisplayType==Schema.DisplayType.ENCRYPTEDSTRING
                    || targetFieldDisplayType==Schema.DisplayType.ID
                    || targetFieldDisplayType==Schema.DisplayType.JSON
                    || targetFieldDisplayType==Schema.DisplayType.REFERENCE
                    || targetFieldDisplayType==Schema.DisplayType.STRING ) {
                
                targetRecord.put(targetFieldName, (String)fieldValue);
            
            } else if (targetFieldDisplayType==Schema.DisplayType.DOUBLE || targetFieldDisplayType==Schema.DisplayType.CURRENCY){
                targetRecord.put(targetFieldName, (Decimal)fieldValue);
            } else if (targetFieldDisplayType==Schema.DisplayType.INTEGER){
				Decimal decimalVal = (Decimal)fieldValue;
				targetRecord.put(targetFieldName, decimalVal.intValue());                                                                                
            } else if (targetFieldDisplayType==Schema.DisplayType.BOOLEAN){                
                targetRecord.put(targetFieldName, (Boolean)fieldValue);
            } else if (targetFieldDisplayType==Schema.DisplayType.DATE){  
                
                Date d;
                try { d = Date.valueOf((String)fieldValue);// yyyy-MM-dd
                } catch(Exception e){}
                
                if (d==null){
                    try { d = Date.parse((String)fieldValue);// dd/MM/yyyy
                    } catch(Exception e){}
                }
                if (d!=null) targetRecord.put(targetFieldName, d);

            } else if (targetFieldDisplayType==Schema.DisplayType.DATETIME){ targetRecord.put(targetFieldName, (DateTime)fieldValue); }
        } catch (Exception e){ throw e; }
		return;
    }     
    
    private static Boolean excludeDueToFilter(String filterOperator,String filterValue, Object o){//1.15+ -- return TRUE to exclude.
        //filterOperator = >
        //filterValue = TODAY
        //filterCheckValue = 2023-03-07T00:00:00.000Z

        //filterOperator = =
        //filterValue = London
        //filterCheckValue = Edinburgh

        if (filterValue.equalsIgnoreCase('TODAY')){
            Datetime dt;

            if (o instanceof Datetime){
                dt = Datetime.valueOf(o);
                
            } else if (o instanceof Date){
                Date d = Date.valueOf(o);
                if (d!=null) dt = Datetime.newInstance(d.year(),d.month(),d.day());
            } else if (o instanceof String){
                try{
                    dt = Datetime.valueOf((String)o);
                } catch(Exception e2){}
            }
            if (dt==null && o instanceof String){
                try{
                    Date d = Date.valueOf((String)o);
                    dt = Datetime.newInstance(d.year(),d.month(),d.day());
                } catch(Exception e2){}                
            }
            if (dt==null) return false;// -- missing or invalid inputs are not excluded by default.

            if (filterOperator.equals('=')) return !dt.isSameDay(Datetime.now());// if not same day then exclude (return true).            
            if (filterOperator.equals('<>')) return dt.isSameDay(Datetime.now());// if is same day then exclude (return true).
            if (filterOperator.equals('<=')) return !(dt.isSameDay(Datetime.now()) || dt<Datetime.now());
            if (filterOperator.equals('>=')) return !(dt.isSameDay(Datetime.now()) || dt>Datetime.now());
            if (filterOperator.equals('<')) return !(dt<Datetime.now());
            if (filterOperator.equals('>')) return !(dt>Datetime.now());
        
        } else {

            if (filterOperator.equals('=')) return !(filterValue.equalsIgnoreCase(String.valueOf(o)));
            if (filterOperator.equals('<>')) return (filterValue.equalsIgnoreCase(String.valueOf(o)));
        }
        return false;// -- missing or invalid inputs are not excluded by default.
    }

    private static void applySubFilter(Map<String,Object> itemMap, String subFilterList,String subFilterObject,String subFilterAttribute,String subFilterOperator,String subFilterValue){//1.16+
        List<Object> itemList;
        Map<String,Object> itemMap2;

        if (subFilterObject!=null 
            && itemMap.containsKey(subFilterObject)
            && itemMap.get(subFilterObject) instanceof Map<String,Object>){

            itemMap2 = (Map<String,Object>)itemMap.get(subFilterObject);                                    
            if (itemMap2.containsKey(subFilterList) && itemMap2.get(subFilterList) instanceof List<Object>) itemList = (List<Object>)itemMap2.get(subFilterList);
            
        } else if (itemMap.containsKey(subFilterList) && itemMap.get(subFilterList) instanceof List<Object>) itemList = (List<Object>)itemMap.get(subFilterList);

        if (itemList==null) return;
        
        for (Integer i=0;i<itemList.size();i++){
            if (!(itemList[i] instanceof Map<String,Object>)) continue;

            itemMap2 = (Map<String,Object>)itemList[i];                            
            if (itemMap2.containsKey(subFilterAttribute) && excludeDueToFilter(subFilterOperator,subFilterValue,itemMap2.get(subFilterAttribute))) itemList.remove(i);
        }
    }   
}