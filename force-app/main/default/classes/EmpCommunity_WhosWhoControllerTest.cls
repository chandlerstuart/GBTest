/*
Name:  EmpCommunity_WhosWhoControllerTest.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test class for EmpCommunity_WhosWhoController
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2016-10-24  Initial development.
*/
@isTest(SeeAllData=true)
private class EmpCommunity_WhosWhoControllerTest {
    
    @IsTest
    static void testGetSearchValues(){
        test.startTest();
            Map<String, List<String>> searchValues = 
                EmpCommunity_WhosWhoController.getSearchValues();
        test.stopTest();
        
        system.assertNotEquals(null, searchValues);
    }
    
    @IsTest
    static void testGetAllPages() {
        test.startTest();
        Map<integer, List<EmpCommunity_WhosWhoController.UserWrapper>> allPages = 
        EmpCommunity_WhosWhoController.getAllPages();
                
        test.stopTest();
        
        system.assertNotEquals(null, allPages);
    }

    @IsTest
    static void testSearchUser() {
        //We need to set up test data when testing ConnectAPI Classes
        String searchString = 'Test';
        ConnectApi.UserPage userPage = new ConnectApi.UserPage();
        ConnectApi.UserPage userPage2 = new ConnectApi.UserPage();
        List<ConnectApi.UserDetail> userList = new List<ConnectApi.UserDetail>();
        List<ConnectApi.UserDetail> userList2 = new List<ConnectApi.UserDetail>();
        userList.add(new ConnectApi.UserDetail());
        userList.add(new ConnectApi.UserDetail());
        userList2.add(new ConnectApi.UserDetail());
        userList2.add(new ConnectApi.UserDetail());
        userPage.users = userList;
        userPage2.users = userList2;
        userPage.currentPageToken = 0;
        userPage.nextPageToken = 1;
        userPage2.currentPageToken = 1;
        userPage2.previousPageToken = 0;
        
        ConnectApi.ChatterUsers.setTestSearchUsers(Network.getNetworkId(),searchString,0,100,userPage); 
        ConnectApi.ChatterUsers.setTestSearchUsers(Network.getNetworkId(),searchString,1,100,userPage2);
    
        test.startTest();

        List<EmpCommunity_WhosWhoController.UserWrapper> userWrapperList = 
                EmpCommunity_WhosWhoController.searchUsers(searchString);
                
        test.stopTest();
        
        system.assertNotEquals(null, userWrapperList);
    }
    
    @IsTest
    static void testSearchManager() {
        //We need to set up test data when testing ConnectAPI Classes
        String managerName = 'Test';
        test.startTest();

        List<EmpCommunity_WhosWhoController.UserWrapper> userWrapperList = 
                EmpCommunity_WhosWhoController.searchByManager(managerName);
                
        test.stopTest();
        
        system.assertNotEquals(null, userWrapperList);
    }
    
    @IsTest
    static void testSearchRole() {
        //We need to set up test data when testing ConnectAPI Classes
        String roleName = 'Test';
        test.startTest();

        List<EmpCommunity_WhosWhoController.UserWrapper> userWrapperList = 
                EmpCommunity_WhosWhoController.searchByRole(roleName);
                
        test.stopTest();
        
        system.assertNotEquals(null, userWrapperList);
    }
    
}