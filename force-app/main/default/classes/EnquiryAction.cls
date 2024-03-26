/*
Name:  EnquiryAction.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Apex Action class for Enquiry creation.

Todo:
        
    TODO ----> (1) Additional unit tests (EnquiryActionTest).
    DONE ----> (2) Validate Flow integration.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-06-10  Initial development.
1.1  Mark Cane&    2019-06-14  Added EnquiryActionInput/Output classes.
1.2  J Radcliffe   2019-07-01  Support for logging Apex Action Request/Response details
*/
public with sharing class EnquiryAction {

    @InvocableMethod(label='Create Enquiry Action' description='Create Enquiry Action')
    public static List<EnquiryActionOutput> createEnquiries(List<EnquiryActionInput> enquiries) {

        String json = json.serializePretty(enquiries);//1.2

        DateTime startDateTime;
        Integer successCount = 0;
        Integer failCount = 0;
        List<String> errorMessages = new List<String>();

        startDateTime = system.now();//1.2 - cache start time

        List<EnquiryActionOutput> enquiryOutputs = new List<EnquiryActionOutput>();

        List<EnquiryManager.Enquiry> enquiriesToProcess = new List<EnquiryManager.Enquiry>();

        for (EnquiryActionInput e : enquiries){
            enquiriesToProcess.add( new EnquiryManager.Enquiry(e) );
        }

        EnquiryManager em = new EnquiryManager();
        
        for (EnquiryManager.Enquiry e : em.processEnquiries(enquiriesToProcess)){
            enquiryOutputs.add( new EnquiryActionOutput( e.isSuccess, e.sfRecordId, e.clientDetails.accountId, e.errorMessages, e.sfRecordObjectType ));
            //1.2
            if(e.isSuccess){
                successCount = successCount+1;
            }else{
                failCount = failCount+1; 
                if(e.errorMessages.isEmpty()) continue;
                for(String error : e.errorMessages.values()){
                    if(!errorMessages.contains(error) && error != null) errorMessages.add(error);
                }
            }
        }

        Integer speedInSeconds = (Integer)(system.now().getTime()-startDateTime.getTime())/1000;//1.5 - capture elapsed time between start and finish  
        //Log Request/Response Summary
        LogHelper.logFlowAPIRequest(json,system.JSON.serializePretty(enquiryOutputs),speedInSeconds,successCount,failCount,errorMessages);//1.5

        return enquiryOutputs;
    }
}