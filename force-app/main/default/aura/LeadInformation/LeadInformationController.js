({
    doInit : function(component, event, helper) {

	},
    
	proceedLeadConvert : function(component, event, helper) {  
        var id = event.target.id;
        if (id == '') {
            console.log('*** -- NO ID -- ***');        
	        id = component.get("v.leadRecordId");
        }
        console.log("***********proceedLeadConvert Id " + id);        
		var convertLd = component.get("c.convertLead");
        convertLd.setParams({
            leadId : id,
            oppName : component.get("v.oppName")
        });
        
        convertLd.setCallback(this, function(returnVal) {
            var result = returnVal.getReturnValue();
            var state = returnVal.getState();            
            if( result != null && result != "null" && result != ""){
                console.log("proceedLeadConvert result - " + result);
                component.set("v.convertedAcn",result.accName);
                component.set("v.convertedOpp",result.oppName);
                component.set("v.convertedAcnId",result.accId);
                component.set("v.convertedOppId",result.oppId);
                component.set("v.conversionErrors",result.errors);
                console.log("State - " + state);
                console.log("Converted Opp - " + component.get("v.convertedOppId"));
                console.log("Created Date - " + component.get("v.createdDate"));
            } 
            
            if( result == null || component.get("v.convertedOppId") == "" || state === "ERROR"){
                if (result != null){
                    var x = document.getElementById("spinner");
                    $A.util.addClass(x, "slds-hide");
                	var errorMsgCmp = document.getElementById('errorMsg');
                	$A.util.removeClass(errorMsgCmp, "slds-hide");
                }                
            } else{
                var x = document.getElementById("spinner");
        		$A.util.addClass(x, "slds-hide");
                component.set("v.isConverted",true);
                var id = component.get("v.convertedOppId");
                var name = component.get("v.convertedOpp");
                
                sforce.console.getEnclosingPrimaryTabId(
                    function openPrimaryTab(result) {
                    //Now that we have the primary tab ID, we can open a new PrimaryTab in it
                    var primaryTabId = result.id;
                    var newURL = window.location.protocol + "//" + window.location.host + "/";
                    sforce.console.openPrimaryTab(null , newURL+id, true, name, null);
                });

            }
        });
        
       	$A.enqueueAction(convertLd);
	},
    /*setOppName : function(component, event, helper) {
        console.log("setOppName");
        if(event.target.value == ""){
            var defaultOppName = helper.setDefaultOppName(component);
            component.set("v.oppName", defaultOppName);
            document.getElementById("text-input-04").value = defaultOppName;
        }
        else{
            component.set("v.oppName", event.target.value);
        }
    },*/
    selectAccount : function(component, event, helper) {
        var id = event.target.getAttribute("data-id");
        var name = event.target.getAttribute("data-name");
        //First find the ID of the primary tab to put the new subtab in
            sforce.console.getEnclosingPrimaryTabId(
                function openPrimaryTab(result) {
                //Now that we have the primary tab ID, we can open a new subtab in it
                var primaryTabId = result.id;
                var newURL = window.location.protocol + "//" + window.location.host + "/";
                sforce.console.openPrimaryTab(null , newURL+id, true, name, null);
            });
    },
    closeErrorMessage : function(component, event, helper) {
    	//Hides
        var errorMsgCmp = document.getElementById('errorMsg');
        $A.util.addClass(errorMsgCmp, "slds-hide");
        
        var leadDetailCmp = document.getElementById('convertGrid');
        $A.util.removeClass(leadDetailCmp, "slds-hide");
	}
})