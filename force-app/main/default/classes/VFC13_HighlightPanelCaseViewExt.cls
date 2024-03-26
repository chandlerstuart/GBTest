/*
Name:  VFC13_HighlightPanelCaseViewExt.cls
======================================================
======================================================
Purpose:
-------
Controller class for VF Page VFP13_HighlightPanelCaseView

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-28  Initial development.
*/
public with sharing class VFC13_HighlightPanelCaseViewExt {
    public List<Case> cases {get; set;}
    
    public VFC13_HighlightPanelCaseViewExt(ApexPages.StandardController controller) {
        Id accId = ApexPages.currentPage().getParameters().get('accId');
        String query = 'SELECT ';
        for (Schema.FieldSetMember fsm : Schema.SObjectType.Case.fieldSets.CaseHighlightPanel.getFields()){
            query += fsm.getFieldPath() + ',';
        }
        
        query += 'Id from Case where IsClosed = FALSE AND AccountId = \'' + accId + '\'';
        
        cases = Database.query(query);
    }

}