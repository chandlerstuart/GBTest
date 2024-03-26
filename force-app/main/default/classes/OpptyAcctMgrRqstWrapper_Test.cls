@isTest
private class OpptyAcctMgrRqstWrapper_Test{
    static{
        new OpportunityAccountManagerRequestWrapper();
    }

    static testmethod void testOpptyAcctMgrWrapper(){
        OpportunityAccountManagerRequestWrapper.EmployeeModel obj1 = new OpportunityAccountManagerRequestWrapper.EmployeeModel(1234, 'test2@email.com', 'John', 'Smith'); 
        OpportunityAccountManagerRequestWrapper.EmployeeModel obj2 = new OpportunityAccountManagerRequestWrapper.EmployeeModel(null, 'test2@email.com', 'John', 'Smith'); 
        OpportunityAccountManagerRequestWrapper.EmployeeModel obj3 = new OpportunityAccountManagerRequestWrapper.EmployeeModel(null, '', 'John', 'Smith');   
    }
}