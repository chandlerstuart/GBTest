public with sharing class ListViewWrapper {
    @AuraEnabled
    public String label {get; set;}

    @AuraEnabled
    public Integer recordCount {get; set;}

    @AuraEnabled
    public String url  {get; set;}
    
    @AuraEnabled
    public Boolean isMarked  {get; set;}
    
    @AuraEnabled
    public List<SObject> records {get; set;}

    @AuraEnabled
    public List<RecordWrapper> recordWrappers {get; set;}
    
}