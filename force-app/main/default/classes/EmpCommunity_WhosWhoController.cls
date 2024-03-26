/*
Name:  EmpCommunity_WhosWhoController.cls
Copyright © 2016  Golfbreaks.
======================================================
======================================================
Purpose:
-------
Controller for EmpCommunity_WhosWho Lightning Component. 
getAllUsers method - Retrieves a list of Users and their profiles
getUsersByGroup - Retrieves a list of users and their profiles by selected group
======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Simon Molloy        2016-09-27  Class creation.
2.0  Simon Molloy        2016-11-07  Changed to manual paging

*/
public without sharing class EmpCommunity_WhosWhoController {
    public static final String WORK_PHONE_TYPE = 'Work';
    public static final integer PAGE_SIZE = 25;

    //2016-11-08 : SM : Init method to get
    //Managers and Roles

    @AuraEnabled
    public static Map<String, List<String>> getSearchValues(){
        Map<String, List<String>> returnValues = new Map<String, List<String>>();
        Set<String> roles = new Set<String>();
        Set<String> mgrs = new Set<String>();
        Set<Id> userIdSet = new Set<Id>();
        
        ConnectApi.UserPage userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(),0,100);
        integer nextPageToken = userPage.nextPageToken;

        for (ConnectApi.UserDetail ud : userPage.users){
            mgrs.add(ud.managerName);
            userIdSet.add(ud.Id);
        }

        while (nextPageToken != null){
            userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(), nextPageToken, 100);
            for (ConnectApi.UserDetail ud : userPage.users){
                mgrs.add(ud.managerName);
                userIdSet.add(ud.Id);
            }
            nextPageToken = userPage.nextPageToken;
        }
        
        for (User u : [select Id, UserRole.Name from User where Id in :userIdSet]){
            roles.add(u.UserRole.Name);
        }
        
        List<String> roleList = new List<String>();
        roleList.addAll(roles);
        roleList.sort();
        List<String> mgrList = new List<String>();
        mgrList.addAll(mgrs);
        mgrList.sort();
        
        returnValues.put('ROLES',roleList);
        returnValues.put('MANAGERS',mgrList);
        
        return returnValues;
        
    }
    
    @AuraEnabled
    public static Map<integer, List<UserWrapper>> getAllPages(){
        Map<integer, List<UserWrapper>> returnMap = new Map<integer, List<UserWrapper>>();
        Map<Id, User> userMap = new Map<Id, User>([select Id, UserRole.Name from User where IsActive = TRUE]);
        
        ConnectApi.UserPage userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(),0,PAGE_SIZE);
        integer nextPageToken = userPage.nextPageToken;

        //Initial Page
        List<UserWrapper> uwList = new List<UserWrapper>();
        for (ConnectApi.UserDetail ud : userPage.users){
            UserWrapper uw = new UserWrapper(ud,false);
            if (null != userMap.get(ud.Id)){
                uw.roleName = userMap.get(ud.Id).UserRole.Name;
            }
            uwList.add(uw);
        }
        
        returnMap.put(0,uwList);

        //Other Pages
        while (nextPageToken != null){
            userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(), nextPageToken, PAGE_SIZE);
            uwList = new List<UserWrapper>();
            for (ConnectApi.UserDetail ud : userPage.users){
                UserWrapper uw = new UserWrapper(ud,false);
                if (null != userMap.get(ud.Id)){
                    uw.roleName = userMap.get(ud.Id).UserRole.Name;
                }
                uwList.add(uw);
            }

            returnMap.put(nextPageToken,uwList);
            
            nextPageToken = userPage.nextPageToken;
        }
        
        return returnMap;
        
    }

    //2016-11-08 : SM : Method to search for users based on Manager selection
    @AuraEnabled
    public static List<UserWrapper> searchByManager(String mgrName){
        system.debug('*** -- into search by manager -- ***');
        Map<Id, UserWrapper> userWrapperMap = new Map<Id, UserWrapper>();
        if (null == mgrName || String.isBlank(mgrName)) return userWrapperMap.values();
        
        ConnectApi.UserPage userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(),0,50);
        integer nextPageToken = userPage.nextPageToken;

        for (ConnectApi.UserDetail ud : userPage.users){
            if (mgrName.equalsIgnoreCase(ud.managerName)){
                //system.debug('*** -- User Detail In Build for ' + ud.firstName + ' '  + ud.lastName + ' ' + ud.managerName + ' ' + ud.managerId + '-- ***');
                UserWrapper uw = new UserWrapper(ud,false);
                userWrapperMap.put(ud.Id, uw);
            }   
        }

        while (nextPageToken != null){
            userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(), nextPageToken, 50);
            for (ConnectApi.UserDetail ud : userPage.users){
                if (mgrName.equalsIgnoreCase(ud.managerName)){
                    //system.debug('*** -- User Detail In Build for Page 2 ' + ud.firstName + ' '  + ud.lastName + ' ' + ud.managerName + ' ' + ud.managerId + '-- ***');
                    UserWrapper uw = new UserWrapper(ud,false);
                    userWrapperMap.put(ud.Id, uw);
                }   
            }
            nextPageToken = userPage.nextPageToken;
        }
        
        for (User u : [select Id, UserRole.Name from User where Id in :userWrapperMap.keySet()]){
            userWrapperMap.get(u.Id).roleName = u.UserRole.Name;
        }
        
        system.debug('*** -- Found ' + userWrapperMap.size() + ' users in manager search -- ***');
        return userWrapperMap.values();
    }
    
    //2016-11-08 : SM : Method to search for users based on Role selection
    @AuraEnabled
    public static List<UserWrapper> searchByRole(String roleName){
        system.debug('*** -- into search by manager -- ***');
        Map<Id, UserWrapper> userWrapperMap = new Map<Id, UserWrapper>();
        List<UserWrapper> returnValues = new List<UserWrapper>();
        if (null == roleName || String.isBlank(roleName)) return userWrapperMap.values();
        
        ConnectApi.UserPage userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(),0,100);
        integer nextPageToken = userPage.nextPageToken;

        for (ConnectApi.UserDetail ud : userPage.users){
            UserWrapper uw = new UserWrapper(ud,false);
            userWrapperMap.put(ud.Id, uw);
        }

        while (nextPageToken != null){
            userPage = ConnectApi.ChatterUsers.getUsers(Network.getNetworkId(), nextPageToken, 100);
            for (ConnectApi.UserDetail ud : userPage.users){
                UserWrapper uw = new UserWrapper(ud,false);
                userWrapperMap.put(ud.Id, uw);
            }
            nextPageToken = userPage.nextPageToken;
        }
        
        for (User u : [select Id, UserRole.Name from User where Id in :userWrapperMap.keySet()]){
            if (roleName.equalsIgnoreCase(u.UserRole.Name)){
                returnValues.add(userWrapperMap.get(u.Id));
            }
        }
        
        return returnValues;
    }


    @AuraEnabled
    public static List<UserWrapper> searchUsers(String searchString){
        system.debug('*** -- Search for ' + searchString + ' -- ***');
        List<UserWrapper> userWrapperList = new List<UserWrapper>();
        Map<Id, UserWrapper> userWrapperMap = new Map<Id, UserWrapper>();
        ConnectApi.UserPage userPage = ConnectApi.ChatterUsers.searchUsers(Network.getNetworkId(), searchString,0,100);

        if (null != userPage){
            system.debug('*** -- userPage is found with token ' + userPage.nextPageToken + ' and ' + userPage.users + ' users -- ***');
        }

        integer nextPageToken = userPage.nextPageToken;
    
        if (!userPage.users.isEmpty()){
            for (ConnectApi.UserDetail ud : userPage.users){
                UserWrapper uw = new UserWrapper(ud, true);
                userWrapperMap.put(ud.Id, uw);
                //userWrapperList.add(new UserWrapper(ud, true));
            }
        }

        while (nextPageToken != null){
            userPage = ConnectApi.ChatterUsers.searchUsers(Network.getNetworkId(), searchString, nextPageToken, 100);
            if (!userPage.users.isEmpty()){
                for (ConnectApi.UserDetail ud : userPage.users){
                    UserWrapper uw = new UserWrapper(ud, true);        
                    userWrapperMap.put(ud.Id, uw);
                    //userWrapperList.add(new UserWrapper(ud, true));
                }
            }
            nextPageToken = userPage.nextPageToken;
        }

        system.debug('*** -- About to return ' + userWrapperMap.size() + ' user wrappers -- ***');

        for (User u : [select Id, UserRole.Name from User where Id in :userWrapperMap.keySet()]){
            userWrapperMap.get(u.Id).roleName = u.UserRole.Name;
        }
    
        return userWrapperMap.values();
    }

    public class UserWrapper {
        @AuraEnabled
        public ConnectApi.UserDetail userDetailRecord {get; set;}
        @AuraEnabled
        public User userRecord {get; set;}
        @AuraEnabled
        public String photoURL {get; set;}
        @AuraEnabled
        public String largePhotoURL {get; set;}
        @AuraEnabled
        public String title {get; set;}
        @AuraEnabled
        public String firstName {get; set;}
        @AuraEnabled
        public String lastName {get; set;}
        @AuraEnabled
        public String workPhone {get; set;}
        @AuraEnabled
        public String managerName {get; set;}
        @AuraEnabled
        public Id managerId {get; set;}
        @AuraEnabled
        public String roleName {get; set;}
        @AuraEnabled
        public String aboutMe {get; set;}
        @AuraEnabled
        public boolean showDetails {
            get {
                if (null == showDetails) showDetails = false;

                return showDetails;
            }
            set;
        }

        public UserWrapper(ConnectApi.UserDetail ud, boolean showDetails){
            
            this.userDetailRecord = ud;
            if (ud.photo != null){
                this.photoURL = ud.photo.smallPhotoUrl;
                this.largePhotoURL = ud.photo.largePhotoUrl;
            }
            this.title = ud.title;
            this.firstName = ud.firstName;
            this.lastName = ud.lastName;
            this.managerName = ud.managerName;
            this.managerId = ud.managerId;
            this.aboutMe = ud.aboutMe;
            if (null != ud.phoneNumbers && !ud.phoneNumbers.isEmpty()){
                for (ConnectApi.PhoneNumber pn : ud.phoneNumbers){
                    if (WORK_PHONE_TYPE.equalsIgnoreCase(pn.phoneType)){
                        this.workPhone = pn.phoneNumber;
                    }
                }
            }
            this.showDetails = showDetails;
        }
    }
}