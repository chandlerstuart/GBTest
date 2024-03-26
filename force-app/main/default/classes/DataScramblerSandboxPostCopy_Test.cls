/*
Name:  DataScramblerSandboxPostCopy_Test.cls
======================================================
======================================================
Purpose:
-------
Test class for DataScramblerSandboxPostCopy

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-10-26  Initial development.
*/
@isTest
private class DataScramblerSandboxPostCopy_Test {
    

    static testmethod void testSandboxPostCopyScript() {
    	Id orgId = UserInfo.getOrganizationId();
    	Id sandboxId = orgId;
    	DataScramblerSandboxPostCopy dsspc = new DataScramblerSandboxPostCopy();

    	Test.testSandboxPostCopyScript(dsspc,orgId, sandboxId, 'Test');
    }
       
}