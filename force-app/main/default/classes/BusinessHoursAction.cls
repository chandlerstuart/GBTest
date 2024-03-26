/*
Name:  BusinessHoursAction.cls
======================================================
======================================================
Purpose:
-------

This action can be called via flow and other sources to:
1. Check whether the current time is within a given Business Hours.
2. If no time is set the current time in the GMT timezone is checked.

Note, it is assumed that the timeToCheck will be localised.
Note, the calling context must defined the Business Hours Name; there is no relationship from GBBU to BH.

======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  Mark Cane&   2024-01-26  Initial development.
1.1  J Radcliffe  2024-01-31  Adding new output variable to return the day of the week (for the timeToCheck) based on the timezone of the specified business hours.
*/
public with sharing class BusinessHoursAction {

    @InvocableMethod
    public static List<ActionResult> checkIsWithinBusinessHours(List<ActionRequest> requests){

        Map<Integer,ActionResult> seqToResult = new Map<Integer,ActionResult>();

        try {
            Map<String,Id> businessHoursNameToId = new Map<String,Id>();
            Map<String,String> businessHoursNameToTZ = new Map<String,String>();//1.1+

            for (BusinessHours bh : [select Id, Name, TimeZoneSidKey from BusinessHours]){ businessHoursNameToId.put(bh.Name,bh.Id); businessHoursNameToTZ.put(bh.Name,bh.TimeZoneSidKey );}//1.1~

            Integer seq=0;

            for(ActionRequest request : requests){
                seq++;
                seqToResult.put(seq,new ActionResult(request.businessHoursName, request.timeToCheck==null ? Datetime.now() : request.timeToCheck));// -- now() returns GMT.
                
                if (String.IsBlank(request.businessHoursName) || !businessHoursNameToId.containsKey(request.businessHoursName)){
                    seqToResult.get(seq).isSuccess = false;
                    seqToResult.get(seq).errorMessage = 'Invalid Business Hours Name';
                }
            }            

            for (ActionResult result : seqToResult.values()){
                if (!result.isSuccess) continue;
                result.isWithinBusinessHours = BusinessHours.isWithin(businessHoursNameToId.get(result.businessHoursName), result.timeToCheck); 
                result.dayOfTheWeek = getDayOfTheWeek(businessHoursNameToTZ.get(result.businessHoursName),result.timeToCheck); // 1.1+ Returns the day of the week in EEEE format e.g. MONDAY, TUESDAY etc 
            }

        } catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BusinessHoursAction','checkIsWithinBusinessHours');
            for(ActionResult result : seqToResult.values()){
                result.isSuccess = false;
                result.errorMessage = e.getMessage()+'-'+e.getStackTraceString();
            }
        }
        return seqToResult.values();
    }

    //1.1+
    public static string getDayOfTheWeek(String timeZoneSidKey, DateTime timeToCheck){
        if(timeZoneSidKey == null || timeToCheck == null) return null;
        Datetime dateTimeInTimeZone = timeToCheck.addSeconds(Timezone.getTimeZone(timezoneSidKey).getOffset(timeToCheck)/1000);
        return dateTimeInTimeZone.format('EEEE').toUpperCase();
    }

        
    public class ActionRequest {
        
        @InvocableVariable(label='Business Hours Name' required=true)
        public String businessHoursName;// -- there is no navigable relationship from Golfbreaks BU to BH.

        @InvocableVariable(label='Time To Check' required=false)
        public Datetime timeToCheck;// -- if not set, then the current GMT time is checked.
    }

    public class ActionResult {

        private ActionResult(String businessHoursName, Datetime timeToCheck){ 
            isSuccess=true;
            isWithinBusinessHours=false;// -- default: time is not within business hours.
            this.businessHoursName = businessHoursName;
            this.timeToCheck=timeToCheck;
        }

        @InvocableVariable
        public String businessHoursName;

        @InvocableVariable
        public Datetime timeToCheck;

        @InvocableVariable
        public Boolean isWithinBusinessHours;

        //1.1+
        @InvocableVariable
        public String dayOfTheWeek;
        
        @InvocableVariable
        public Boolean isSuccess;

        @InvocableVariable
        public String errorMessage;
    }
}