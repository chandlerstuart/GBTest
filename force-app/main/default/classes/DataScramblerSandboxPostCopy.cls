/*
Name:  DataScramblerSandboxPostCopy.cls
======================================================
======================================================
Purpose:
-------
Post Sandbox Copy class used to call DataScrambler

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-30  Initial development.
*/
global class DataScramblerSandboxPostCopy implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        DataScrambler dsLead = new DataScrambler('LEAD');
        DataScrambler dsAccount = new DataScrambler('ACCOUNT');
        
        Database.executebatch(dsLead,2000);
        Database.executebatch(dsAccount,2000);     
    }
}