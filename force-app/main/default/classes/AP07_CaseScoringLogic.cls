/**
* @author Majoy Maliñana
* @date 2016
* @description Logic for setting Case Scoring upon inserting or updating Lead record.
*/

/**
 ** @Edited by: Nicole De Guzman 03/04/2016
 ** @Class Name: AP07_CaseScoringLogic
 ** @Description: Code clean-up - Replaced all newCaseMap to newCaseList
 ** @Revision:
 ** Jerome To - May 30, 2016 - Recode logical operators in comparing numerical values on FieldValue vs Value
 **
 **/
public with sharing class AP07_CaseScoringLogic{

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP07_CaseScoringLogic';
        
    public static Map<Id, LeadScoringRule__c> leadScoringRuleByRecordType = new Map<Id, LeadScoringRule__c>();
    
    // method for setting case score
    public static void setCaseScore(List<Case> newCaseList, Boolean isFromTrigger){
        System.debug('setCaseScore --- Start');
        System.debug(newCaseList.size());
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([SELECT Id,Name FROM RecordType WHERE SobjectType=:'Case']); 
        Map<String, Id> caseAndRecordTypeMap = new Map<String, Id>();
        String caseIdentifier = '';
        
        AssignmentRule AR;
        Database.DMLOptions dmlOpts;
        
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        
        try{
            for(Case caseRecord: newCaseList){
                caseIdentifier = caseRecord.CaseNumber+caseRecord.AccountId+caseRecord.Type+caseRecord.Status+caseRecord.Origin+caseRecord.BusinessHoursId+caseRecord.Description+caseRecord.Id+caseRecord.Booking__c+caseRecord.Category__c+caseRecord.SubCategory__c;
                caseAndRecordTypeMap.put(caseIdentifier, caseRecord.RecordTypeId);
            }
            
            getLeadScoringRuleByRecordType(caseAndRecordTypeMap.values());
            Map<String, Decimal> caseAndScoringMap = new Map<String, Decimal>();
            Map<String, String> describedFieldsMap = getDescribeFields();
           
            for(Case caseRecord: newCaseList){
                caseIdentifier = caseRecord.CaseNumber+caseRecord.AccountId+caseRecord.Type+caseRecord.Status+caseRecord.Origin+caseRecord.BusinessHoursId+caseRecord.Description+caseRecord.Id+caseRecord.Booking__c+caseRecord.Category__c+caseRecord.SubCategory__c;
                for(LeadScoringRule__c lsr: leadScoringRuleByRecordType.values()){
                    if(lsr.RecordType__c.equals(caseRecord.RecordTypeId) && 
                        checkMatching(caseRecord, lsr, describedFieldsMap)){
                        if(!caseAndScoringMap.containsKey(caseIdentifier)){
                            caseAndScoringMap.put(caseIdentifier, 0);
                        }
                        
                        System.debug('setCaseScore --- field: ' + lsr.FieldLabel__c + ' points: ' + lsr.Points__c);
                        caseAndScoringMap.put(caseIdentifier, caseAndScoringMap.get(caseIdentifier) + lsr.Points__c);
                    }
                }
            }
            
            Map<Id, LeadScoreMapping__c> scoreMap = getScoreMapping();
            List<Case> casesToUpdate = new List<Case>();
            
            Decimal points = 0;
            for(Case caseRecord: newCaseList){
                caseIdentifier = caseRecord.CaseNumber+caseRecord.AccountId+caseRecord.Type+caseRecord.Status+caseRecord.Origin+caseRecord.BusinessHoursId+caseRecord.Description+caseRecord.Id+caseRecord.Booking__c+caseRecord.Category__c+caseRecord.SubCategory__c;
                if(caseAndScoringMap.containsKey(caseIdentifier)){
                    points = caseAndScoringMap.get(caseIdentifier);
                    caseRecord.Priority = getCasePriority(points, scoreMap);
                    System.debug('========'+caseRecord.Priority+'===========');
                    caseRecord.Points__c = points;
                    caseRecord.CaseScoreAppliedDate__c = Date.today();
                    caseRecord.setOptions(dmlOpts);
                    casesToUpdate.add(caseRecord);
                }
            }
            
            if(!isFromTrigger && casesToUpdate.size() > 0){
                Database.SaveResult[] updateCaseList = Database.update(casesToUpdate, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateCaseList, 'setCaseScore()', CLASS_NAME, ApplicationConstant.CASE_SOBJECTTYPE, 'Update'));
            }
        }catch(Exception e){
           System.debug('====== error ======' + e.getMessage());
           logs.add(ApplicationConstant.getExceptionLog(e, 'setCaseScore()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('setCaseScore --- Start');
    }
    
    //method of getting lead scoring rule based on record type
    private static void getLeadScoringRuleByRecordType(List<Id> recordTypeIds){
        System.debug('getLeadScoringRuleByRecordType --- Start');
        if(leadScoringRuleByRecordType.size()==0){
            leadScoringRuleByRecordType = new Map<Id, LeadScoringRule__c>([SELECT Id,Name,Active__c,FieldLabel__c,Operator__c,RecordTypeId,RecordType__c,Value__c,MinimumValue__c,MaximumValue__c,Points__c FROM 
               LeadScoringRule__c WHERE RecordType__c IN :recordTypeIds AND Active__c = true AND FieldLabel__c <> '']);
        }
        System.debug('getLeadScoringRuleByRecordType --- End');
    }
    
    // Updated for D-0733 By Dee 06/21/2016
    private static Boolean checkMatching(Case caseRecord, LeadScoringRule__c lsr, Map<String, String> describedFieldsMap){
        System.debug('checkMatching --- Start: ' + lsr.Operator__c);
        
        Boolean isMatch = false;
        String fieldValue = getFieldValue(caseRecord, lsr.FieldLabel__c, describedFieldsMap);
        
        if(lsr.Operator__c.equals('equals') && !String.isEmpty(fieldValue) && 
            (fieldValue.equalsIgnoreCase(lsr.Value__c) || (isStringNumeric(lsr.Value__c) && isStringNumeric(fieldValue) && (Decimal.valueOf(lsr.Value__c) == Decimal.valueOf(fieldValue)) ) ) ){
            isMatch = true;
        }

        else if(lsr.Operator__c.equals('not equals') && !String.isEmpty(fieldValue) && ((!isStringNumeric(lsr.Value__c) && !fieldValue.equalsIgnoreCase(lsr.Value__c)) || 
             (isStringNumeric(lsr.Value__c) && isStringNumeric(fieldValue) && (Decimal.valueOf(lsr.Value__c) != Decimal.valueOf(fieldValue))))) {
            isMatch = true;
        }

        else if(lsr.Operator__c.equals('contains') && !String.isEmpty(fieldValue) && fieldValue.containsIgnoreCase(lsr.Value__c)){
            isMatch = true;
        }
        else if(lsr.Operator__c.equals('starts with') && !String.isEmpty(fieldValue) && fieldValue.startsWithIgnoreCase(lsr.Value__c)){
            isMatch = true;
        }

        else if(lsr.Operator__c.equals('less than/greater than') && !String.isEmpty(fieldValue) && 
                isStringNumeric(fieldValue) && isInRange(fieldValue, lsr)){
            isMatch = true;
        }

        else{
            isMatch = false;
        }
        
        System.debug('checkMatching --- End, Match Found? ' + isMatch);
        return isMatch;
    }
    
    private static String getFieldValue(Case caseRecord, String fieldLabel, Map<String, String> describedFieldsMap){
        System.debug('getFieldValue --- Start');
        String fieldValue = '';
        String fieldApi = '';
        
        if(describedFieldsMap.containsKey(fieldLabel)){
            fieldApi = describedFieldsMap.get(fieldLabel);
        }
        
        if(fieldLabel.equals('Case Status') && String.isEmpty(fieldApi)){
            fieldApi = 'Status';
        }
         // May 10 2016 Merari Cebrian -- Added error handler if fieldApi is blank
        fieldValue = String.isNotBlank(fieldApi) ?  String.valueOf(caseRecord.get(fieldApi)) : '';
        
        System.debug('getFieldValue --- End, Field Value = ' + fieldValue);
        return fieldValue;
    }
    
    // Added 5/14/2016 --- Dee
    private static Map<String, String> getDescribeFields(){
    
        Map<String, String> describedFieldsMap = new Map<String, String>();
        
        Map<String, Schema.SObjectField> ObjectFieldMap =
            Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
        
        for(String key : ObjectFieldMap.KeySet()){
            describedFieldsMap.put(ObjectFieldMap.get(key).getDescribe().getLabel(), key);
        }
        
        return describedFieldsMap;
    }
    
    private static Map<Id, LeadScoreMapping__c> getScoreMapping(){
        return new Map<Id, LeadScoreMapping__c>([SELECT Id, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c, CasePriority__c FROM 
            LeadScoreMapping__c Where RuleType__c = 'Case' AND
            LeadScoreMaximumValue__c <> null AND LeadScoreMinimumValue__c <> null AND CasePriority__c <> '']);
    }
    
    private static String getCasePriority(Decimal score, Map<Id, LeadScoreMapping__c> scoreMap){
        System.debug('getCasePriority --- Start');
        System.debug('Points --- ' + score);

        String Priority = '';
        for(LeadScoreMapping__c scoreMapRecord: scoreMap.values()){
            System.debug('Max --- ' + scoreMapRecord.LeadScoreMaximumValue__c );
            System.debug('Min --- ' + scoreMapRecord.LeadScoreMinimumValue__c );
            System.debug('CasePriority__c --- ' + scoreMapRecord.LeadScoreMaximumValue__c );
            if(scoreMapRecord.LeadScoreMaximumValue__c >= score && scoreMapRecord.LeadScoreMinimumValue__c <= score){
                Priority = scoreMapRecord.CasePriority__c;
            }
        }
        
        System.debug('getCasePriority --- End, Priority = ' + Priority);
        return Priority;
    }
    
    private static Boolean isInRange(String fieldValue, LeadScoringRule__c lsr){

        Boolean isMatch = true;
        Decimal numValue = Decimal.valueOf(fieldValue);
        if(lsr.MinimumValue__c <> null && (Decimal)lsr.MinimumValue__c > numValue){
            isMatch = false;
        }
        
        if(lsr.MaximumValue__c <> null && (Decimal)lsr.MaximumValue__c < numValue){
            isMatch = false;
        }
        
        return isMatch;
        
    }
    
    // Added for D-0733 By Dee 06/21/2016
    private static Boolean isStringNumeric(String fieldValue){
        try{
            Decimal.valueOf(fieldValue);
        }catch(TypeException e){
            return false;
        }
        
        return true;
    }

}