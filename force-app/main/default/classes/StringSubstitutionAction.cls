/*
Name:  StringSubstitutionAction
======================================================
======================================================
Purpose:
-------
This class provides an invocable Apex action that can be used within Salesforce Flows.
It allows for the substitution of one value with another in a given string, with error handling.
If the input string is null, it returns a blank string instead of throwing an error.

Usage Example: Marketing Cloud will map data through from a Data Extension to a Multi Select Picklist with comma separated
list of values. This can be used before insert to transform the value into a picklist friendly format by replacing commas with semi-colons.
======================================================
======================================================


History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-19  Initial development.
*/
public with sharing class StringSubstitutionAction {

    @InvocableMethod(label='String Substitution Action' description='Substitute a value in a string')
    public static List<SubstitutionResult> substituteValue(List<SubstitutionRequest> requests) {
        List<SubstitutionResult> results = new List<SubstitutionResult>();

        try{

            for (SubstitutionRequest request : requests) {
                SubstitutionResult result = new SubstitutionResult();

                String inputString = request.InputString;
                String oldValue = request.OldValue;
                String newValue = request.NewValue;

                if (inputString != null) {
                    String substitutedString = inputString.replace(oldValue, newValue);
                    result.SubstitutedString = substitutedString;
                } else {
                    result.SubstitutedString = null; // Set the result to null if inputString is null
                }

                results.add(result);
            }

            return results;

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'StringSubstitutionAction','substituteValue');
            return results;
        }

    }

    public class SubstitutionRequest {
        @InvocableVariable(label='Input String' required=true)
        public String InputString;

        @InvocableVariable(label='Old Value' required=true)
        public String OldValue;

        @InvocableVariable(label='New Value' required=true)
        public String NewValue;
    }

    public class SubstitutionResult {
        @InvocableVariable(label='Substituted String')
        public String SubstitutedString;
    }
}