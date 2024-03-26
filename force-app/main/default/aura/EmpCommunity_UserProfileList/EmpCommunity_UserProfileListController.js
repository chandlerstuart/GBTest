({
	doInit : function(component, event, helper) {
        //shows spinner 
        var x = document.getElementById("spinner");
        $A.util.removeClass(x, "slds-hide");
        
        var getSearchVals = component.get("c.getSearchValues");
        getSearchVals.setCallback(this, function(response){
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
                var searchVals = response.getReturnValue();
                var mgrs = searchVals['MANAGERS'];
                var roles = searchVals['ROLES'];
                component.set("v.managerList",mgrs);
                component.set("v.roleList",roles);
            }else {
                //shows spinner 
        		var x = document.getElementById("spinner");
		        $A.util.addClass(x, "slds-hide");
                
                helper.processError(component, event, response);
            }
        });
        
        $A.enqueueAction(getSearchVals);        
        
        helper.getAllPages(component, event);
	},
    
    getNext : function(component, event, helper){
		var nextToken = parseInt(component.get("v.nextToken"));
        var allPages = component.get("v.allPages");
        var userList = allPages[nextToken];
        
        var prevToken = nextToken-1;
        nextToken++;
        if (nextToken > allPages.length) nextToken = allPages.length;
        if (prevToken < 0) prevToken = 0;
        
        component.set("v.nextToken",nextToken.toString());
        component.set("v.prevToken",prevToken.toString());
        component.set("v.uList",userList);
    },
    
    getPrev : function(component, event, helper){
        var prevToken = parseInt(component.get("v.prevToken"));
        var allPages = component.get("v.allPages");
        var userList = allPages[prevToken];
        
        var nextToken = prevToken + 1;
        prevToken--;
        if (prevToken < 0) prevToken = 0;
        if (nextToken > allPages.length) nextToken = allPages.length;
        
        component.set("v.nextToken",nextToken.toString());
        component.set("v.prevToken",prevToken.toString());
        component.set("v.uList",userList);
    },
    
    doSearch : function(component, event, helper){
        var searchString = component.find("searchInput").get("v.value");
        if (searchString == null || searchString.length < 2){
            //Do not do anything
        }
        //Clear the current user list
        component.set("v.uList", null); 
        
        var x = document.getElementById("spinner");
        $A.util.removeClass(x, "slds-hide");
        
        var searchAction = component.get("c.searchUsers");
        
        searchAction.setParams({
            "searchString" : searchString
        });
        
        searchAction.setCallback(this, function(response){
            //console.log('Users Call = ' + response.state + ' ' + response.getReturnValue().length);
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var userList = response.getReturnValue();
           		//console.log('Users List = ' + userList);
           		console.log('SET USER LIST FROM SEARCH ' + userList.length);
            	component.set("v.uList", userList); 
                var x = document.getElementById("spinner");
                $A.util.addClass(x, "slds-hide");
                
                component.set("v.showNextPrev", false);
            }else {
                helper.processError(component, event, response);
            }
        });
        
       $A.enqueueAction(searchAction);
	},
    
    doClear : function(component, event, helper){
        component.find("searchInput").set("v.value",'');
        component.find("selectManager").set("v.value", 'ALL');
        component.find("selectRole").set("v.value", 'ALL');
        component.set("v.uList", null); 
        component.set("v.showNextPrev",true);
        
        //shows spinner 
        var x = document.getElementById("spinner");
        $A.util.removeClass(x, "slds-hide");
        
        $A.get('e.force:refreshView').fire();
    },
    
    onManagerChange : function(component, event, helper) {
        //Show spinner
        var x = document.getElementById("spinner");
	    $A.util.removeClass(x, "slds-hide");
        
    	var selected = component.find("selectManager").get("v.value");
        if ('ALL' == selected){
            component.set("v.showNextPrev",true);
            helper.getAllPages(component, event);
        }else {
            
        	var searchMgr = component.get("c.searchByManager");
            searchMgr.setParams({
                "mgrName" : selected
            });
            
            searchMgr.setCallback(this, function(response){
                //Show spinner
            	var x = document.getElementById("spinner");
	       	    $A.util.addClass(x, "slds-hide");
                
                if (response.state == 'SUCCESS' && null != response.getReturnValue()){
	                var searchResults = response.getReturnValue();
    	        	component.set("v.uList", searchResults);
                    component.set("v.showNextPrev",false);
                }else {
                    helper.processError(component, event, response);
                }
            });
            $A.enqueueAction(searchMgr);
        }
        
	},
    
    onRoleChange : function(component, event, helper) {
        //Show spinner
        var x = document.getElementById("spinner");
	    $A.util.removeClass(x, "slds-hide");
        
    	var selected = component.find("selectRole").get("v.value");
        if ('ALL' == selected){
			component.set("v.showNextPrev",true);            
            helper.getAllPages(component, event);
        }else {
        	var searchRole = component.get("c.searchByRole");
            searchRole.setParams({
                "roleName" : selected
            });
            
            searchRole.setCallback(this, function(response){
                //Show spinner
            	var x = document.getElementById("spinner");
	       	    $A.util.addClass(x, "slds-hide");
                if (response.state == 'SUCCESS' && null != response.getReturnValue()){
	                var searchResults = response.getReturnValue();
    	        	component.set("v.uList", searchResults);  
                    component.set("v.showNextPrev",false);
                }else {
                	helper.processError(component, event, response);    
                }
            });
            $A.enqueueAction(searchRole);    
        }
        
	},
})