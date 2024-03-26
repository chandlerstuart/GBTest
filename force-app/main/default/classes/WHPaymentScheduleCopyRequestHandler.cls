/*
Name:  WHPaymentScheduleCopyRequestHandler.cls
======================================================
======================================================
Purpose: Request Handler for PaymentScheduleCopy Webhook
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-04-20  Initial Development.
*/

/*Design Notes
    This handler is responsible for the maintenance of Expected Payments in Corp.
    The equivalent 'Expected Payment' Object in Kaptio is called 'Payment Schedule'
    Each request will contain a collection of ItineraryIds with Payment Schedules (Bulk Pattern)
    Payment Schedules will be sent from Kaptio in their full state, meaning if there are records that do not exist in Corp, they should be created. If there are records in Corp that aren't in the package, they should be deleted etc.
    Kaptio has 'Deposit' and 'Full Balance' Types (only). Some calculation is required to identify the Partial Deposits vs the Full Deposit record
    Payment Schedules have individual totals. The Expected Payment amounts are a cumulative totals of all preceeding payments. This request handler is responsible for calculating the correct totals
*/

public with sharing class WHPaymentScheduleCopyRequestHandler implements IWebhookRequestHandler{

    public static Boolean isSuccess = true;

    public void handleRequest(RestRequest req, RestResponse res, Webhook__mdt wh){
        
        List<PaymentScheduleResponse> responseData = new List<PaymentScheduleResponse>();
        Set<String> itineraryIds = new Set<String>();
        Map<String,List<Expected_Payment__c>> itinIdToExpPaymentMap = new Map<String,List<Expected_Payment__c>>();
        Map<String,List<Expected_Payment__c>> itinIdToExpPaymentUpsertListMap = new Map<String,List<Expected_Payment__c>>();
        Map<String,List<Expected_Payment__c>> itinIdToExpPaymentDeleteListMap = new Map<String,List<Expected_Payment__c>>();
        Map<String,String> kaptioToCorpBookingIdMap = new Map<String,String>();

        try{
            String jsonString = RestContext.request.requestBody.toString();
            //String jsonString = '{"paymentSchedules":[{"paymentScheduleId":"a1y9H000007hzgOQAQ","expectedPaymentId":null,"expectedAmount":21697.5,"dueDate":"2019-09-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000006hzgORTR","expectedPaymentId":null,"expectedAmount":697.5,"dueDate":"2020-10-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000007uzgOQAQ","expectedPaymentId":null,"expectedAmount":21697.5,"dueDate":"2020-11-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y6H000006hzgORTR","expectedPaymentId":null,"expectedAmount":697.5,"dueDate":"2019-10-20","currencyISOCode":"NOK"}],"itineraryBookingId":"a0h24000002NIMAAA4"}';
            List<PaymentScheduleRequest> paymentScheduleRequestList = (List<PaymentScheduleRequest>)System.JSON.deserialize(jsonString, List<PaymentScheduleRequest>.class);

            //Build a list of Itinerary Ids for querying the Booking & Exp Payment data
            for(PaymentScheduleRequest psr : PaymentScheduleRequestList){
                if(psr.itineraryBookingId == null) continue;
                if(!itineraryIds.contains(psr.itineraryBookingId)) itineraryIds.add(psr.itineraryBookingId);
            }
            
            //Retrieve and sort existing data (Bookings and Expected Payments)

            //Retrieve Booking and Expected Payment Data
            List<Booking__c> bookingsWithExpPayments = [Select Id, INTL_KaptioItineraryId__c, (Select Id, INTL_KaptioPaymentScheduleId__c, Expected_Amount__c, ExpectedPaymentType__c, Outstanding_Balance__c, Booking_System__c, Booking__c From Expected_Payments__r ) From Booking__c Where INTL_KaptioItineraryId__c in:itineraryIds];
            for(Booking__c b : bookingsWithExpPayments){
                if(!itinIdToExpPaymentMap.containsKey(b.INTL_KaptioItineraryId__c)) itinIdToExpPaymentMap.put(b.INTL_KaptioItineraryId__c,new List<Expected_Payment__c>());
                kaptioToCorpBookingIdMap.put(b.INTL_KaptioItineraryId__c,b.Id);
                if(b.Expected_Payments__r.size()>0){
                    system.debug('Found '+b.Expected_Payments__r.size()+' Expected Payments records for Booking '+b.Id);
                    itinIdToExpPaymentMap.get(b.INTL_KaptioItineraryId__c).addAll(b.Expected_Payments__r);
                }
            }

            for(PaymentScheduleRequest psr : paymentScheduleRequestList){
                //Return Failure if Id is not specified
                if(psr.itineraryBookingId == null){
                    system.debug('Error: Could not find Booking - Required Property Missing > itineraryBookingId');
                    isSuccess = false;
                    responseData.add(new PaymentScheduleResponse(null,'Error: Could not find Booking - Required Property Missing > itineraryBookingId'));
                    continue;
                }
                //Return Failure if Id is not recognised
                if(!itinIdToExpPaymentMap.containsKey(psr.itineraryBookingId)){
                    system.debug('Error: Could not find Booking with itineraryBookingId '+psr.itineraryBookingId);
                    isSuccess = false;
                    responseData.add(new PaymentScheduleResponse(psr.itineraryBookingId,'Error: Could not find Booking with itineraryBookingId '+psr.itineraryBookingId));
                    continue;
                }
                //If Payment Schedules is empty and EPs exist, add existing EPs to Delete List
                if(psr.paymentSchedules.size()==0){
                    system.debug('No Payment Schedules specified, deleting all Expected Payments for Booking matching Itinerary:'+psr.itineraryBookingId);
                    if(itinIdToExpPaymentMap.get(psr.itineraryBookingId).size()>0){
                        if(!itinIdToExpPaymentDeleteListMap.containsKey(psr.itineraryBookingId)) itinIdToExpPaymentDeleteListMap.put(psr.itineraryBookingId,new List<Expected_Payment__c>());
                        itinIdToExpPaymentDeleteListMap.get(psr.itineraryBookingId).addAll(itinIdToExpPaymentMap.get(psr.itineraryBookingId));
                    }
                    continue;
                }else{//Else Convert Payment Schedules into Expected Payments (for upsert)
                    Map<String,Expected_Payment__c> psIdsWithUpsertList = convertPaymentSchedulesToExpectedPayments(psr.paymentSchedules,kaptioToCorpBookingIdMap.get(psr.itineraryBookingId));
                    //If there are existing Expected Payments, retrieve from Map to see if they are still valid. If so, set the Id on the upsert record, else add to delete list
                    List<Expected_Payment__c> existingExpPayments = itinIdToExpPaymentMap.get(psr.itineraryBookingId);
                    if(existingExpPayments.size()>0){
                        for(Expected_Payment__c ep : existingExpPayments){
                            //If the Payment Schedule Id on the Existing Record is not recognised, add to delete list
                            if(ep.INTL_KaptioPaymentScheduleId__c == null || !psIdsWithUpsertList.containsKey(ep.INTL_KaptioPaymentScheduleId__c)){
                                //Add to delete map
                                if(!itinIdToExpPaymentDeleteListMap.containsKey(psr.itineraryBookingId)) itinIdToExpPaymentDeleteListMap.put(psr.itineraryBookingId,new List<Expected_Payment__c>());
                                if(itinIdToExpPaymentDeleteListMap.containsKey(psr.itineraryBookingId) && !itinIdToExpPaymentDeleteListMap.get(psr.itineraryBookingId).contains(ep)) itinIdToExpPaymentDeleteListMap.get(psr.itineraryBookingId).add(ep);
                            }else{//else, set the Id of the corresponding upsert record so the existing record is recognised and updated in the upsert
                                psIdsWithUpsertList.get(ep.INTL_KaptioPaymentScheduleId__c).Id = ep.Id;
                            }
                        }
                    }
                    //Add to Upsert list
                    if(!itinIdToExpPaymentUpsertListMap.containsKey(psr.itineraryBookingId)) itinIdToExpPaymentUpsertListMap.put(psr.itineraryBookingId,new List<Expected_Payment__c>());
                    itinIdToExpPaymentUpsertListMap.get(psr.itineraryBookingId).addAll(psIdsWithUpsertList.values());
                }
            }

            //DML Operations

            //Upsert Expected Payments
            if(itinIdToExpPaymentUpsertListMap.values().size()>0){
                List<Expected_Payment__c> upsertList = new List<Expected_Payment__c>();
                for(List<Expected_Payment__c> epList : itinIdToExpPaymentUpsertListMap.values()){
                    upsertList.addAll(epList);
                }
                system.debug('Upserting '+upsertList.size()+' Expected Payments');
                upsert upsertList;
            }

            //Delete Expected Payments
            if(itinIdToExpPaymentDeleteListMap.values().size()>0){
                List<Expected_Payment__c> deleteList = new List<Expected_Payment__c>();
                for(List<Expected_Payment__c> epList : itinIdToExpPaymentDeleteListMap.values()){
                    deleteList.addAll(epList);
                }
                system.debug('Deleting '+deleteList.size()+' Expected Payments');
                delete deleteList;
            }

            //Build Responses for remaining Payment Schedule Requests
            for(PaymentScheduleRequest psr : paymentScheduleRequestList){
                if(psr.itineraryBookingId == null || !itinIdToExpPaymentMap.containsKey(psr.itineraryBookingId)) continue;//Already logged as failures (no Id & unrecognised Id)
                Map<String,String> responseMap = new Map<String,String>();

                if(itinIdToExpPaymentUpsertListMap.containsKey(psr.itineraryBookingId)){
                    for(Expected_Payment__c ep : itinIdToExpPaymentUpsertListMap.get(psr.itineraryBookingId)){
                        responseMap.put(ep.INTL_KaptioPaymentScheduleId__c,ep.Id);
                    }
                }
                responseData.add(new PaymentScheduleResponse(psr.itineraryBookingId,responseMap));//Empty List (No Exp Payments Remaining)
            }

            //PaymentScheduleResponseWrapper responseWrapper;
            if(isSuccess){
                res.statusCode = (wh.SuccessResponseStatusCode__c != null)?(Integer)wh.SuccessResponseStatusCode__c:200;
            }else{
                res.statusCode = (wh.ErrorResponseStatusCode__c != null)?(Integer)wh.ErrorResponseStatusCode__c:400;//All Or None - If one of the Schedules failed, return error to alert the admin team and force retries
            }
            res.responseBody = Blob.valueOf(JSON.serialize(new PaymentScheduleResponseWrapper(responseData,isSuccess)));

        }catch(Exception e){
            PlatformLogManager.logExceptions(e, 'WHPaymentScheduleCopyRequestHandler', 'handleRequest');
            system.debug('WHPaymentScheduleCopyRequestHandler.handleRequest Error> '+e.getMessage()+'-'+e.getStackTraceString());
            res.statusCode = (wh.ErrorResponseStatusCode__c != null)?(Integer)wh.ErrorResponseStatusCode__c:400;
            String errorMessage = 'Error: Runtime Exception: '+e.getMessage()+'-'+e.getStackTraceString();
            res.responseBody = Blob.valueOf(JSON.serialize(new PaymentScheduleResponseWrapper(errorMessage)));
            return;
        }

    }

    //Local copy of Kaptio Payment Schedule Schema
    public Class PaymentSchedule{
        public Decimal expectedAmount;//Expected Amount
        public Date dueDate;//Due Date 
        public String currencyISOCode;//CurrencyCode
        public String paymentScheduleId;//Kaptio Payment Schedule Id
    }

    //Expected Request Structure
    public Class PaymentScheduleRequest{
        List<PaymentSchedule> paymentSchedules;//List of Kaptio Payment Schedules
        String itineraryBookingId;
    }
    //Expected Response Structure
    public Class PaymentScheduleResponse{
        Boolean isSuccess;
        String errorMessage;
        Map<String,String> paymentScheduleIdsWithExpPaymentIds;//List of Kaptio Payment Schedule Ids with matching Expected Payment Id
        String itineraryBookingId;

        public PaymentScheduleResponse(String itineraryBookingId, String errorMessage){
            this.isSuccess = false;
            this.itineraryBookingId = itineraryBookingId;
            this.errorMessage = errorMessage;
        }

        public PaymentScheduleResponse(String itineraryBookingId, Map<String,String> paymentScheduleIdsWithExpPaymentIds){
            this.isSuccess = true;
            this.itineraryBookingId = itineraryBookingId;
            this.paymentScheduleIdsWithExpPaymentIds = paymentScheduleIdsWithExpPaymentIds;
        }
    }

    public Class PaymentScheduleResponseWrapper{
        Boolean isSuccess;
        String errorMessage;
        List<PaymentScheduleResponse> results;

        public PaymentScheduleResponseWrapper(String errorMessage){
            this.isSuccess = false;
            this.errorMessage = errorMessage;
            this.results = new List<PaymentScheduleResponse>();
        }

        public PaymentScheduleResponseWrapper(List<PaymentScheduleResponse> responseData, Boolean isSuccess){
            this.isSuccess = isSuccess;
            this.errorMessage = (!isSuccess)?Label.WHPaymentScheduleCopyRequestHandlerError:null;
            this.results = responseData;
        }
    }

    //This method converts Payment Schedule records into Expected Payment records
    public Map<String,Expected_Payment__c> convertPaymentSchedulesToExpectedPayments(List<PaymentSchedule> paymentSchedules, String bookingId){

        system.debug('convertPaymentSchedulesToExpectedPayments - Start');
        if(paymentSchedules == null || paymentSchedules.size()==0 || bookingId == null) return null;
        system.debug('paymentSchedules - '+JSON.serialize(paymentSchedules));
        system.debug('bookingId: '+bookingId);

        Map<String,Expected_Payment__c> psIdsToExpectedPayment = new Map<String,Expected_Payment__c>();

        //Use Comparable Interface to Sort Payment Schedules by Due Date
        List<PaymentScheduleWrapper> psWrappers = new List<PaymentScheduleWrapper>();
        for(PaymentSchedule ps : paymentSchedules){
            if(ps.paymentScheduleId == null) continue;//TO DO - Log Failures. A Payment Schedule must always have an Id
            psWrappers.add(new PaymentScheduleWrapper(ps));
        }

        system.debug('Sorting Payment Schedules by Due Date');
        psWrappers.sort();//Sorted by DueDate ASC

        Integer paymentCount = psWrappers.size();
        Integer currentPayment = 1;
        Decimal cumulativeExpectedAmount = 0.00;
        String expPaymentType;
        system.debug('Creating Expected Payments');
        for(PaymentScheduleWrapper psw : psWrappers){

            //Calculate Cumulative Totals
            cumulativeExpectedAmount = psw.ps.expectedAmount+cumulativeExpectedAmount;

            //Calculate Type
            if(paymentCount == currentPayment){//Is the last Payment Schedule
                expPaymentType = ApplicationConstant.EPAYMENTTYPEFULLBALANCE;
            }else if(currentPayment == paymentCount-1){//Is the last Payment before the Final Balance
                expPaymentType = ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT;
            }else{//Is neither the final balance nor final deposit
                expPaymentType = ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT;
            }

            Expected_Payment__c ep = new Expected_Payment__c(
                Expected_Amount__c = cumulativeExpectedAmount,
                ExpectedPaymentType__c = expPaymentType,
                Expected_Payment_Date__c = psw.ps.dueDate,
                CurrencyIsoCode = psw.ps.currencyISOCode,
                Booking__c = bookingId,
                Booking_System__c = 'Kaptio',
                INTL_KaptioPaymentScheduleId__c = psw.ps.paymentScheduleId
            );

            psIdsToExpectedPayment.put(psw.ps.paymentScheduleId,ep);
            currentPayment = currentPayment+1;
        }

        if(psIdsToExpectedPayment.values().size()>0) system.debug('Expected Payments - '+JSON.serialize(psIdsToExpectedPayment.values()));
        system.debug('convertPaymentSchedulesToExpectedPayments - End');

        return psIdsToExpectedPayment;

    }

    public Class PaymentScheduleWrapper implements Comparable{
        private PaymentSchedule ps;
        public PaymentScheduleWrapper(PaymentSchedule ps) {this.ps = ps;}
        public Integer compareTo(Object compareTo) {
            PaymentScheduleWrapper ctps = (PaymentScheduleWrapper) compareTo;
            if(ctps.ps.dueDate == null || this.ps.dueDate == null) return 0;
            if (ctps.ps.dueDate < this.ps.dueDate) return +1;
            if (ctps.ps.dueDate > this.ps.dueDate) return -1;
            return 0; 
        }
    }




}