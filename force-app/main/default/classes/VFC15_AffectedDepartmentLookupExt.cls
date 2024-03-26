/*
Name:  VFC15_AffectedDepartmentLookupExt.cls
======================================================
======================================================
Purpose:
-------
Controller class for VF Page VFC15_AffectedDepartmentLookup

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-11-09  Initial development.
*/
public with sharing class VFC15_AffectedDepartmentLookupExt {
    public Id sprintItemId {get; set;}
    public List<AffectedDepartmentWrapper> currentRecords {get; set;}
    public List<AffectedDepartmentWrapper> newRecords {get; set;}
    public boolean showCurrent {get; set;}      
    public boolean showNew {get; set;}
    public List<SelectOption> departmentSelect {get; set;}
    public String[] selectedDepartments {get; set;}
    public Map<String, Department__c> departmentMap {get; set;}
        
    public VFC15_AffectedDepartmentLookupExt(ApexPages.StandardController controller){
        sprintItemId = controller.getId();

        init();

    }

    public void init(){
        showCurrent = FALSE;
        showNew = FALSE;

        currentRecords = new List<AffectedDepartmentWrapper>();
        for (Affected_Department__c ad : [select Id, Department__c from Affected_Department__c where Sprint_Item__c = :sprintItemId]){
            currentRecords.add(new AffectedDepartmentWrapper(ad));
        }

        if (!currentRecords.isEmpty()) showCurrent = TRUE;

        newRecords = new List<AffectedDepartmentWrapper>();

        departmentSelect = buildDepartmentSelect();

    }

    public List<SelectOption> buildDepartmentSelect(){
        departmentMap = new Map<String, Department__c>();
        departmentSelect = new List<SelectOption>();
        Map<String, String> currentRecordMap = new Map<String, String>();
        for (AffectedDepartmentWrapper adw : currentRecords){
            currentRecordMap.put(adw.adRecord.Department__c, adw.adRecord.Department__c);
        }

        for (Department__c d : [select Id, Name from Department__c ORDER BY Name ASC]){
            departmentMap.put(String.valueOf(d.Id),d);

            if (!currentRecordMap.containsKey(String.valueOf(d.Id))){
                departmentSelect.add(new SelectOption(d.Id, d.Name));
            }
        }   

        return departmentSelect;
    }

    public PageReference saveAll(){
        List<Affected_Department__c> saveRecords = new List<Affected_Department__c>();

        for (String d : selectedDepartments){
            Department__c dept = departmentMap.get(d);
            Affected_Department__c adRecord = new Affected_Department__c(Sprint_Item__c = sprintItemId, Department__c = dept.Id);
            saveRecords.add(adRecord);
        }

        if (!saveRecords.isEmpty()) insert saveRecords;

        init();

        return null; 
    }

    public PageReference deleteSelected(){
        List<Affected_Department__c> deleteRecords = new List<Affected_Department__c>();

        for (AffectedDepartmentWrapper adw : currentRecords){
            if (adw.isSelected) deleteRecords.add(adw.adRecord);
        }

        if (!deleteRecords.isEmpty()) delete deleteRecords;

        init();

        return null;
    }

    public class AffectedDepartmentWrapper {
        public Affected_Department__c adRecord {get; set;}
        public boolean isSelected {get; set;}

        public AffectedDepartmentWrapper(Affected_Department__c ad){
            this.adRecord = ad;
        }
    }
}