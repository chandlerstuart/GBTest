public with sharing class RecordWrapper {
	@AuraEnabled
	public SObject obj {get; set;}

	@AuraEnabled
	public String objType {get; set;}

	@AuraEnabled
	public String objClass {
		get {
			if (null == objClass) objClass = LC07_SalesAgentDesktopController.SHOW_BLACK_CLASS;
			return objClass;
		}
		set;
	}

	public RecordWrapper(SObject inObject, String inObjectType) {
		this.obj = inObject;
		this.objType = inObjectType;

		if ('LEAD'.equalsIgnoreCase(inObjectType)){
			Lead l = (Lead) inObject;
			if (null != l.DiaryDate__c){
				if (l.DiaryDate__c < Date.today()){
					objClass = LC07_SalesAgentDesktopController.SHOW_RED_CLASS;
				}
			}	
		}else if ('OPPORTUNITY'.equalsIgnoreCase(inObjectType)){
			Opportunity o = (Opportunity) inObject;
			if (null != o.DiaryDate__c){
				if (o.DiaryDate__c < Date.today()){
					objClass = LC07_SalesAgentDesktopController.SHOW_RED_CLASS;
				}
			}
		}else if ('CASE'.equalsIgnoreCase(inObjectType)){
			Case c = (Case)inObject;
			if (null != c.DiaryDate__c){
				if (c.DiaryDate__c < Date.today()){
					objClass = LC07_SalesAgentDesktopController.SHOW_RED_CLASS;
				}
			}
		}

		
	}
}