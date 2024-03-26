/*
Name:  BookingPaymentRequestWrapper.cls
======================================================
======================================================
Purpose:
-------
A wrapper class for detailing the parameters required
for the Clubhouse Payment API

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  30/05/2018  Initial Development.
1.1  James Radcliffe  08/03/2022  New required Payment API property - PaymentApplicationType
*/
public class BookingPaymentRequestWrapper {
    
    //The Salesforce identifier of the booking to attach the payment to.
    public String BookingSalesforceID;
    //The Golfbreaks identifier of the booking to attach the payment to.
    public Integer BookingGolfbreaksID;
    //The different payment methods that are being used to take payment from the client.
    public PaymentMethodsModel[] PaymentMethods;
    //An indication as to the type of application that is taking payments. This value influences whether the 3D Secure can be used when taking the payment and it can also influence which merchant account gets used, and thereby which set of tokenised cards are available for use. Take care when setting this value.
    public Integer PaymentApplicationType;//1.1+
    
    //Describes a method of making a payment.
    public class PaymentMethodsModel{
        
        //An optional Salesforce ID that will be associated with the client payment. This is sent back to Salesforce on the payment records in the booking syncs. Clubhouse does not attach any meaning to the tracking ID.
        public String SalesforceTrackingID;
        //The value of the payment to take. This is the monetary value to deduct from the booking total. It must not include surcharges.
        public AmountModel Amount;
        //Supply this parameter if the client is using a tokenised card.
        public TokenisedCardPaymentMethodModel TokenisedCardPayment;
    }
    
    //Describes a payment value.
    public class AmountModel{

        //The monetary value of the payment in the currency described within.
        public Double Value;
        //The ISO-3 code for the currency that the Value is in.
        public String CurrencyIso3Code;
        
        public AmountModel(Double inValue, String inCurrencyCode){
            Value = inValue;
            CurrencyIso3Code = inCurrencyCode; 
        }
        
    }
    
    //The parameters required when taking payment from a tokenised card.
    public class TokenisedCardPaymentMethodModel{
        //The Salesforce ID of the client that owns the tokenised card.
       // public String ClientAccountID;
        //The type of entity that the card was tokenised against. i.e. 'Opportunity', 'Booking' or 'Person'
        public String CardHolderType;
        //The identifier of the entity that the card was tokenised against. For bookings and clients this should **ALWAYS** be the Golfbreaks ID, i.e. an integer expressed as a string. For Opportuntities it is always the 18 character Salesforce ID.
        public String CardHolderID;
        //The name of the payment card to deduct the funds from.
        public String CardName;
        //The surcharge to add to the Value. The total amount deducted from the payment card's account will be the payment Value plus the Surcharge.
        public AmountModel Surcharge;
        //The email address to pass to the payment provider for fraud checks.
        public String EmailAddress;
        //An indication as to the type of application that is taking payments. This value influences whether the 3D Secure can be used when taking the payment and it can also influence which merchant account gets used, and thereby which set of tokenised cards are available for use. Take care when setting this value.
        public Integer PaymentApplicationType;//1.1+
    }
      
    
}