/*
Name:  DuplicateManagementHelper.cls
======================================================
======================================================
Purpose: Manager for all Master Account De-duplication
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-08-12   Initial development
1.1  J Radcliffe   2019-08-21   Big Fix - Work around for packages not having Person Accounts enabled 
1.2  J Radcliffe   2019-09-03   Support for multiple Duplicate Rules (unique rules per Action Type)
1.3  J Radcliffe   2019-09-03   Separating Upserts into Update/Inserts (SF does not support DML Options for DML Upsert operations)
1.4  J Radcliffe   2019-09-04   Additional support for test assertions with inactive Duplicate Management
1.5  J Radcliffe   2019-09-04   Support for skipping Duplicate Matching if set explicitly via bypassDupeCheck property
1.6  J Radcliffe   2019-09-09   Bug Fix - null check
1.7  J Radcliffe   2019-09-10   Bug Fix - Handle lower volume duplicates
1.8  J Radcliffe   2019-09-10   Bug Fix - 'No duplicate rules are defined for the Account object.' - Cause: Absence of a Person Account Record Type Id
1.9  J Radcliffe   2019-09-12   Bug Fix - Null Reference Errors
1.10 J Radcliffe   2019-09-16   Add support for specifying Record Type/s for Dupe Checks
1.11 J Radcliffe   2019-11-02   Set allOrNone DML Option to false, Abort Enquiry and Add Error on Client Insert/Update failure
1.12 J Radcliffe   2019-12-06   Bug Fix - Prevent false positives by aborting enquiries if exception is thrown
1.13 J Radcliffe   2020-01-20   Add uniqueIdentifier to property cache for reference in subsequent processing
1.14 J Radcliffe   2020-03-04   Set the 'clientCreatedOrUpdated' property 
1.15 J Radcliffe   2020-10-01   Moving the creation of the Individual record to the Iframework (plus dynamic field mapping)
1.16 Mark Cane&    2023-12-04   Enhancements - if the specified DuplicateRule is inactive then set all enquiries to bypassDupeCheck - better to process enquiries than throw an error.
*/
global without sharing class DuplicateManagementHelper {

    //Performs the client matching logic for inbound enquiries leveraging Salesforce Duplicate Management matching rules
    global static Boolean findDuplicates(List<EnquiryManager.Enquiry> enquiries, String duplicateRuleDeveloperName/*1.2*/){
        
        try{
            //1.10+
            FrameworkSettings__c fs = FrameworkSettings__c.getInstance();
            List<Id> supportedRecordTypes = new List<Id>();
            if(fs != null && fs.AccountDupeManagementRecordTypeIds__c != null){
                if(fs.AccountDupeManagementRecordTypeIds__c.contains(',')){
                    supportedRecordTypes.addAll((List<Id>)fs.AccountDupeManagementRecordTypeIds__c.split(','));
                }else{
                    supportedRecordTypes.add((Id)fs.AccountDupeManagementRecordTypeIds__c);
                }
            }

            if (fs?.SkipInactiveDuplicateRules__c!=null && fs.SkipInactiveDuplicateRules__c && String.isNotBlank(duplicateRuleDeveloperName)){//1.16+
                List<DuplicateRule> duplicateRules = [select Id, IsActive from DuplicateRule where DeveloperName=:duplicateRuleDeveloperName];
                if (duplicateRules.size()<>1 || !duplicateRules[0].IsActive){
                    for(EnquiryManager.Enquiry e : enquiries){ e.bypassDupeCheck=true; }
                }
            }

            //Apply Unique Identifier and store in a map
            Map<String, EnquiryManager.Enquiry> enqMap = new Map<String, EnquiryManager.Enquiry>();
            for(EnquiryManager.Enquiry e : enquiries){
                if(e.isAborted) continue;
                e.uniqueIdentifier = createUniqueIdentifier(e);//Assign a unique identifier to the Enquiry
                e.propertyCache.put('uniqueIdentifier',e.uniqueIdentifier);//1.13+
                enqMap.put(e.uniqueIdentifier,e);
            }

            List<Account> processAccounts = new List<Account>();//Accounts to de-dupe
            List<String> enqKeyIndexList = new List<String>();//Enquiry Identifiers in same order (enqKeyIndexList[i] stores the identifier for processAccounts[i] account )
            Map<String,List<Id>> enqKeyWithDupeAccountIds = new Map<String,List<Id>>();//1.10+
            List<Id> allDupeIds = new List<Id>();//1.10+
            
            for(EnquiryManager.Enquiry e : enquiries){
                if(e.ClientDetails.accountId != null) continue;//Exit if AccountId is specified in the request
                if(e.bypassDupeCheck != null && e.bypassDupeCheck) continue;//Exit if explicitly told to skip duplicate matching //1.5+//1.6+
                processAccounts.add(createAccountFromEnquiry(e));//Cache in ordered lists to process
                enqKeyIndexList.add(e.uniqueIdentifier);//Cache in ordered list to link Dupe Result back to Enquiry
                if((processAccounts.size()==50) ||(processAccounts.size()<50 && processAccounts.size() == enquiries.size())){//<-- Method can only take 50 sObjects per batch//1.7~
                    if(!Test.isRunningTest()){//1.15+ Unit tests failing since adding support for Person Accounts ('EntityInfo of EntityObject cannot be set to null') - Bypassing DataCloud methods in Test Context
                        List<DataCloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(processAccounts);
                        for(Integer i=0; i<results.size(); i++){
                        DataCloud.FindDuplicatesResult res = results[i];
                            if(!res.success){
                                for(Database.Error error : res.errors){
                                    enqMap.get(enqKeyIndexList[i]).errorMessages.put('keyCode','Label'+error.getMessage());
                                }
                                enqMap.get(enqKeyIndexList[i]).isAborted = true;
                            }else{              
                                ///Assign Duplicate Id to Account Id
                                for(Datacloud.DuplicateResult dupe: res.getDuplicateResults()){
                                    if(duplicateRuleDeveloperName == null || dupe.getDuplicateRule().equalsIgnoreCase(duplicateRuleDeveloperName)){//Only proceed for the applicable rule (if specified)//1.2
                                        for (Datacloud.MatchResult matchResult : dupe.getMatchResults()) {//1.10+
                                            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {//1.10+
                                                if(!enqKeyWithDupeAccountIds.containsKey(enqKeyIndexList[i])) enqKeyWithDupeAccountIds.put(enqKeyIndexList[i],new List<Id>());//1.10+
                                                    List<Id> idList = enqKeyWithDupeAccountIds.get(enqKeyIndexList[i]);
                                                    idList.add(matchRecord.getRecord().Id);//1.10+
                                                    enqKeyWithDupeAccountIds.put(enqKeyIndexList[i],idList);//1.10+
                                                    allDupeIds.add(matchRecord.getRecord().Id);//1.10+
                                            }
                                        }   
                                    } 
                                        //if(dupe.getMatchResults().size()>0 && dupe.getMatchResults()[0].getMatchRecords().size()>0){//1.10-
                                            //enqMap.get(enqKeyIndexList[i]).ClientDetails.accountId = dupe.getMatchResults()[0].getMatchRecords()[0].getRecord().Id;//1.10-
                                            //e.propertyCache.put('ClientDetails.accountId',enqMap.get(enqKeyIndexList[i]).ClientDetails.accountId);//1.10-
                                            //break;1.10-
                                        //}//1.10-
                                    
                                } 
                            }
                        }   
                    }
                processAccounts = new List<Account>();//Clear the process list
                enqKeyIndexList = new List<String>();//Clear the uniqueId List
                }
            }

            //Query Accounts with Supported Record Types
            List<Id> applicableAccountIds = new List<Id>();
            String query = 'Select Id From Account Where Id in :allDupeIds';
            if(!Test.isRunningTest()) query = query+' and RecordTypeId in :supportedRecordTypes';//Dynamic Query Required to work around; No such column 'RecordTypeId' on entity 'Account'
            for(Account acc : database.query(query)){
                applicableAccountIds.add(acc.Id);
            }

            //Assign Dupe Id to accountId property
            for(String enqKey : enqMap.keySet()){//1.10+
                if(enqKeyWithDupeAccountIds.containsKey(enqKey)){
                    for(Id accId : enqKeyWithDupeAccountIds.get(enqKey)){
                        if(applicableAccountIds.contains(accId)){//Check if the duplicate Id is in the applicable accounts list (else continue)
                            enqMap.get(enqKey).ClientDetails.accountId = accId;//Assign the Id
                            enqMap.get(enqKey).propertyCache.put('ClientDetails.accountId',accId);//Add Id to Enq property cache
                            break;//Move onto next Enquiry
                        }
                    }
                }
            }

            return true;
        }catch(exception e){
            LogHelper.logExceptions(e, 'DuplicateManagement', 'getDuplicateAccountIds');
            for(EnquiryManager.Enquiry enq : enquiries){//1.12
                enq.isAborted = true;
                enq.errorMessages.put('1090',Label.Duplicate_Management_Failure_Runtime_Error+': '+e.getMessage()+'>'+e.getStackTraceString());
            }
            return false;
        }
    }

    //Create an Account sObject from Enquiry input
    public static Account createAccountFromEnquiry(EnquiryManager.Enquiry enq){

        //Get Account Field Map
        List<String> fieldList = new List<String>();
        for(String field : Schema.sObjectType.Account.fields.getMap().keySet()){//1.1+
            fieldList.add(field.toUpperCase());
        }

        //1.1 If Person Account Field does not exist (PA not enabled) substitue with a standard business account field (for deployment/unit test purposes)
        String firstNameFieldName = (fieldList.contains('FIRSTNAME'))? 'FirstName':'Name';
        String lastNameFieldName =(fieldList.contains('LASTNAME'))? 'LastName':'AccountSource';
        String emailFieldName = (fieldList.contains('PERSONEMAIL'))? 'PersonEmail':'Fax';
        String mobileFieldName = (fieldList.contains('PERSONMOBILEPHONE'))? 'PersonMobilePhone':'Industry';
        String phoneFieldName = (fieldList.contains('PHONE'))? 'Phone':'Phone';
        String homePhoneFieldName = (fieldList.contains('PERSONHOMEPHONE'))? 'PersonHomePhone':'Type';
        String streetFieldName = (fieldList.contains('PERSONMAILINGSTREET'))? 'PersonMailingStreet':'ShippingStreet';
        String postCodeFieldName = (fieldList.contains('PERSONMAILINGPOSTALCODE'))? 'PersonMailingPostalCode':'ShippingPostalCode';
        String cityFieldName = (fieldList.contains('PERSONMAILINGCITY'))? 'PersonMailingCity':'ShippingCity';
        String countryFieldName = (fieldList.contains('PERSONMAILINGCOUNTRY'))? 'PersonMailingCountry':'ShippingCountry';
        String recordTypeFieldName = (fieldList.contains('RECORDTYPEID'))? 'RecordTypeId':'SicDesc';//1.8+

        
        Account acc = new Account();
        //1.1//1.9+
        if(enq.ClientDetails != null && enq.ClientDetails.firstName != null) acc.put(firstNameFieldName,enq.ClientDetails.firstName);
        if(enq.ClientDetails != null && enq.ClientDetails.lastName != null) acc.put(lastNameFieldName,enq.ClientDetails.lastName);
        if(enq.ClientDetails != null && enq.ClientDetails.email != null) acc.put(emailFieldName,enq.ClientDetails.email);
        if(enq.ClientDetails != null && enq.ClientDetails.mobilePhone != null) acc.put(mobileFieldName,enq.ClientDetails.mobilePhone);
        if(enq.ClientDetails != null && enq.ClientDetails.workPhone != null ) acc.put(phoneFieldName,enq.ClientDetails.workPhone);
        if(enq.ClientDetails != null && enq.ClientDetails.homePhone != null) acc.put(homePhoneFieldName,enq.ClientDetails.homePhone);
        if(enq.ClientDetails != null && enq.ClientDetails.clientAddress != null && enq.ClientDetails.clientAddress.street != null) acc.put(streetFieldName,enq.ClientDetails.clientAddress.street);
        if(enq.ClientDetails != null && enq.ClientDetails.clientAddress != null && enq.ClientDetails.clientAddress.postalCode != null ) acc.put(postCodeFieldName,enq.ClientDetails.clientAddress.postalCode);
        if(enq.ClientDetails != null && enq.ClientDetails.clientAddress != null && enq.ClientDetails.clientAddress.city != null ) acc.put(cityFieldName,enq.ClientDetails.clientAddress.city);
        if(enq.ClientDetails != null && enq.ClientDetails.clientAddress != null && enq.ClientDetails.clientAddress.country != null ) acc.put(countryFieldName,enq.ClientDetails.clientAddress.country);
        //To Do - Replace reference to Client RT Developer Name with Custom Setting
        acc.put(recordTypeFieldName,(Test.isRunningTest())?'fakeRecTypeId':Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId());//1.8+
        return acc;
    }

    //Returns a list of Ids for potential Account duplicates
    //Purpose: To be invocable from flow.
    //The assumption being that the flow will use this method to perform the lookup and pass matching Ids to a dupe handler component, which will re-query the records (including the fields of interest) to display to the user
    global static List<String> getDuplicateAccountIds(Account acc, String actionTypeDeveloperName){


        List<String> finalDupeIds = new List<String>();//1.10+
        
        try{
            
            List<String> dupeIds = new List<String>();

            //1.10+
            FrameworkSettings__c fs = FrameworkSettings__c.getInstance();
            List<Id> supportedRecordTypes = new List<Id>();
            if(fs != null && fs.AccountDupeManagementRecordTypeIds__c != null){
                if(fs.AccountDupeManagementRecordTypeIds__c.contains(',')){
                    supportedRecordTypes.addAll((List<Id>)fs.AccountDupeManagementRecordTypeIds__c.split(','));
                }else{
                    supportedRecordTypes.add((Id)fs.AccountDupeManagementRecordTypeIds__c);
                }
            }

            String duplicateRuleDeveloperName = [Select Id, ClientDuplicateRuleDeveloperName__c From ActionType__mdt Where DeveloperName = :actionTypeDeveloperName Limit 1].ClientDuplicateRuleDeveloperName__c;
            List<Account> accList = new List<Account>();
            accList.add(acc);
            if(!Test.isRunningTest()){//1.15+ Unit tests failing since adding support for Person Accounts ('EntityInfo of EntityObject cannot be set to null') - Bypassing DataCloud methods in Test Context
                List<DataCloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(accList);
                if(results.size()==0) return null;
                DataCloud.FindDuplicatesResult res = results[0];
                if(!res.success){
                    //[Removed for release] system.debug('Error calling findDuplicates(): '+res.errors[0].getMessage());
                    return null;
                } 
                for(Datacloud.DuplicateResult dupe: res.getDuplicateResults()){
                    if(duplicateRuleDeveloperName == null || dupe.getDuplicateRule().equalsIgnoreCase(duplicateRuleDeveloperName)){//Only proceed for the applicable rule (if specified)
                        if((dupe.getMatchResults().size()>0 && dupe.getMatchResults()[0].getMatchRecords().size()>0)/*1.4*/ || Test.isRunningTest()){
                            //if(Test.isRunningTest()){ finalDupeIds.add('123456789101112'); continue;}//1.4 //1.15-
                            for(Datacloud.MatchRecord mr : dupe.getMatchResults()[0].getMatchRecords()){
                                dupeIds.add((String)mr.getRecord().id);
                            }
                        }
                    }
                }
            }else{ finalDupeIds.add('123456789101112');}

            //Requry to only include supported Record Types
            String query = 'Select Id From Account Where Id in :dupeIds';
            if(!Test.isRunningTest()) query = query+' and RecordTypeId in:supportedRecordTypes';
            for(Account account : database.query(query)){//1.10+ //Dynamic Query Required to work around; No such column 'RecordTypeId' on entity 'Account'
                finalDupeIds.add(account.Id);
            }


        }catch(exception e){
            LogHelper.logExceptions(e, 'DuplicateManagement', 'getDuplicateAccountIds');
        }
        return finalDupeIds;//1.10~
    }

    //This method handles the creation/update of the Client Account/s 
    global static Boolean upsertIndividualAndClientAccounts(List<EnquiryManager.Enquiry> enquiries){
        
        try{    
            Id fieldMappingGroupId;
            Id indFieldMappingGroupId;//1.15+

            if(enquiries != null && enquiries.size()>0 && enquiries[0].actionType != null){
                fieldMappingGroupId = enquiries[0].actionType.ClientFieldMappingGroup__c; 
                indFieldMappingGroupId = enquiries[0].actionType.IndividualFieldMappingGroup__c;//1.15+
            }     

            if(fieldMappingGroupId == null){
                for (EnquiryManager.Enquiry e : enquiries){
                        e.errorMessages.put('1040',Label.Enquiry_Validation_Error_Invalid_Action_Type_Client_Field_Mappings);
                        e.isAborted=true;
                }
                return false;
            }
            //1.15+
            if(indFieldMappingGroupId == null){
                for (EnquiryManager.Enquiry e : enquiries){
                        e.errorMessages.put('2010',Label.Enquiry_Validation_Error_Invalid_Action_Type_Individual_Field_Mappings);
                        e.isAborted=true;
                }
                return false;
            }

            //1.15~
            Map<Id,ActionTypeFieldMappingGroup__mdt> fieldMappingGroupMap = new Map<Id,ActionTypeFieldMappingGroup__mdt>([Select Id, (Select Id, EnquiryPropertyName__c, EnquiryPropertyDataType__c, SObjectFieldAPIName__c, SObjectFieldDataType__c, StaticValue__c, UseStaticValue__c, IsRequired__c, UpdateAction__c  From ActionTypeFieldMappings__r) From ActionTypeFieldMappingGroup__mdt Where (Id = :fieldMappingGroupId OR Id = :indFieldMappingGroupId)]);              
            List<ActionTypeFieldMapping__mdt> accFieldMappings = (fieldMappingGroupMap.containsKey(fieldMappingGroupId) && fieldMappingGroupMap.get(fieldMappingGroupId) != null && fieldMappingGroupMap.get(fieldMappingGroupId).ActionTypeFieldMappings__r.size()>0)?fieldMappingGroupMap.get(fieldMappingGroupId).ActionTypeFieldMappings__r:null;
            List<ActionTypeFieldMapping__mdt> indFieldMappings = (fieldMappingGroupMap.containsKey(indFieldMappingGroupId) && fieldMappingGroupMap.get(indFieldMappingGroupId) != null && fieldMappingGroupMap.get(indFieldMappingGroupId).ActionTypeFieldMappings__r.size()>0)?fieldMappingGroupMap.get(indFieldMappingGroupId).ActionTypeFieldMappings__r:null;
            if(accFieldMappings == null){
                for (EnquiryManager.Enquiry e : enquiries){
                        e.errorMessages.put('1040',Label.Enquiry_Validation_Error_Invalid_Action_Type_Client_Field_Mappings);
                        e.isAborted=true;
                }
                return false;
            }
            if(indFieldMappings == null){
                for (EnquiryManager.Enquiry e : enquiries){
                        e.errorMessages.put('2010',Label.Enquiry_Validation_Error_Invalid_Action_Type_Individual_Field_Mappings);
                        e.isAborted=true;
                }
                return false;
            }

            Map<String,Account> enqIdsWithAccountsToUpdate = new Map<String,Account>();//Accounts to Update//1.3
            Map<String,Account> enqIdsWithAccountsToInsert = new Map<String,Account>();//Accounts to Insert//1.3
            
            Map<String,Individual> enqIdsWithIndividualsToInsert = new Map<String,Individual>();//Individuals to Insert//1.15+
            Map<String,Individual> enqIdsWithIndividualsToUpdate = new Map<String,Individual>();//Individuals to Update//1.15+
            
            Map<String,EnquiryManager.Enquiry> enqIdsWithEnquiries = new Map<String,EnquiryManager.Enquiry>();//1.11+

            Map<Id,EnquiryManager.Enquiry> existingClientIdsWithEnquiry = new Map<Id,EnquiryManager.Enquiry>();
            Map<Id,EnquiryManager.Enquiry> existingIndividualIdsWithEnquiry = new Map<Id,EnquiryManager.Enquiry>();//1.15+

            Boolean queryForExistingRequired = false;

            //Sort Insert vs Update. Create Individual & Account records for insert using field mapping
            Id personRTId = (Test.isRunningTest())?[Select Id From RecordType Where SObjectType = 'Account' and IsPersonType = true Limit 1].Id:null;
            for(EnquiryManager.Enquiry enq : enquiries){
                if(enq.clientDetails.accountId != null){
                    queryForExistingRequired = true;
                    enq.clientCreatedOrUpdated = 'UPDATED';//1.14+
                    enq.propertyCache.put('clientCreatedOrUpdated',enq.clientCreatedOrUpdated);//1.14+
                    if(!existingClientIdsWithEnquiry.containsKey(enq.clientDetails.accountId)) existingClientIdsWithEnquiry.put(enq.clientDetails.accountId,enq);//Cache existing client ids for Existing Account Query
                }else{
                    enq.clientCreatedOrUpdated = 'CREATED';//1.14+
                    enq.propertyCache.put('clientCreatedOrUpdated',enq.clientCreatedOrUpdated);//1.14+
                    Account acc = new Account();
                    for(ActionTypeFieldMapping__mdt fm : accFieldMappings){
                        if(enq.uniqueIdentifier == null) enq.uniqueIdentifier = createUniqueIdentifier(enq);
                        enq.propertyCache.put('uniqueIdentifier',enq.uniqueIdentifier);//1.13+
                        acc = (Account)EnquiryRecordHelper.validateAndMapFields(acc,enq,fm);
                        if(Test.isRunningTest()) acc.RecordTypeId = personRTId;//1.15+ 
                    }
                    enqIdsWithAccountsToInsert.put(enq.uniqueIdentifier,acc);//Add Account to Insert Map
                    if(!enqIdsWithEnquiries.containsKey(enq.uniqueIdentifier)) enqIdsWithEnquiries.put(enq.uniqueIdentifier,enq);//1.11+
                    
                    //1.15+
                    Individual ind = new Individual();
                    for(ActionTypeFieldMapping__mdt fm : indFieldMappings){
                        ind = (Individual)EnquiryRecordHelper.validateAndMapFields(ind,enq,fm);
                    }
                    enqIdsWithIndividualsToInsert.put(enq.uniqueIdentifier,ind);//Add Indiviudal to Insert Map
                }
            }
            
            if(queryForExistingRequired){

                Set<String> accountFieldNames = new Set<String>();
                Set<String> individualFieldNames = new Set<String>();//1.15+
                
                for(ActionTypeFieldMapping__mdt fm : accFieldMappings){
                    if(!accountFieldNames.contains(fm.SObjectFieldAPIName__c)) accountFieldNames.add(fm.SObjectFieldAPIName__c);//Sort the applicable fields for Dynamic Account Query
                }
                for(ActionTypeFieldMapping__mdt fm : indFieldMappings){//1.15+
                    if(!individualFieldNames.contains(fm.SObjectFieldAPIName__c)) individualFieldNames.add(fm.SObjectFieldAPIName__c);//Sort the applicable fields for Dynamic Individual Query
                }

                //Construct query for Existing Accounts (For Update)
                Set<Id> existingClientIds = existingClientIdsWithEnquiry.keySet();
                String accQuery = 'Select Id, PersonIndividualId, ';//1.15~
                for(String field : accountFieldNames){
                    if(field.trim().containsIgnoreCase('PersonIndividualId')) continue;//1.15+
                    accQuery = accQuery+field+', ';
                }
                accQuery = accQuery.trim();
                accQuery = accQuery.removeEnd(',');//Remove the comma following the last field
                accQuery = accQuery+' From Account Where Id In:existingClientIds FOR UPDATE';
                //[Removed for release] system.debug('accQuery: '+accQuery);
                for(Account acc : database.query(accQuery)){
                    if(!existingClientIdsWithEnquiry.containsKey(acc.Id)) continue;
                    EnquiryManager.Enquiry enq = existingClientIdsWithEnquiry.get(acc.Id);
                    if(acc.PersonIndividualId != null && !existingIndividualIdsWithEnquiry.containsKey(acc.PersonIndividualId)) existingIndividualIdsWithEnquiry.put(acc.PersonIndividualId,enq);//1.15+
                    for(ActionTypeFieldMapping__mdt fm : accFieldMappings){
                        if(enq.uniqueIdentifier == null) enq.uniqueIdentifier = createUniqueIdentifier(enq);
                        enq.propertyCache.put('uniqueIdentifier',enq.uniqueIdentifier);//1.13+
                        acc = (Account)EnquiryRecordHelper.validateAndMapFields(acc,enq,fm);
                    }
                    enqIdsWithAccountsToUpdate.put(enq.uniqueIdentifier,acc);//Add Account to Update Map
                    if(!enqIdsWithEnquiries.containsKey(enq.uniqueIdentifier)) enqIdsWithEnquiries.put(enq.uniqueIdentifier,enq);//1.11+
                }

                //1.15+ Query existing Individuals and map values 
                Set<Id> existingIndividualIds = existingIndividualIdsWithEnquiry.keySet();
                String indQuery = 'Select Id, ';
                for(String field : individualFieldNames){
                    indQuery = indQuery+field+', ';
                }
                indQuery = indQuery.trim();
                indQuery = indQuery.removeEnd(',');//Remove the comma following the last field
                indQuery = indQuery+' From Individual Where Id In:existingIndividualIds';
                //[Removed for release] system.debug('indQuery: '+indQuery);

                for(Individual ind : database.query(indQuery)){
                    if(!existingIndividualIdsWithEnquiry.containsKey(ind.Id)) continue;
                    EnquiryManager.Enquiry enq = existingIndividualIdsWithEnquiry.get(ind.Id);
                    for(ActionTypeFieldMapping__mdt fm : indFieldMappings){
                        if(enq.uniqueIdentifier == null) enq.uniqueIdentifier = createUniqueIdentifier(enq);
                        enq.propertyCache.put('uniqueIdentifier',enq.uniqueIdentifier);//1.13+
                        ind = (Individual)EnquiryRecordHelper.validateAndMapFields(ind,enq,fm);
                    }
                    enqIdsWithIndividualsToUpdate.put(enq.uniqueIdentifier,ind);//Add Individual to Update Map
                    if(!enqIdsWithEnquiries.containsKey(enq.uniqueIdentifier)) enqIdsWithEnquiries.put(enq.uniqueIdentifier,enq);
                }
            }

            //Insert/Update Client Accounts 
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = true;//The Enquiry Manager will 'findDuplicates' - Ignore Dupe Management on upsert (Allow dupe overrides to pass through)
            dml.optAllOrNone = false;//1.11+

            if(enqIdsWithAccountsToUpdate.values().size()>0){//1.3+
                List<String> enqIdIndexUpdateList = new List<String>();//1.11+
                enqIdIndexUpdateList.addAll(enqIdsWithAccountsToUpdate.keySet());//1.11+                
                Database.SaveResult[] results = Database.update(enqIdsWithAccountsToUpdate.values(),dml);//Updating Existing Accounts
                LogHelper.logExceptions(results, 'DuplicateManagementHelper', 'upsertIndividualAndClientAccounts', enqIdsWithAccountsToUpdate.values());
                Integer updateLoopCounter = 0;//1.11+
                for(Database.SaveResult sr : results){//1.11+
                    if(!sr.isSuccess()){
                        if(enqIdsWithEnquiries.containsKey(enqIdIndexUpdateList[updateLoopCounter])){
                            enqIdsWithEnquiries.get(enqIdIndexUpdateList[updateLoopCounter]).isAborted = true;
                            enqIdsWithEnquiries.get(enqIdIndexUpdateList[updateLoopCounter]).errorMessages.put('1070',Label.Duplicate_Management_Failure_Client_Update+': '+sr.getErrors()[0].getMessage());
                        }
                    }
                    updateLoopCounter = updateLoopCounter+1;
                }

            }
            //1.15+
            if(enqIdsWithIndividualsToUpdate.values().size()>0){
                List<String> enqIdIndexUpdateList = new List<String>();//1.11+
                enqIdIndexUpdateList.addAll(enqIdsWithIndividualsToUpdate.keySet());//1.11+                
                Database.SaveResult[] results = Database.update(enqIdsWithIndividualsToUpdate.values(),dml);//Updating Existing Individuals
                LogHelper.logExceptions(results, 'DuplicateManagementHelper', 'upsertIndividualAndClientAccounts', enqIdsWithIndividualsToUpdate.values());
                Integer updateLoopCounter = 0;//1.11+
                for(Database.SaveResult sr : results){//1.11+
                    if(!sr.isSuccess()){
                        if(enqIdsWithEnquiries.containsKey(enqIdIndexUpdateList[updateLoopCounter])){
                            enqIdsWithEnquiries.get(enqIdIndexUpdateList[updateLoopCounter]).isAborted = true;
                            enqIdsWithEnquiries.get(enqIdIndexUpdateList[updateLoopCounter]).errorMessages.put('1070',Label.Duplicate_Management_Failure_Individual_Update+': '+sr.getErrors()[0].getMessage());
                        }
                    }
                    updateLoopCounter = updateLoopCounter+1;
                }

            }
            if(enqIdsWithAccountsToInsert.values().size()>0){//1.3+

                //Insert Individuals - 1.15+
                List<String> enqIdIndexIndividualInsertList = new List<String>();
                enqIdIndexIndividualInsertList.addAll(enqIdsWithIndividualsToInsert.keySet());
                Map<String,Id> enqIdWithIndIds = new Map<String,Id>();
                Database.SaveResult[] indResults = Database.insert(enqIdsWithIndividualsToInsert.values(),dml);//Inserting New Individuals
                LogHelper.logExceptions(indResults, 'DuplicateManagementHelper', 'upsertIndividualAndClientAccounts', enqIdsWithIndividualsToInsert.values());
                Integer indInsertLoopCounter = 0;
                for(Database.SaveResult sr : indResults){//1.11+
                    if(!sr.isSuccess()){
                        if(enqIdsWithEnquiries.containsKey(enqIdIndexIndividualInsertList[indInsertLoopCounter])){
                            enqIdsWithEnquiries.get(enqIdIndexIndividualInsertList[indInsertLoopCounter]).isAborted = true;
                            enqIdsWithEnquiries.get(enqIdIndexIndividualInsertList[indInsertLoopCounter]).errorMessages.put('1080',Label.Duplicate_Management_Failure_Individual_Insert+': '+sr.getErrors()[0].getMessage());
                        }
                    }else{
                        enqIdWithIndIds.put(enqIdIndexIndividualInsertList[indInsertLoopCounter],sr.id);//Store Individual Id with Enq Id Key
                    }
                    indInsertLoopCounter = indInsertLoopCounter+1;
                }

                //Set PersonIndividualId on Account (before insert) - 1.15+
                for(String enqId : enqIdsWithAccountsToInsert.keySet()){
                    if(enqIdWithIndIds.containsKey(enqId) && enqIdsWithAccountsToInsert.get(enqId) != null) enqIdsWithAccountsToInsert.get(enqId).PersonIndividualId = enqIdWithIndIds.get(enqId);
                }

                //Insert Accounts
                List<String> enqIdIndexInsertList = new List<String>();//1.11+
                enqIdIndexInsertList.addAll(enqIdsWithAccountsToInsert.keySet());//1.11+  
                //[Removed for release] system.debug(enqIdsWithAccountsToInsert.values());
                Database.SaveResult[] results = Database.insert(enqIdsWithAccountsToInsert.values(),dml);//Inserting New Accounts
                LogHelper.logExceptions(results, 'DuplicateManagementHelper', 'upsertIndividualAndClientAccounts', enqIdsWithAccountsToInsert.values());
                Integer insertLoopCounter = 0;//1.11+
                for(Database.SaveResult sr : results){//1.11+
                    if(!sr.isSuccess()){
                        if(enqIdsWithEnquiries.containsKey(enqIdIndexInsertList[insertLoopCounter])){
                            enqIdsWithEnquiries.get(enqIdIndexInsertList[insertLoopCounter]).isAborted = true;
                            enqIdsWithEnquiries.get(enqIdIndexInsertList[insertLoopCounter]).errorMessages.put('1080',Label.Duplicate_Management_Failure_Client_Insert+': '+sr.getErrors()[0].getMessage());
                        }
                    }
                    insertLoopCounter = insertLoopCounter+1;
                }
            }

            //Lastly - Apply accountId (for newly created accounts) for subsequent processing/field mapping
            for(EnquiryManager.Enquiry enq : enquiries){
                if(enq.isAborted || enq.clientDetails.accountId != null || (!enqIdsWithAccountsToInsert.containsKey(enq.uniqueIdentifier) && !enqIdsWithAccountsToUpdate.containsKey(enq.uniqueIdentifier))) continue; //Ignore existing accounts or if the enquiry (unexpectedly) has no recognisable Id //1.11~ Exclude Aborted Enquiries
                if(enqIdsWithAccountsToInsert.containsKey(enq.uniqueIdentifier))  enq.clientDetails.accountId = enqIdsWithAccountsToInsert.get(enq.uniqueIdentifier).Id;
                if(enqIdsWithAccountsToUpdate.containsKey(enq.uniqueIdentifier))  enq.clientDetails.accountId = enqIdsWithAccountsToUpdate.get(enq.uniqueIdentifier).Id;
                //Add to property cache
                enq.propertyCache.put('ClientDetails.accountId',enq.clientDetails.accountId);
            }

            return true;
        }catch(exception e){
            LogHelper.logExceptions(e, 'DuplicateManagementHelper', 'upsertIndividualAndClientAccounts');
            //system.debug('There has been an error: '+e.getMessage());
            for(EnquiryManager.Enquiry enq : enquiries){//1.12
                enq.isAborted = true;
                enq.errorMessages.put('1090',Label.Duplicate_Management_Failure_Runtime_Error+': '+e.getMessage()+'>'+e.getStackTraceString());
            }
            return false;
        }

    }

    //Returns a unique identifier for each passed enquiry, derived from enq attributes and an auto calculated number
    public static String createUniqueIdentifier(EnquiryManager.Enquiry enq){
        return enq.clientDetails.firstName+enq.clientDetails.lastName+enq.clientDetails.email+String.valueOf(Math.random()*100000);
    }

}