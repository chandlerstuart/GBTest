/**
  * @Author: Jerome To (ACN)
  * @name: AP42_MonthlySalesTargetBL
  * @CreateDate: MAY 5, 2016
  * @Description: Business Logic for MonthlySalesTargetTrigger
  * @Version <1.0>
  * @History
 */ 

public with sharing class AP42_MonthlySalesTargetBL {

    public static void updateRecordOwner(List<Monthly_Sales_Target__c> newMonthlySalesTargetList){      
        for(Monthly_Sales_Target__c monthlySalesTarget : newMonthlySalesTargetList){
            if(monthlySalesTarget.OwnerId != monthlySalesTarget.SalesAgent__c){
                monthlySalesTarget.OwnerId = monthlySalesTarget.SalesAgent__c;              
            }
        }
    }

  public static void updateMonthlySalesTargetRollup(Map<Id, Monthly_Sales_Target__c> newMonthlySalesTargetMap) {    
    Set<String> closedWonStageNames = 
        new Set<String> { ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_DEPOSIT, 
                          ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_BALANCE, 
                          ApplicationConstant.OPPORTUNITY_STAGENAME_TRIP_COMPLETED };
    
    Set<Id> aggregatedMonthlySalesTargetIds = new Set<Id>();
    
    if(!newMonthlySalesTargetMap.isEmpty()){
       
      for (AggregateResult ar : [SELECT COUNT(Id), SUM(Amount), SUM(BookingAmount__c), TECH_Monthly_Sales_Target__c 
                                 FROM Opportunity 
                                 WHERE TECH_Monthly_Sales_Target__c IN: newMonthlySalesTargetMap.keyset()  
                                 AND Stagename IN: closedWonStageNames                                                    
                                 GROUP BY TECH_Monthly_Sales_Target__c]) {
        Id monthlySalesTargetId = String.valueOf(ar.get('TECH_Monthly_Sales_Target__c')); 
        if(newMonthlySalesTargetMap.containsKey(monthlySalesTargetId)) {          
          if(newMonthlySalesTargetMap.get(monthlySalesTargetId).RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT) {
              String totalWonAmount = String.valueOf(ar.get('expr1'));
              String totalBookingAmount = String.valueOf(ar.get('expr2'));
              newMonthlySalesTargetMap.get(monthlySalesTargetId).Won_Amount__c = Decimal.valueOf(!String.isEmpty(totalWonAmount) ? totalWonAmount : '0');
              newMonthlySalesTargetMap.get(monthlySalesTargetId).Total_Booking_Amount__c = Decimal.valueOf(!String.isEmpty(totalBookingAmount) ? totalBookingAmount : '0');                       
          } else if(newMonthlySalesTargetMap.get(monthlySalesTargetId).RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS) {
              String totalCount = String.valueOf(ar.get('expr0'));
              newMonthlySalesTargetMap.get(monthlySalesTargetId).Total_no_of_Closed_Bookings__c = Integer.valueOf(!String.isEmpty(totalCount) ? totalCount : '0');
          }
          aggregatedMonthlySalesTargetIds.add(monthlySalesTargetId);
        } 
      } 
      
      for(Monthly_Sales_Target__c monthlySalesTarget : newMonthlySalesTargetMap.values()){
          if(!aggregatedMonthlySalesTargetIds.contains(monthlySalesTarget.Id)) {
              if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT) {
                  monthlySalesTarget.Won_Amount__c = 0;
                  monthlySalesTarget.Total_Booking_Amount__c = 0;
              }
              else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS) {
                  monthlySalesTarget.Total_no_of_Closed_Bookings__c = 0;
              }
          }
      }      
    } 
  }

}