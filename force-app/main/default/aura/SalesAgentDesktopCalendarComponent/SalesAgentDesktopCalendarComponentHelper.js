({  
    getLeads : function(component, filterDate){
        var action = component.get("c.returnLeadRecords");
        
        action.setParams({
            "inFilterDate" : filterDate
        });
        
        action.setCallback(this, function(response){
        	var leadCollection = response.getReturnValue();
            if (null != leadCollection){
                var totalLeads = 0;
                var totalRecords = component.get("v.totalRecords");
                for (var i = 0 ; i < leadCollection.length ; i++){
                    totalLeads += leadCollection[i].recordCount;
                }
                component.set("v.todayLeads", leadCollection);
                component.set("v.totalRecords", totalRecords + totalLeads);
                component.set("v.totalLeads", totalLeads);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getOpps : function(component, filterDate){
        var action = component.get("c.returnOppRecords");
        
        action.setParams({
            "inFilterDate" : filterDate
        });
        
        action.setCallback(this, function(response){
        	var oppCollection = response.getReturnValue();
            if (null != oppCollection){
                var totalOpps = 0;
                var totalRecords = component.get("v.totalRecords");
                for (var i = 0 ; i < oppCollection.length ; i++){
                    totalOpps += oppCollection[i].recordCount;
                }
                component.set("v.totalOpps", totalOpps);
                component.set("v.totalRecords", totalRecords + totalOpps);
                component.set("v.todayOpps", oppCollection);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getCases : function(component, filterDate){
        var action = component.get("c.returnCaseRecords");
        
        action.setParams({
            "inFilterDate" : filterDate
        });
        
        action.setCallback(this, function(response){
        	var caseCollection = response.getReturnValue();
            if (null != caseCollection){
                var totalCases = 0;
                var totalRecords = component.get("v.totalRecords");
                for (var i = 0 ; i < caseCollection.length ; i++){
                    totalCases += caseCollection[i].recordCount;
                }
                component.set("v.totalCases", totalCases);
                component.set("v.totalRecords", totalRecords + totalCases);
                component.set("v.todayCases", caseCollection);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getReport : function(component, methodName, variablename) {
	var action = component.get("c." + methodName);    
    action.setCallback(this, function(a){
   	    component.set("v." + variablename, a.getReturnValue()); 
       });
      $A.enqueueAction(action);
	},
    
    getReportByDate : function(component, methodName, variablename, dateString) {
	var action = component.get("c." + methodName + "ByDate");    
        action.setParams({
            "dateString" : dateString
        });
    action.setCallback(this, function(a){
   	    component.set("v." + variablename, a.getReturnValue()); 
       });
      $A.enqueueAction(action);
	},
    
    getUserRecord : function(component){
        var action = component.get("c.getCurrentUser");
        action.setCallback(this, function(response){
        	component.set("v.currentUser", response.getReturnValue());                   
		});
    
        $A.enqueueAction(action);
    },
    
    getCurrDate : function(component){
        var action = component.get("c.getCurrentDateList");
        action.setCallback(this, function(response){
           var dtList = response.getReturnValue();
           component.set("v.prevDate", dtList[0]); 
           component.set("v.filterDate", dtList[1]); 
           component.set("v.nextDate", dtList[2]); 

        });
        
        $A.enqueueAction(action);
    },
    
    getColumnHeaders : function(component, whichObject, variableName,caseTypes){
        var action = component.get("c.getColumnHeaders");
        action.setParams({
            "whichObject" : whichObject,
            "caseTypes" : caseTypes
        });
        action.setCallback(this, function(response){
            console.log('Col Headers for ' + whichObject + ' ' + response.getReturnValue());
            component.set("v." + variableName, response.getReturnValue());
        });
        $A.enqueueAction(action);
    }
})