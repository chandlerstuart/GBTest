/*
Name:  StringSubstitutionActionTest
======================================================
======================================================
Purpose:
-------
Test Suite for StringSubstitutionAction.cls
======================================================
======================================================


History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-19  Initial development.
*/
@isTest
private class StringSubstitutionActionTest {
    @isTest
    static void testSubstituteValue() {
        // Test case 1: Valid substitution
        StringSubstitutionAction.SubstitutionRequest request1 = new StringSubstitutionAction.SubstitutionRequest();
        request1.InputString = 'Hello, World!';
        request1.OldValue = 'Hello';
        request1.NewValue = 'Hi';

        List<StringSubstitutionAction.SubstitutionRequest> requests1 = new List<StringSubstitutionAction.SubstitutionRequest>();
        requests1.add(request1);

        List<StringSubstitutionAction.SubstitutionResult> results1 = StringSubstitutionAction.substituteValue(requests1);
        System.assertEquals(1, results1.size(), 'Test Case 1 failed');
        System.assertEquals('Hi, World!', results1[0].SubstitutedString, 'Test Case 1 failed');

        // Test case 2: Null input string
        StringSubstitutionAction.SubstitutionRequest request2 = new StringSubstitutionAction.SubstitutionRequest();
        request2.InputString = null;
        request2.OldValue = 'Hello';
        request2.NewValue = 'Hi';

        List<StringSubstitutionAction.SubstitutionRequest> requests2 = new List<StringSubstitutionAction.SubstitutionRequest>();
        requests2.add(request2);

        List<StringSubstitutionAction.SubstitutionResult> results2 = StringSubstitutionAction.substituteValue(requests2);
        System.assertEquals(1, results2.size(), 'Test Case 2 failed');
        System.assertEquals(null, results2[0].SubstitutedString, 'Test Case 2 failed');
    }
}