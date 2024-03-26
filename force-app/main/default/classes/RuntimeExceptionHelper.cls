/*
Name:  RuntimeExceptionHelper.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Helper class that controls logging of runtime exceptions

Future enhancements:
Better internal error handling.
======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-31    Initial development.
*/
public class RuntimeExceptionHelper {

    public Class testThrownException extends Exception{}
    
    Class invalidInputDataException extends Exception{}

    public static void logException(Exception e) {
        try {
            RunTimeExceptionSettings__c rtes = RunTimeExceptionSettings__c.getInstance();
            if(rtes == null) return;

            if(rtes.LogToCustomObject__c) {
                logExceptionToCustomObject(e);
            }

            if(rtes.LogToEmail__c) {
                if(rtes.ExceptionEmail__c != null) {
                    logExceptionToEmail(e);
                }
            }

            if(rtes.LogToDebugLog__c) {
                logExceptionToDebugLog(e.getMessage(), e.getStackTraceString());
            }
        } catch (Exception ex) {
            logLocalException();
        }
    }

    public static void logExceptionToCustomObject(Exception e) {
        try {
            logToCustomObject(e.getMessage(), e.getStackTraceString());
        } catch (Exception ex) {
            logLocalException();
        }
    }

    public static void logExceptionToEmail(Exception e) {
        try {
            RunTimeExceptionSettings__c rtes = RunTimeExceptionSettings__c.getInstance();
            if(rtes == null) return;

            if(rtes.ExceptionEmail__c != null) {
                notifyByEmail(e.getMessage(), e.getStackTraceString(), rtes.ExceptionEmail__c);
            }
        } catch (Exception ex) {
            logLocalException();
        }
    }

    public static void logExceptionToDebugLog(String message, String stackTrace) {
        try {
            if (message == null || message.length() == 0) throw new invalidInputDataException('Invalid data. No message');
            System.debug(LoggingLevel.ERROR, '\nMessage: '+message + ' \nStackTrace: ' + stackTrace);
        } catch (Exception ex) {
            logLocalException();
        }
    }

    @future
    private static void logToCustomObject(String message, String stackTrace) {
        try {
            if(message == null || message.length() ==0) throw new invalidInputDataException('Invalid data. No message');

            RuntimeException__c re = new RuntimeException__c();
            re.Message__c = message;
            re.StackTrace__c = stackTrace;
            re.User__c = UserInfo.getUserId();
            insert re;
        } catch (Exception ex) {
            logLocalException();
        }
    }

    private static void notifyByEmail(String message, String stackTrace, String emailAddress) {
        try {
            if(message == null || message.length() ==0) throw new invalidInputDataException('Invalid data. No message');

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {emailAddress};
            mail.setToAddresses(toAddresses);
            mail.setReplyTo(emailAddress);
            mail.setSenderDisplayName(UserInfo.getOrganizationName()+' Admin');
            mail.setSubject('Runtime Exception');
            mail.setPlainTextBody('\nMessage: '+message + '\nStackTrace: ' + stackTrace);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception ex) {
            logLocalException();
        }
    }

    private static void logLocalException() {
        System.debug(LoggingLevel.ERROR, System.Label.RuntimeExceptionHelperError);
    }
    
}