/*
Name:  EmpCommunity_UsefulLinkController.cls
Copyright © 2016  Golfbreaks.
======================================================
======================================================
Purpose:
-------
Controller for EmpCommunity_UsefulLinks Lightning Component. 
getUsefulLinks method - Retrieves a list of Useful Link records for displaying on Employee Community
======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Simon Molloy        2016-09-27  Class creation.

*/
public with sharing class EmpCommunity_UsefulLinkController {
    public static String defaultURL {
        get {
            if (null == defaultURL){
                AttachmentBaseURL__c baseURL = AttachmentBaseURL__c.getInstance('Default');
                if(null == baseURL){
                    defaultURL = 'https://golfbreaks--itdev--c.cs81.content.force.com';
                }else {
                    defaultURL = baseURL.URL__c;
                }
            }
            return defaultURL;
        }
        set;
    }

    @AuraEnabled
    public static List<Useful_Link__c> getUsefulLinks(){
        return [select Id, Target__c, Label__c, Display_Order__c, URL__c, Description__c, Server_Path__c, (select Id from Attachments Order By LastModifiedDate LIMIT 1) from Useful_Link__c];
    }

    @AuraEnabled
    public static List<UsefulLinkWrapper> getUsefulLinkWrappers(){
        List<UsefulLinkWrapper> wrapperList = new List<UsefulLinkWrapper>();
        for (Useful_Link__c u : [select Id, Target__c, Display_Order__c, Label__c, URL__c, Description__c, Server_Path__c, (select Id from Attachments Order By LastModifiedDate LIMIT 1) from Useful_Link__c
                ORDER BY Display_Order__c ASC]){
            wrapperList.add(new UsefulLinkWrapper(u));
        }

        wrapperList.sort();
        return wrapperList;
    }

    public class UsefulLinkWrapper implements Comparable{
        @AuraEnabled
        public String linkLabel {get; set;}
        @AuraEnabled
        public String linkURL {get; set;}
        @AuraEnabled
        public String linkDescription {get; set;}
        @AuraEnabled 
        public String linkImage {get; set;}
        @AuraEnabled
        public integer displayOrder {get; set;}
        @AuraEnabled
        public String target {get; set;}

        //Sort method
        public integer compareTo(Object compareTo){
            UsefulLinkWrapper wrapperCompareTo = (UsefulLinkWrapper)compareTo;
            if (displayOrder == null) return -1;
            if (displayOrder == wrapperCompareTo.displayOrder) return 0;
            if (displayOrder > wrapperCompareTo.displayOrder) return 1;
            if (displayOrder != null && wrapperCompareTo.displayOrder == null) return 1;
            return -1;
            
        }

        public UsefulLinkWrapper(Useful_Link__c inLink){
            this.displayOrder = integer.valueOf(inLink.Display_Order__c);
            this.linkLabel = inLink.Label__c;
            this.linkURL = inLink.URL__c;
            this.linkDescription = inLink.Description__c;
            this.target = ('NEW WINDOW'.equalsIgnoreCase(inLink.Target__c) ? '_blank' : '_self');

            if (inLink.Attachments != null && !inLink.Attachments.isEmpty()){
                //https://golfbreaks--itdev--c.cs81.content.force.com/servlet/servlet.FileDownload?file=00P26000001bM27
                //String urlPath = inLink.Server_Path__c;//ApexPages.currentPage().getHeaders().get('Host');
                String urlPath = defaultURL;
                urlPath += '/servlet/servlet.FileDownload?file=' + inlink.Attachments[0].Id;
                this.linkImage = urlPath;
            }
        }

    }
}