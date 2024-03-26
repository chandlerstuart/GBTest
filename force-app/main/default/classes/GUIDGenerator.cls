/*
Name:  GUIDGenerator.cls
======================================================
======================================================
Purpose: The generation and assignment of Globally Unique 
Identifiers (GUIDs) to records of various Salesforce objects. 
-------
======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  J Radcliffe  2024-02-12  Initial development.
*/
public class GUIDGenerator {

    public class GUIDGeneratorException extends Exception {}

    private static Map<String, Boolean> sObjectTypesToCheckMap = new Map<String, Boolean>();

    public static void assignPublicId(List<SObject> records) {

        try {

            //Temporary flag for supporting phased feature rollout
            Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getOrgDefaults();
            if(!pcr.ActivatePublicIdGeneration__c) return; 

            for (SObject record : records) {
                String sObjectType = record.getSObjectType().getDescribe().getName();
                
                if (!sObjectTypesToCheckMap.containsKey(sObjectType)) {

                    //Check if the object type has a PublicId__c field
                    Boolean hasPublicIdField = sObjectHasPublicIdField(sObjectType);
                    sObjectTypesToCheckMap.put(sObjectType, hasPublicIdField);

                    // If the SObject type doesn't have PublicId__c, throw an exception
                    if (!hasPublicIdField) {
                        throw new GUIDGeneratorException('PublicId__c field does not exist on object ' + sObjectType);
                    }
                }

                // If the SObject type has PublicId__c, generate and assign the UUID
                if (sObjectTypesToCheckMap.get(sObjectType)) {
                    // Generate a UUID
                    String uuidStr = UUID.randomUUID().toString();
                    // Assign the UUID to the PublicId__c field
                    record.put('PublicId__c', uuidStr);
                }
            }
        } catch (GUIDGeneratorException e) {
            System.debug('Exception: ' + e.getMessage()+'-'+e.getStackTraceString());
            Golfbreaks.PlatformLogManager.logExceptions(e,'GUIDGenerator','assignPublicId');
        }
    }

    private static Boolean sObjectHasPublicIdField(String sObjectType) {
        if (!Schema.getGlobalDescribe().containsKey(sObjectType)) {
            return false;
        }

        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
        return fieldsMap.containsKey('PublicId__c');
    }
}