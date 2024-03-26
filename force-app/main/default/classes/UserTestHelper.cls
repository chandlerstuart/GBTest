/*
Name:  UserTestHelper.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2013-05-21  Initial development.
*/
@isTest
public with sharing class UserTestHelper {

    /* */
    public static List<User> createStandardUsers(Integer n, String firstNamePrefix, String lastNamePrefix){
        return createStandardUsers(n, firstNamePrefix, lastNamePrefix, true);
    }
    /* */
    
    /* */
    public static List<User> createStandardUsers(Integer n, String firstNamePrefix, String lastNamePrefix, Boolean proceedToInsert){
        User u;
        List<User> users = new List<User>();

        Id userProfileId = [select Id from Profile where Name = 'Standard User'].Id;
        Id roleId = [select Id from UserRole where ParentRoleId = null limit 1].Id;

        for (Integer i=0; i<n; i++) {
            u = new User();
            
            buildUser(u, firstNamePrefix, lastNamePrefix, i);
            
            u.ProfileId = userProfileId;
            u.UserRoleId = roleId;

            users.add(u);
        }
        if (proceedToInsert) insert users;
        
        return users;
    }
    /* */

    /* */
    public static void setupOrgSettings() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c=true, ValidationRulesActive__c=true, WorkflowRulesActive__c=true);
        insert orgSettings;
    }
    /* */
    
    private static void buildUser(User u, String fn, String ln, Integer i){
        u.username = fn+'.'+ln+i.format()+'@cloudmethods.unittesting.com';
        u.email = fn+'.'+ln+i.format()+'@cloudmethods.unittesting.com';
        u.FirstName = fn+i.format();
        u.LastName = ln+i.format();         
        u.alias = fn+i.format();
        u.languagelocalekey='en_US';
        u.localesidkey='en_US';
        u.timezonesidkey='Europe/London';
        u.emailencodingkey='UTF-8';
        u.isactive = true;
    }

}