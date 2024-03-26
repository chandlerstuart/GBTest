({
    doInit : function(component, event, helper) {  
        helper.getUserRecord(component);
        helper.getCurrDate(component);
        //New code to get column headers
        helper.getColumnHeaders(component, "Lead", "leadColumnHeaders","");
        helper.getColumnHeaders(component, "Opportunity", "oppColumnHeaders","");
        //helper.getColumnHeaders(component, "Case", "caseColumnHeaders");
        //helper.getColumnHeaders(component, "Case", "bookingCaseColumnHeaders","Booking");
        helper.getColumnHeaders(component, "Case", "leadOppCaseColumnHeaders","LeadOpp");
        var fDate = new Date();
        var y = fDate.getFullYear();
        var m = (fDate.getMonth()+1 < 10 ? '0' + (fDate.getMonth()+1) : fDate.getMonth()+1);
        var d = (fDate.getDate() < 10 ? '0' + fDate.getDate() : fDate.getDate());
        var filterDate = y + '-' + m + '-' + d;
        helper.getLeads(component, filterDate);
        helper.getOpps(component, filterDate);
        helper.getCases(component, filterDate);
    },
    
    handleOppUpdate : function(component, event, helper){
    	var fDate = new Date();
        var y = fDate.getFullYear();
        var m = (fDate.getMonth()+1 < 10 ? '0' + (fDate.getMonth()+1) : fDate.getMonth()+1);
        var d = (fDate.getDate() < 10 ? '0' + fDate.getDate() : fDate.getDate());
        var filterDate = y + '-' + m + '-' + d;
        component.set("v.totalRecords",0);
        helper.getOpps(component, filterDate);	    
    },
    
    checkDateChange : function(component, event, helper){
    	var whichDate = component.find("v.inputFilterDate").get("v.value");
        console.log(whichDate);
    },
    
    doTodayFilter : function(component, event, helper){
        console.log('Today Filter');
        var fDate = new Date();
        var y = fDate.getFullYear();
        var m = (fDate.getMonth()+1 < 10 ? '0' + fDate.getMonth()+1 : fDate.getMonth()+1);
        var d = (fDate.getDate() < 10 ? '0' + fDate.getDate() : fDate.getDate());
        var filterDate = y + '-' + m + '-' + d;
        
        component.set("v.filterDate",filterDate);
        
        helper.getLeads(component, filterDate);
        helper.getOpps(component, filterDate);
        helper.getCases(component, filterDate);
        
    },
    
    doAllDateFilter : function(component, event, helper){
        console.log('All Date Filter');
    	var filterDate = component.get("v.filterDate");
        helper.getLeads(component, filterDate);
        helper.getOpps(component, filterDate);
        helper.getCases(component, filterDate);
    },
    
    openListView: function(component, event, helper) {
           var  url;
		if (event.getSource) {
            // handling a framework component event
            var src = event.getSource();
        	url = src.get("v.class");
        } else {
            // handling a native browser event
            url = event.target.class; // this is a DOM element
        }
 		
        sforce.console.openPrimaryTab(null , url, true);
    },
    
    showSpinner : function (component, event, helper) {
        var spinner = component.find("spinner");        
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });		
        var y = document.getElementById("summaryTable");
        $A.util.addClass(y, "slds-hide");        
        evt.fire();    
    },
    hideSpinner : function (component, event, helper) {        
        var spinner = component.find("spinner");
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        var x = document.getElementById("summaryTable");
        $A.util.removeClass(x, "slds-hide");
        
		//Open the Calendar tab
        var calendarURL = '/00U/c?cType=1&isdtp=vw';
        var user = component.get("v.currentUser");

        sforce.console.openPrimaryTab(null,encodeURI(calendarURL),false,'Calendar for ' + user.Name);        

        evt.fire();        
    },
    
    objectSelectChange : function(component, event, helper){
        //FOUR tables are leadTable, oppTable, caseTable, taskTable
        var selObj = component.find("objectSelect").get("v.value");
        if ('ALL' == selObj){
            var leadTable = component.find("leadTable");
            var oppTable = component.find("oppTable");
            var caseTable = component.find("caseTable");
            var taskTable = component.find("taskTable");
            
            $A.util.removeClass(leadTable, "slds-hide");
            $A.util.removeClass(oppTable, "slds-hide");
            $A.util.removeClass(caseTable, "slds-hide");
            $A.util.removeClass(taskTable, "slds-hide");
            
        }else {
            var leadTable = component.find("leadTable");
            var oppTable = component.find("oppTable");
            var caseTable = component.find("caseTable");
            var taskTable = component.find("taskTable");
            
            $A.util.addClass(leadTable, "slds-hide");
            $A.util.addClass(oppTable, "slds-hide");
            $A.util.addClass(caseTable, "slds-hide");
            $A.util.addClass(taskTable, "slds-hide");

            var showTable = component.find(selObj + "Table");
        	$A.util.removeClass(showTable, "slds-hide");  
        }
		
    },
    
    refreshViews : function(component, event, helper){
        var fDate = new Date();
        var y = fDate.getFullYear();
        var m = (fDate.getMonth()+1 < 10 ? '0' + (fDate.getMonth()+1) : fDate.getMonth()+1);
        var d = (fDate.getDate() < 10 ? '0' + fDate.getDate() : fDate.getDate());
        var filterDate = y + '-' + m + '-' + d;
        component.set("v.totalRecords",0);
        helper.getLeads(component, filterDate);
        helper.getOpps(component, filterDate);
        helper.getCases(component, filterDate);
    }
    
 })