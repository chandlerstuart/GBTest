/*
Name:  ConversationQuickTextUtilityController.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Controller for Quick Text Utility
-------
The utility enables a user to choose quick text values
to apply to SMS/WhatsApp messages from a list retrieved from GXP

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-01  Initial development.
*/
public with sharing class ConversationQuickTextUtilityController {

    public static final String GetQuickTextCatagoriesDETName = 'Get_Quick_Text_Categories';
    public static final String GetQuickTextOptionsDETName = 'Get_Quick_Text_Options';
    public static Boolean throwException = false;

    public static Map<Integer,String> categoryMap = new Map<Integer,String>();

    public class CustomException extends Exception{}
    
    public class PageData{ 
        @AuraEnabled public List<SelectOption> categoryOptions;
        @AuraEnabled public List<QuickTextOption> quickTextOptions;
        public PageData(){
            this.categoryOptions = new List<SelectOption>();
            this.quickTextOptions = new List<QuickTextOption>();
        }
    }

    public class QuickTextOption{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String category;
        public QuickTextOption(QuickTextData qtd){
            this.label = qtd.name;
            this.value = qtd.message;
            this.category = (categoryMap.containsKey(qtd.category))?categoryMap.get(qtd.category):null;
        }
    }

    public class QuickTextCategory{
        public Integer key;
        public String value;
    }   

    public class QuickTextData{
        public Integer category;
        public String name;
        public String message;
    }  

    public class SelectOption{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public SelectOption(String label, String value){
            this.label = label;
            this.value = value;
        }
    } 

    @AuraEnabled
    public static PageData getQuickTextOptions(){
        try{
            PageData data = new PageData();

            //Get Quick Text Categories
            DataEventTypeAction.DataEventTypeActionRequest req = new DataEventTypeAction.DataEventTypeActionRequest(GetQuickTextCatagoriesDETName,UserInfo.getUserId());
            DataEventTypeAction.DataEventTypeActionResult res; 
            if(Test.isRunningTest()){
                if(throwException == true) throw new CustomException('Uh oh, something went wrong');
                DataEventTypeAction.DataEventTypeActionResult testRes1 = new DataEventTypeAction.DataEventTypeActionResult(UserInfo.getUserId(),true);
                testRes1.responseBody = '[{"key":0,"value":"Introductions"},{"key":1,"value":"Signoffs"},{"key":2,"value":"HoldingMessages"},{"key":3,"value":"CallToActions"},{"key":4,"value":"Policies"},{"key":5,"value":"Other"}]';
                res = testRes1;
            }else{
                res = DataEventTypeAction.invokeDataEventType(new List<DataEventTypeAction.DataEventTypeActionRequest>{req})[0];
            }
            if(res.isSuccess){
                //Populate category map
                List<QuickTextCategory> categoryVals = (List<QuickTextCategory>)JSON.deserialize(res.responseBody, List<QuickTextCategory>.class);
                if(categoryVals != null && categoryVals.size()>0){
                    for(QuickTextCategory qtc : categoryVals){
                        if(qtc.key == null || qtc.value == null) continue;
                        categoryMap.put(qtc.key,qtc.value);
                        data.categoryOptions.add(new SelectOption(qtc.value,qtc.value));
                    }
                }
            }else{
                throw new CustomException('Oops error returned by api call: '+res.errorMessage);
            }
            
            //Get Quick Text Options for running user
            DataEventTypeAction.DataEventTypeActionRequest req2 = new DataEventTypeAction.DataEventTypeActionRequest(GetQuickTextOptionsDETName,UserInfo.getUserId());
            DataEventTypeAction.DataEventTypeActionResult res2;
            if(Test.isRunningTest()){
                DataEventTypeAction.DataEventTypeActionResult testRes2 = new DataEventTypeAction.DataEventTypeActionResult(UserInfo.getUserId(),true);
                testRes2.responseBody = '[{"id":"637b7ea0b372e180bc1b47dc","name":"Thank you for enquiry","category":0,"message":"Thanks for your enquiry, give me a minute while I load up your details in our system please.","ownerUserId":null,"locale":"en-gb","hasVariables":false},{"id":"637b7ea0b372e180bc1b47dd","name":"Wait 5 - Hotel","category":2,"message":"Please give me 5 minutes whilst i try and call the hotel","ownerUserId":null,"locale":"en-gb","hasVariables":false},{"id":"637b99b59060db93305bf881","name":"Glad to help","category":1,"message":"I am glad that i was able to help, please do reach out again if there is anything else I can assist you with. ","ownerUserId":null,"locale":"en-gb","hasVariables":false}]';
                res2 = testRes2; 
            }else{
                res2 = DataEventTypeAction.invokeDataEventType(new List<DataEventTypeAction.DataEventTypeActionRequest>{req2})[0];
            } 
            if(res2.isSuccess){
                //Populate category map
                List<QuickTextData> quickTextDataList = (List<QuickTextData>)JSON.deserialize(res2.responseBody, List<QuickTextData>.class);
                if(quickTextDataList != null && quickTextDataList.size()>0){
                    for(QuickTextData qtd : quickTextDataList){
                        data.quickTextOptions.add(new QuickTextOption(qtd));
                    }
                }
            }else{
                throw new CustomException('Oops error returned by api call: '+res2.errorMessage);
            }

            system.debug(data);
            return data;

        } catch (Exception e) {
            Golfbreaks.PlatformLogManager.logExceptions(e,'ConversationQuickTextUtilityController','getQuickTextOptions');
            throw new AuraHandledException(e.getMessage()+'-'+e.getStackTraceString());
        }
    }

}