/**
   @Author: Recuerdo Bregente/MaJoy Maliñana
   @name: LC03_CalendarEventsController
   @CreateDate: 02.17.2016
   @Description: Controller for Calendar Events
   @Version <1.0>
   @ History 
   * Jerome To - Commented out filter that appends Event_Channel__c in the query because field does not exist - May 31, 2016
 **/
public with sharing class LC03_CalendarEventsController{
    /* Description: Wrapper Class
    *  Author: Recuerdo Bregente
    */     
    public class Filters{
        @AuraEnabled
        public Object recordTypes {get; set;}
        @AuraEnabled
        public Object eventTypes {get; set;}
        @AuraEnabled
        public Object territories {get; set;}
    }
    /* Description: Wrapper Class
    *  Author: Recuerdo Bregente
    */
    public class calEvent{
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public Boolean allDay {get;set;}
        @AuraEnabled
        public String startString {get;set;}
        @AuraEnabled
        public String endString {get;set;}
        @AuraEnabled
        public String url {get;set;}
        @AuraEnabled
        public String className {get;set;}
        @AuraEnabled
        public String color {get;set;}
    }

    /* Description: Method to get Calendar Filters
    *  Author: Recuerdo Bregente
    */
    @AuraEnabled
    public static Filters getCalendarFilters(){
        Filters filters = new Filters();
        
        List<String> rtNames = new List<String>();
        rtNames.add(ApplicationConstant.CALENDAR_TYPE_NONE);
        for(RecordType rt : [SELECT Id,Name FROM RecordType WHERE SobjectType = :ApplicationConstant.CALENDAR_CAMPAIGN]){
            rtNames.add(rt.Name);
        }
        filters.recordTypes = rtNames;
        
        List<String> typeList = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = Campaign.Type.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        typeList.add(ApplicationConstant.CALENDAR_TYPE_NONE);
            
        for( Schema.PicklistEntry f : ple)
        {
            typeList.add(f.getValue());
        }
        
        filters.eventTypes = typeList;
        
        List<String> territories = new List<String>();
        Schema.DescribeFieldResult territoryFieldResult = Campaign.Territory__c.getDescribe();
        List<Schema.PicklistEntry> territoryPLE = territoryFieldResult.getPicklistValues();
        territories.add(ApplicationConstant.CALENDAR_TYPE_NONE);
            
        for(Schema.PicklistEntry f : territoryPLE)
        {
            territories.add(f.getValue());
        }
        
        filters.territories = territories;
        
        return filters;
    }
    
    /* Description: Method to get Calendar Events
    *  Author: Recuerdo Bregente
    */
    @AuraEnabled
    public static String getCalEvents
        (String sSelectedChannel, String sSelectedType, String sSelectedRecordType, String sSelectedTerritory)
    {
        List<calEvent> events = new list<calEvent>();
        String dtFormat = ApplicationConstant.CALENDAR_DTFORMAT;
        Boolean includeMyEvents = false;
        
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        Map<Id, String> recordTypeMapById = new Map<Id, String>();
        for(RecordType rt : [SELECT Id,Name FROM RecordType WHERE SobjectType = :ApplicationConstant.CALENDAR_CAMPAIGN]){
            recordTypeMap.put(rt.Name, rt.Id);
            recordTypeMapById.put(rt.Id, rt.Name);
        }
               
         String sQuery='select Id,RecordTypeId, Name,StartDate,EndDate from Campaign where';
         
         if(!String.isEmpty(sSelectedType) && !ApplicationConstant.CALENDAR_TYPE_NONE.equals(sSelectedType))
         {
             sQuery+=' Type=\'' + sSelectedType + '\' and ';
         } 
         
          
          if(!String.isEmpty(sSelectedRecordType) && !ApplicationConstant.CALENDAR_TYPE_NONE.equals(sSelectedRecordType))
           {
           
              sQuery+=' recordTypeId=\''+recordTypeMap.get(sSelectedRecordType)+'\' and ';
           
           }
           
           if(!String.isEmpty(sSelectedTerritory) && !ApplicationConstant.CALENDAR_TYPE_NONE.equals(sSelectedTerritory)){
               sQuery+=' Territory__c=\'' + sSelectedTerritory + '\' and ';
           }
         
          sQuery+=' Id!=null ';
          system.debug('.........................'+sQuery);
          
          
        //Below function sets the campaign value to campEvent obejct which will be used to disply values on calender and will be pased to jQuery plugin to display purpose
        for(Campaign camp : (List<Campaign>)Database.query(sQuery)){
            
            Integer i=0;
            DateTime startDT;
            DateTime endDT ; 
          
            if(camp.StartDate!=null)
            {
                startDT = DateTime.newInstance(camp.StartDate.year(), camp.StartDate.month(), camp.StartDate.day(), 7, 0, 0);
              i++;
            
            }

            if(camp.EndDate!=null)
            {
                endDT = DateTime.newInstance(camp.EndDate.year(), camp.EndDate.month(), camp.EndDate.day(), 20, 0, 0);
              i++;
            
            }
            
            system.debug('..........start.........'+startDT );
            system.debug('..........End.........'+endDT );
           
            if(i==2)
            {
            
                calEvent campEvent = new calEvent();
                campEvent.allDay = false;
                Decimal dateDif = Math.Floor(
                                          (Decimal)(
                                               (endDT.getTime()  - startDT.getTime())
                                               / (1000.0*60.0*60.0*24)
                                          )
                                    );
                if(dateDif >= 1){
                    campEvent.allDay = true;
                }
                campEvent.title = camp.Name;
                campEvent.startString = startDT.format(dtFormat);
                campEvent.endString = endDT.format(dtFormat);
                campEvent.url = '/' + camp.Id;
                campEvent.className = ApplicationConstant.CALENDAR_EVENT_CAMPAIGN;
                  system.debug('...........................'+campEvent);
                  
                campEvent.color = ApplicationConstant.CALENDAR_BLUE;
                if(recordTypeMapById.containsKey(camp.RecordTypeId) && recordTypeMapById.get(camp.RecordTypeId) == ApplicationConstant.CALENDAR_CAMPAIGNEVENT){
                    campEvent.color = ApplicationConstant.CALENDAR_LIGHTGREENFORR1;
                }
                else if(recordTypeMapById.containsKey(camp.RecordTypeId) && recordTypeMapById.get(camp.RecordTypeId) == ApplicationConstant.CALENDAR_CAMPAIGNPROGRAM){
                    campEvent.color = ApplicationConstant.CALENDAR_LIGHTBLUEFORR1;
                }
                
                events.add(campEvent);
        
         
            //Below function sets the Event Location value to calEvent obejct which will be used to disply values on calender and will be pased to jQuery plugin to display purpose
          }
       } 
       return parseEventToJSON(events);
    }
    
    /* Description: Method to parse Event to JSON
    *  Author: Recuerdo Bregente
    */
    private static String parseEventToJSON(List<calEvent> events){
        List<Map<String,Object>> eventList = new List<Map<String,Object>>();
        Map<String,Object> eventMap = new Map<String,Object>();
        for(calEvent event : events){
            eventMap = new Map<String,Object>();
            eventMap.put(ApplicationConstant.CALENDAR_TITLE, event.title);
            eventMap.put(ApplicationConstant.CALENDAR_START, event.startString);
            eventMap.put(ApplicationConstant.CALENDAR_END, event.endString);
            eventMap.put(ApplicationConstant.CALENDAR_URL , event.url);
            eventMap.put(ApplicationConstant.CALENDAR_ALLDAY, event.allDay);
            eventMap.put(ApplicationConstant.CALENDAR_COLOR, event.color);
            eventList.add(eventMap);
        }
        System.debug(JSON.serialize(eventList));
        return JSON.serialize(eventList);
    }
}