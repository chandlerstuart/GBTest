/*
Author: James Radcliffe
Date: 04/04/17
Detail: A Class to test the functionality of the ChangeRequestStatusAlert VF Page
*/

@IsTest
public class ChangeRequestStatusAlertExtensionTest{  

    @testSetup static void buildTestData() {
    
    RecordType rt = [select Id from RecordType where DeveloperName = 'Feature' and SObjectType = 'Change_Request__c' LIMIT 1];
    
    List<String> statusList = new List<String>();

    List<Change_Request__c> changeRequests = new List<Change_Request__c>();
    
    integer i = 1;
    for (String s : ChangeRequestStatusAlertExtension.statusAndSeverity.keySet()){
        Change_Request__c cr = new Change_Request__c();
        cr.RecordTypeId = rt.Id;
        cr.Title__c = 'Test CR ' + i;
        cr.Status__c = s;

        changeRequests.add(cr);

        i++;
    }
    
    insert changeRequests;
    
    }

    static testMethod void testNoCR(){
        
        PageReference pageRef = Page.ChangeRequestStatusAlert;
        test.setCurrentPage(pageRef);
        test.startTest();    
        
        ApexPages.StandardController std = new ApexPages.StandardController(new Change_Request__c());
        ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
        controller.getCR();
        
        test.stopTest();
        
        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        system.assertNotEquals(TRUE, pageMessages.isEmpty());
        
        for (ApexPages.Message msg : pageMessages){
            system.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            system.assertEquals('No Change Request parameter found', msg.getSummary());
        }
    
    }
    
    static testMethod void testStatus1(){
        
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_NEW];
        system.assertNotEquals(TRUE, crList.isEmpty());

        PageReference pageRef = Page.ChangeRequestStatusAlert;
        pageRef.getParameters().put('id',crList[0].Id);
        test.setCurrentPage(pageRef);
        test.startTest();    
        
        ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
        ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
        controller.getCR();
        
        test.stopTest();
        
        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        system.assertNotEquals(TRUE, pageMessages.isEmpty());
        
        for (ApexPages.Message msg : pageMessages){
            system.assertEquals(ApexPages.Severity.WARNING, msg.getSeverity());
            system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_New, msg.getSummary());
        }
    
    }
    
    static testMethod void testStatus2(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_CANCELLED];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Cancelled_By_User, msg.getSummary());
            }
        
        }

    static testMethod void testStatus3(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_REJECTED_BUSINESS_OWNER];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Rejected_by_Business_Owner, msg.getSummary());
            }
        
        }
    
    static testMethod void testStatus4(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_APPROVED_BUSINESS_OWNER];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Approved_by_Business_Owner, msg.getSummary());
            }
        
        }

    static testMethod void testStatus5(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_SUBMITTED_BUSINESS_OWNER];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Submitted_to_Business_Owner, msg.getSummary());
            }
        
        }
        
    static testMethod void testStatus6(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_SUBMITTED_IT];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Submitted_to_IT, msg.getSummary());
            }
        
        }
        
    static testMethod void testStatus7(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_REJECTED_IT];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Rejected_by_IT, msg.getSummary());
            }
        
        }  
        
    static testMethod void testStatus8(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_APPROVED_IT];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Approved_for_Development, msg.getSummary());
            }
        
        }              

    static testMethod void testStatus9(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_IN_PROGRESS];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_In_Development, msg.getSummary());
            }
        
        }         
        
    static testMethod void testStatus10(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_TESTING];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_In_Test, msg.getSummary());
            }
        
        }            
        
    static testMethod void testStatus11(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_USER_ACCEPTANCE_TESTING];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_In_UAT, msg.getSummary());
            }
        
        }              

    static testMethod void testStatus12(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_RELEASE_READY];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Approved_for_Release, msg.getSummary());
            }
        
        }            
  
    static testMethod void testStatus13(){
            
            List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_DEPLOYED];
            system.assertNotEquals(TRUE, crList.isEmpty());
    
            PageReference pageRef = Page.ChangeRequestStatusAlert;
            pageRef.getParameters().put('id',crList[0].Id);
            test.setCurrentPage(pageRef);
            test.startTest();    
            
            ApexPages.StandardController std = new ApexPages.StandardController(crlist[0]);
            ChangeRequestStatusAlertExtension controller = new ChangeRequestStatusAlertExtension(std);
            controller.getCR();
            
            test.stopTest();
            
            List<ApexPages.Message> pageMessages = ApexPages.getMessages();
            system.assertNotEquals(TRUE, pageMessages.isEmpty());
            
            for (ApexPages.Message msg : pageMessages){
                system.assertEquals(ApexPages.Severity.INFO, msg.getSeverity());
                system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Deployed_Complete, msg.getSummary());
            }
        
    } 

    //AURA METHOD TESTING
    static testMethod void testNoCRAura(){
        
        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(null);
        
        test.stopTest();
        
        system.assertEquals('error', retList[0]);
        system.assertEquals('No Change Request parameter found', retList[1]);
    
    }

    static testMethod void testStatus1Aura(){
        
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_NEW];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('warning', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_New, retList[1]);
    
    }  

    static testMethod void testStatus2Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_CANCELLED];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Cancelled_By_User, retList[1]);
    
    }

    static testMethod void testStatus3Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_REJECTED_BUSINESS_OWNER];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Rejected_by_Business_Owner, retList[1]);
        
    }
    
    static testMethod void testStatus4Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_APPROVED_BUSINESS_OWNER];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Approved_by_Business_Owner, retList[1]);
        
    }

    static testMethod void testStatus5Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_SUBMITTED_BUSINESS_OWNER];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Submitted_to_Business_Owner, retList[1]);
    }
        
    static testMethod void testStatus6Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_SUBMITTED_IT];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Submitted_to_IT, retList[1]);
        
    }
        
    static testMethod void testStatus7Aura(){
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_REJECTED_IT];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Rejected_by_IT, retList[1]);
            
    }  
        
    static testMethod void testStatus8Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_APPROVED_IT];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Approved_for_Development, retList[1]);
            
    }              

    static testMethod void testStatus9Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_IN_PROGRESS];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_In_Development, retList[1]);
            
    }         
        
    static testMethod void testStatus10Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_TESTING];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_In_Test, retList[1]);
            
        
    }            
        
    static testMethod void testStatus11Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_USER_ACCEPTANCE_TESTING];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_In_UAT, retList[1]);
            
    }              

    static testMethod void testStatus12Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_RELEASE_READY];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Approved_for_Release, retList[1]);
             
    }            
  
    static testMethod void testStatus13Aura(){
            
        List<Change_Request__c> crList = [select Id, Status__c from Change_Request__c where Status__c = :ChangeRequestStatusAlertExtension.CHANGE_REQUEST_DEPLOYED];
        system.assertNotEquals(TRUE, crList.isEmpty());

        test.startTest();    
        
        List<String> retList = ChangeRequestStatusAlertExtension.getStatusAlertMsg(crList[0].Id);
        
        test.stopTest();
        
        system.assertEquals('info', retList[0]);
        system.assertEquals(crList[0].Status__c + ': ' + system.label.Change_Request_Status_Deployed_Complete, retList[1]);
            
    }   
                    
}