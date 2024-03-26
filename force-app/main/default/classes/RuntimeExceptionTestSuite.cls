@isTest
private class RuntimeExceptionTestSuite {
    //Create a exception extension we can throw at will
    Class CustomException extends Exception{}

    @isTest static void testLogException() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Create a test user
            User u = UserTestHelper.createStandardUsers(1, 'Buck', 'Bonzai')[0];
            
            //Create the custom setting
            RuntimeExceptionSettings__c settings = new RuntimeExceptionSettings__c();
            settings.LogToCustomObject__c = true;
            settings.LogToEmail__c = false;
            settings.LogToDebugLog__c = false;
            settings.ExceptionEmail__c = 'orn@kaptio.com';
            //settings.OwnerId = u.Id;
            insert settings;

            System.runAs(u) {
                try {
                    throw new CustomException('Error');
                } catch(Exception e) {
                    RuntimeExceptionHelper.logException(e);
                }
            }
            //RuntimeException__c re = [SELECT Id, Message__c, StackTrace__c FROM RuntimeException__c LIMIT 1];
            //System.assertEquals(re.Message__c, 'Error');
        }
    }
    
    @isTest static void testLogByEmail() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Create a test user
            User u = UserTestHelper.createStandardUsers(1, 'Buck', 'Bonzai')[0];
            
            //Create the custom setting
            RuntimeExceptionSettings__c settings = new RuntimeExceptionSettings__c();
            settings.LogToCustomObject__c = false;
            settings.LogToEmail__c = true;
            settings.LogToDebugLog__c = false;
            settings.ExceptionEmail__c = 'orn@kaptio.com';
            //settings.OwnerId = u.Id;
            insert settings;

            System.runAs(u) {
                try {
                    throw new CustomException('Error');
                } catch(Exception e) {
                    RuntimeExceptionHelper.logException(e);
                }
            }
        }
    }

    @isTest static void testLogToDebuglog() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Create a test user
            User u = UserTestHelper.createStandardUsers(1, 'Buck', 'Bonzai')[0];
            
            //Create the custom setting
            RuntimeExceptionSettings__c settings = new RuntimeExceptionSettings__c();
            settings.LogToCustomObject__c = false;
            settings.LogToEmail__c = false;
            settings.LogToDebugLog__c = true;
            settings.ExceptionEmail__c = 'orn@kaptio.com';
            //settings.OwnerId = u.Id;
            insert settings;

            System.runAs(u) {
                try {
                    throw new CustomException('Error');
                } catch(Exception e) {
                    RuntimeExceptionHelper.logException(e);
                }
            }
        }
    }
}