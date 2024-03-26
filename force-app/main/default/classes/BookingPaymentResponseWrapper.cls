/*
Name:  BookingPaymentRequestWrapper.cls
======================================================
======================================================
Purpose:
-------
A wrapper class for detailing the parameters within the
Clubhouse Payment API response

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  12/06/2018  Initial Development.
*/
public class BookingPaymentResponseWrapper {

  //The identifer in Booking__c of the booking that payment was taken for.  
  public  String BookingSalesforceID;
  //The identifier of the booking that payment was taken for.
  public  Integer BookingGolfbreaksID;
  //True if all of the payment methods requested were successful.
  public  Boolean AllPaymentMethodsSuccessful;
  //True if at least one of the payment methods requested was successful.
  public  Boolean AnyPaymentMethodSuccessful;
  //A collection of outcomes for each payment method requested.
  public  PaymentMethodOutcomeModel[] PaymentMethodOutcomes;
  //True if the deposit confirmation was sent after payment was taken.
  public  Boolean DepositConfirmationSent;
  //True if the travel pack was sent after payment was taken.  
  public  Boolean TravelPackSent;
  //True if an exception was raised during the send of documentation. Details are in the application log.  
  public  Boolean ExceptionDuringDocumentationSend;
        
        //Describes the outcome of a single payment method attempt.
        public class PaymentMethodOutcomeModel{
           
          //The optional Salesforce ID copied verbatim from the associated payment method in the original request.
          public  String SalesforceTrackingID;
          //The tag value, if any, copied verbatim from the associated payment method in the original request.
          public  String Tag;
          //True if the API tried to take payment.
          public  Boolean Attempted;
          //True if the payment method was successful.
          public  Boolean Success;
          //A description of the outcome. This comes from various sources (payment providers, internal GBDC methods etc.), successful payment methods will not have consistent text in this field.
          public  String Outcome;
          //A short description of the exception that was thrown during the payment request. This will be null if no exception was thrown.
          public  String ExceptionMessage;      
            
        }
    
}