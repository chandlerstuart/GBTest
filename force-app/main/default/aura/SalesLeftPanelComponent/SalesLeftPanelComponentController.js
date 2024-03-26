({
    doInit : function(component, event, helper) {        
		helper.getReport(component, "getTodayReportLeads", "todayLeads");        
        helper.getReport(component, "getTodayReportOpportunities", "todayOpps");
        helper.getReport(component, "getTodayReportCases", "todayCases");
        helper.getReport(component, "getTodayReportTasks", "todayTasks");
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
        
        evt.fire();        
    }
    
    
 })