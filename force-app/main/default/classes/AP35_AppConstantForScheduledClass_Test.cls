@isTest
public class AP35_AppConstantForScheduledClass_Test {	
	@isTest static void testConstants() {
		// Implement test code
		System.assertEquals('Queue', AP35_AppConstantForScheduledClass.CASE_OWNER_QUEUE);
		System.assertEquals('New', AP35_AppConstantForScheduledClass.CASE_STATUS_NEW);
		System.assertEquals('CS-Urgent', AP35_AppConstantForScheduledClass.QUEUE_CS_URGENT);
	}
}