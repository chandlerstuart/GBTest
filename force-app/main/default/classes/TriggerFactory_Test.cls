@isTest
private class TriggerFactory_Test {

	private static testMethod void test() {
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        database.insert(acc);
        
        database.update(acc);  
        
        database.delete(acc);
	}

}