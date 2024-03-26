/*
Name:  TakePaymentControllerExtension.cls
======================================================
======================================================
Purpose:
-------
Extension Class for the TakePaymentVF Page

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  30/05/2018  Initial Development.
1.1  James Radcliffe  12/06/2018  If an exception is thrown after the API starts taking payments then a success status is returned, but there is still an error. Adding a wrapper to capture and handle the response more effectively
1.2  James Radcliffe  08/03/2022  Changes to support new required payment API property - PaymentApplicationType
*/
public class TakePaymentControllerExtension {
    
    public Opportunity theOpp {get;set;}
    public Id theOppId {get;set;}
    public Booking__c booking {get;set;}
    //The Transaction Amount before editing
    public Double transactionAmount {get;set;}
    
    public String requestLabel {get;set;}
    public String result {get;set;}
    public Integer resultStatusCode {get;set;}
    
    //State variable for rendering output panels
    public Boolean showError {get;set;}
    public Boolean showSuccess {get;set;}
    public Boolean showForm {get;set;}
    public Boolean isErrorStyle {get;set;}
    
    //List (and Class Name) for logging exceptions/errors
    List<Error_Log__c> logs = new List<Error_Log__c>();
    String CLASS_NAME = 'TakePaymentControllerExtension'; 
    
    //1.1 BookingPaymentResponseWrapper
    BookingPaymentResponseWrapper responseWrapper {get;set;}
    
    public TakePaymentControllerExtension(ApexPages.StandardController cont){
        
        //Hide Errors (Default)
        showError = false;
        //Hide Results (Default)
        showSuccess = false;
        //Show the form
        showForm = true;
        
        //Retrieve the Opportunity
        theOppId = cont.getRecord().Id;
        
        //Retrieve the Opp and related booking
        theOpp = [Select Id, Name, Transaction_Amount__c, Transaction_Authorised_Amount__c, Card_Token_Id__c, (Select Id, Golfbreaks_Booking_ID__c, Account__c, Account__r.PersonEmail From Bookings__r Order by LastModifiedDate Desc LIMIT 1) From Opportunity Where Id = :theOppId];
        if(theOpp != null){
            system.debug('theOpp: '+theOpp);
            if(theOpp.Bookings__r != null && theOpp.Bookings__r.size()>0){ 
                booking = theOpp.Bookings__r[0];
                system.debug('booking: '+booking);
            }
        }
        
        //Capture the Transaction Amount before setting
        transactionAmount = theOpp.Transaction_Amount__c;
        
        //Default Transaction Amount
        theOpp.Transaction_Amount__c = theOpp.Transaction_Authorised_Amount__c;                
        
        //Check all the required information is available
        verifyPaymentRequestDetails();
        
    }
    
    //This method handles the payment request to Clubhouse    
    public Object processRequest(){
        
        //Hide Error, Hide Form, Show Spinner
        showError = false;     
        showForm = false;       
        
        //Re-run validation checks
        Boolean validationPassed = verifyPaymentRequestDetails();
        if(!validationPassed){
            return null;
        }else{
            //Build Booking Payment Request wrapper
            system.debug('Building Payment Request Wrapper');
            
            //Set TokenisedCardPayment Details
            BookingPaymentRequestWrapper.TokenisedCardPaymentMethodModel tcpmm = new BookingPaymentRequestWrapper.TokenisedCardPaymentMethodModel();
            tcpmm.CardHolderType = ApplicationConstant.OBJECT_TYPE_OPPORTUNITY;
            tcpmm.CardHolderID = theOpp.Id;
            tcpmm.CardName = theOpp.Card_Token_Id__c;
            tcpmm.EmailAddress = booking.Account__r.PersonEmail;
            tcpmm.PaymentApplicationType = 1;//1.2+ (Setting to MOTO type as the client is not available to answer questions for 3D secure payments)
            tcpmm.Surcharge = new BookingPaymentRequestWrapper.AmountModel(0,theOpp.CurrencyIsoCode);
            
            //Set Payment Method Details
            BookingPaymentRequestWrapper.PaymentMethodsModel pmm = new BookingPaymentRequestWrapper.PaymentMethodsModel();
            pmm.SalesforceTrackingID = theOpp.Id;
            double amount = theOpp.Transaction_Amount__c;
            pmm.Amount = new BookingPaymentRequestWrapper.AmountModel(amount,theOpp.CurrencyIsoCode);
            pmm.TokenisedCardPayment = tcpmm;
            
            //Set BookingPaymentRequestWrapper
            BookingPaymentRequestWrapper bprw = new BookingPaymentRequestWrapper();
            bprw.BookingSalesforceID = booking.Id;
            bprw.BookingGolfbreaksID = (Integer)booking.Golfbreaks_Booking_ID__c;
            bprw.PaymentApplicationType = 1;//1.2+ (Setting to MOTO type as the client is not available to answer questions for 3D secure payments)
            List<BookingPaymentRequestWrapper.PaymentMethodsModel> pmmList = new List<BookingPaymentRequestWrapper.PaymentMethodsModel>();
            pmmList.add(pmm);
            bprw.PaymentMethods = pmmList;
            
            try{
                
                // Create callout request
                Http http = new Http();                
                HttpRequest request = new HttpRequest();
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setEndpoint('callout:ClubhouseCredentials/api/Payment');
                request.setBody(JSON.serialize(bprw));
                system.debug('Request Body: '+request.getBody());
                
                //Get timeout value from custom setting
                Http_Timeout__c httpTimeout = Http_Timeout__c.getInstance('Take Payment');
                Integer timeOut;            
                if (null != httpTimeout){
                    //We have a value, so set the timeout
                    system.debug('*** -- Setting Take Payment timeout to ' + integer.valueOf(httpTimeout.Timeout_In_Seconds__c) + ' -- ***');
                    timeOut = integer.valueOf(httpTimeout.Timeout_In_Seconds__c);
                }else{
                    //Else it will keep the default of 20 seconds
                    timeOut = 20;
                }
                
                system.debug('Time Out: '+timeOut);
                
                // Create continuation with a timeout
                Continuation con = new Continuation(timeOut);
                // Set callback method
                con.continuationMethod='processResponse';
                
                // Add callout request to continuation
                requestLabel = con.addHttpRequest(request);
                system.debug('Request Label: '+requestLabel);
                
                // Return the continuation
                return con;  
                
                
            }catch(exception e){
                //DISPLAY ERROR
                system.debug('Contination Apex Error: '+e);
                isErrorStyle = true;
                showError = true;
                showSuccess = false;
                showForm = false; 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There was an error; '+e));
                return null;                             
            }
        }
        
    }
    
    // Callback method 
    public Object processResponse() {   
        system.debug('Processing Response');
        showForm = false;
        
        // Get the response by using the unique label
        HttpResponse response = Continuation.getResponse(this.requestLabel);
        // Set the result variable that is displayed on the Visualforce page
        this.result = response.getBody();
        this.resultStatusCode = response.getStatusCode();
        system.debug('Response Body: '+result);
        
        //If successful, confirm there were no exceptions after the initial payment, save the Opportunity (set the Transaction_Amount__c) and display success ELSE display error
        if(response.getStatusCode() == 200){
            try{           
                //1.1 Deserialise the response into the BookingPaymentResponseWrapper
                if(this.result != null){
                    responseWrapper = (BookingPaymentResponseWrapper)JSON.deserialize(this.result, BookingPaymentResponseWrapper.class);
                }
                //Check all payments were successful (no exceptions were thrown following successful payment)
                if(responseWrapper != null && responseWrapper.AllPaymentMethodsSuccessful){
                    system.debug('Payment Successful. Setting Transaction Amount on Opp. Amount: '+theOpp.Transaction_Amount__c);
                    
                    //Query Opp for update
                    Opportunity opp = [Select Id, Transaction_Amount__c, Card_Token_ID__c From Opportunity Where Id = :theOppId][0];
                    system.debug('Opp To Update: '+opp);
                    //Set the Transaction_Amount__c
                    opp.Transaction_Amount__c = theOpp.Transaction_Amount__c;
                    opp.Card_Token_ID__c = null;
                    update opp;
                    //Display Success Message
                    showSuccess = true;
                    
                }else{
                    //1.1 - Log error in Error_Log__c, clear Token Id and display the outcome                    
                    
                    //Clear the Token Id (Prevent future 'Take Payment' attempts) 
                    //Query Opp for update
                    Opportunity opp = [Select Id, Card_Token_Id__c From Opportunity Where Id = :theOppId][0];
                    system.debug('Opp To Update: '+opp);
                    //clear the token id
                    opp.Card_Token_Id__c = null;
                    update opp;
                    
                    //Log the error
                    Error_Log__c e = new Error_Log__c();
                    e.Name = 'Take Payment Error';
                    e.Error_Type__c = ApplicationConstant.GENERAL_ERROR_LOG;
                    e.Method_Name__c = 'processResponse';
                    e.Class_Name__c = 'TakePaymentControllerExtension';
                    e.Trace__c = 'There was an error taking the payment: '+responseWrapper.PaymentMethodOutcomes[0].Outcome+'. The card token Id ('+theOpp.Card_Token_Id__c+') has been cleared from the Opportunity ('+theOpp.Id+') to prevent future payments attempts from Salesforce';
                    e.Error_Message__c = 'See "Trace"';
                    insert e;
                    
                    //Display the Error
                    system.debug('Error Following the taking of the payment: '+responseWrapper.PaymentMethodOutcomes[0].Outcome);
                    isErrorStyle = true;
                    showError = true;
                    showSuccess = false;
                    showForm = false; 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There was an error. DO NOT submit another take payment request for this booking. Please contact your system administrator for assistance. Error:'+responseWrapper.PaymentMethodOutcomes[0].Outcome));
                    return null;
                }
            }catch(exception e){
                system.debug('Error thrown: '+e);
                isErrorStyle = true;
                showError = true;
                showSuccess = false;
                showForm = false; 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There was an error. DO NOT submit another take payment request for this booking. Please contact your system administrator for assistance; Payment was successful, but failed to update the Opportunity. Error: '+e));
                return null;
            }
            
            
        }else{
            //Display response error message
            isErrorStyle = true;
            showError = true;
            showSuccess = false;
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Payment Request Unsuccessful. Error: '+result+'. Please contact your system administrator if you require assistance'));
            return null;
        }
        
        // Return null to re-render the original Visualforce page
        return null;
    }    
    
    //This method checks if the Opportunity and Booking contain all the required information for making a payment request
    public boolean verifyPaymentRequestDetails(){
        
        system.debug('Start Validation');
        
        //ERRORS should be displayed when: 
        //There is no booking against the Booking Request
        if(booking == null){
            system.debug('Validation Fail: No Booking Found');
            isErrorStyle = false;
            showError = true;
            showForm = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Cannot take payment. No Booking was found for this Opportunity ('+theOpp.Name+' ['+theOpp.Id+']). Please contact your system administrator if you require assistance'));
            return false;
        }
        
        
        //The Transaction Amount is greater than 0 (payment has already been taken) - Only one payment can be taken per booking request        
        if(transactionAmount > 0){
            system.debug('Validation Failed: Payment has already been taken');
            isErrorStyle = false;
            showError = true;
            showForm = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Cannot take payment. A payment of '+transactionAmount+' has already been taken for this Booking Request ['+theOpp.Id+']). Only one payment can be taken per Booking Request. Please contact your system administrator if you require assistance'));
            //Set the transaction amount to the payment that has already been taken (revert the change in the constructor)
            theOpp.Transaction_Amount__c = transactionAmount;
            return false;            
        }
        
        //There is no transaction auth amount (Auth Amount = 0.00)
        if(theOpp.Transaction_Authorised_Amount__c == null || theOpp.Transaction_Authorised_Amount__c == 0){
            system.debug('Validation Failed: Authorised Amount = 0.00');
            isErrorStyle = false;
            showError = true;
            showForm = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Cannot take payment. Authorsied Transaction Amount: '+theOpp.Transaction_Authorised_Amount__c+' ['+theOpp.Id+']). Please contact your system administrator if you require assistance'));
            return false;            
        }
        
        //The correct info (for a successful api call) is not available 
        String missingInfo;
        if(booking.Account__r.PersonEmail == null || booking.Account__r.PersonEmail == ''){
            missingInfo = missingInfo+'; Client Email';
            system.debug('Validation Failed: Missing Information: Email');
        }
        if(theOpp.Card_Token_Id__c == null || theOpp.Card_Token_Id__c == ''){
            missingInfo = missingInfo+'; Card Token Id';
        }
        if(booking.Golfbreaks_Booking_ID__c == null || booking.Golfbreaks_Booking_ID__c == 0){
            missingInfo = missingInfo+'; Golfbreaks Booking Id';
        }
        if(missingInfo != null && missingInfo != ''){
            //Remove the first ';'
            missingInfo = missingInfo.substringAfter(';');
            isErrorStyle = false;
            showError = true;
            showForm = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Cannot take payment. The following required detail/s are missing:'+missingInfo));
            return false;
        }
        
        //The Transaction Amount exceeds the Transaction Authorised Amount
        if(theOpp.Transaction_Authorised_Amount__c < theOpp.Transaction_Amount__c || theOpp.Transaction_Amount__c < 0.01){
            system.debug('Validation Failed: Payment exceeds maximum authorised amount');
            isErrorStyle = true;
            showError = true;
            showForm = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot take payment. The transaction amount ('+theOpp.Transaction_Amount__c+') must be greater than 0.00 and cannot exceed the maximum authorised amount ('+theOpp.Transaction_Authorised_Amount__c+'). Please contact your system administrator if you require assistance'));
            return false;            
        }
        
        system.debug('Validation Passed');
        
        return true;
    }
    
}