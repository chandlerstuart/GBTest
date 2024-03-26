/**************************************************************
@author - James Radcliffe (Golfbreaks)
@date - 25/11/2016
@description - This Class hosts the methods to run on records passed in through the CoopInvoice Trigger
***************************************************************/
public class CoopInvoiceDML {
    
    //This method retrieves the current dates exchange rates and calculates the GBP Amount for every non GBP Invoice.
    public static void convertToGBP(List<Co_op_Invoice__c> allInvs){
        Map<String,Decimal> codesAndConversionRates = new Map<String,Decimal>(); 
        for (DatedConversionRate der : [select Id, ConversionRate, IsoCode, StartDate, NextStartDate from DatedConversionRate where StartDate <= TODAY AND NextStartDate > TODAY]){
        	codesAndConversionRates.put(der.ISOCode,der.ConversionRate);   
        }
        
        for(Co_op_Invoice__c i : allInvs){
            if(i.CurrencyISOCode != 'GBP'){
                i.Invoice_Amount_GBP__c = (i.Amount__c / codesAndConversionRates.get(i.CurrencyIsoCode)).setScale(2,RoundingMode.HALF_UP); 
                i.Conversion_Rate__c = codesAndConversionRates.get(i.CurrencyIsoCode).setScale(2,RoundingMode.HALF_UP);
            }else{
                i.Invoice_Amount_GBP__c = i.Amount__c.setScale(2,RoundingMode.HALF_UP);
                i.Conversion_Rate__c = 1;
            }
        }
    }
    
}