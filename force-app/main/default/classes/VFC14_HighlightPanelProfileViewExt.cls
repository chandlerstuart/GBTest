/*
Name:  VFC14_HighlightPanelProfileViewExt.cls
======================================================
======================================================
Purpose:
-------
Controller class for VF Page VFP14_HighlightPanelProfileView

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-09-11  Initial development.
*/
public with sharing class VFC14_HighlightPanelProfileViewExt {
    public List<Client_Profile__c> clientProfiles {get; set;}
    public String newClientProfileURL {get;set;}
    
    public VFC14_HighlightPanelProfileViewExt(ApexPages.StandardController controller) {
        Id accId = ApexPages.currentPage().getParameters().get('accId');
        
        if (null == accId){
            clientProfiles = new List<Client_Profile__c>();
        }else {
            String query = 'SELECT ';
            for (Schema.FieldSetMember fsm : Schema.SObjectType.Client_Profile__c.fieldSets.ProfilesHighlightPanel.getFields()){
                query += fsm.getFieldPath() + ',';
            }
            
            query += 'Id, Account__r.Name from Client_Profile__c where Account__c = \'' + accId + '\'';
            
            clientProfiles = Database.query(query);     
            
            String accountName;
            if(!clientProfiles.isEmpty()){
               accountName = clientProfiles[0].Account__r.Name;
            }
            String url = System.Url.getSalesforceBaseURL().toExternalForm();
            system.debug('BaseUrl = '+url);
            String ClientProfileIdPrefix = Client_Profile__c.sObjectType.getDescribe().getKeyPrefix();
            newClientProfileURL = '/'+ClientProfileIdPrefix+'/e?&CF00N4E000001M570__lkid='+accId + '&CF00N4E000001M570=' + accountName;
            system.debug('newClientProfileURL: '+newClientProfileURL);
            
        }
    }

}