/*
Name:  UserManager.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Manager class for the User Object

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-05-21      Initial development.
*/
public with sharing class UserManager {

    /*
    getListViewOptions
    ------------------------
    Purpose: Gets a list of list-view filters from the User object
    Input: StandardSetController for user object
    Output: Array of SelectOption objects
    */
    public static SelectOption[] getListViewOptions(ApexPages.StandardSetController userSetController){
        List<SelectOption> results = new List<SelectOption>();
        SelectOption[] options = userSetController.getListViewOptions();
        results.add(new SelectOption('','Choose filter'));
        for(SelectOption option : options){
            results.add(new SelectOption(option.getValue(),option.getLabel()));
        }
        return results;
    }

    /*
    getUsers
    ------------------------
    Purpose: Gets the user records of users in a standardSetController
    Input: StandardSetController for user object
    Output: List of User records
    */
    public static List<User> getUsers(ApexPages.StandardSetController userSetController) {
        return (List<User>) userSetController.getRecords();
    }

    /*
    getUsersId
    ------------------------
    Purpose: Gets the user ids from the users in a standardSetController
    Input: StandardSetController for user object
    Output: Set if user Ids
    */
    public static Set<Id> getUsersId(ApexPages.StandardSetController userSetController){
        return UserManager.getUserIdsFromList( UserManager.getUsers( userSetController ) );
    }

    /*
    getUsersById
    ------------------------
    Purpose: Gets User records by a set of ids.
    Input: Set of userIds 
    Output: List of user records
    */
    public static List<User> getUsersById(Set<Id> userIds){
        List<User> userlist = new List<User>();
        try{
            userlist = [ SELECT Id, Name FROM User WHERE Id IN: userIds ];
        }catch(Exception e){
            System.debug('No users found with ids:  '+ userIds +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return userlist;
    }

    /*
    getUserIdsFromList
    ------------------------
    Purpose: Gets a list of user ids from a list of user records
    Input: List of user records
    Output: Set of Ids
    */
    public static Set<Id> getUserIdsFromList(List<User> users){
        Set<Id> userIds = new Set<Id>();
        for(User u : users){
            userIds.add(u.Id);
        }
        return userIds;
    }

}