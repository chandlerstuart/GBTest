/*
-------
Name:
GenerateGuidAction.cls
========================================================
========================================================
Purpose:
-------
Apex Action class for Generating a GUID 
========================================================
========================================================
Verison     Author         Date           Detail
1.0        C Stuart        26/04/2023     Inital Deployment - Added generateGuid Method 
1.1        J Radcliffe     13/02/2024     Redirect action to NEW natively supported guid generator method.
*/

public with sharing class GenerateGuidAction {

    @TestVisible public static Boolean throwException = false;
    @TestVisible public static final String errorMessage = 'An unexpected error occured';

    //Apex Action to be pass through a Flow, to generate a 35 digit GUID for the Password reset token.
    @InvocableMethod(label='Generate Guid' description= 'Create\'s a GUID')
    public static List<Result> generateGuid(List<Request> reqList){
        List<Result> guid = new List<Result>();

        try{
            for(Request req : reqList){
                Result res = new Result();
                //res.guid = GlobalUtility.newGuid();//1.1-
                res.guid = UUID.randomUUID().toString();//1.1+
                res.idx = req.idx;
                guid.add(res);
            }
            if(throwException) throw new GenerateGuidActionTest.CustomException(errorMessage);
            return guid;
        } catch (Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e, 'GenerateGuidAction','generateGuid');
            return null;
        }
    }

    public class Request {
        @invocableVariable(label='idx' description='optional unique Id for coupling with new guid') // Forced to create a parameter for the code compile
        public String idx;
    }

    public class Result {
        @invocableVariable(label='Output Records' description='Stored Guids')
        public String guid;
        @invocableVariable(label='idx' description='optional unique Id for coupling with new guid')
        public String idx;
    }
}