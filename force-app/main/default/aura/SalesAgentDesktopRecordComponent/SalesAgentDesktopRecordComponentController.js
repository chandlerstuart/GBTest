({  
    setHigh : function(component, event, helper){
        var recId = component.get("v.recId");
        var highFunction = component.get("c.setHighPriority");
        highFunction.setParams({
            "oppId" : recId
        });
        
        highFunction.setCallback(this, function(response){
        	var changeEvent = component.getEvent("oppUpdateEvent");    
            changeEvent.fire();
        });
        
        $A.enqueueAction(highFunction);
    },
    
    openRecord : function(component, event, helper){
        var recId = component.get("v.recId"); 
        sforce.console.openPrimaryTab(null,'/' + recId,true);
    },
    
    openAccountRecord : function(component, event, helper){
        var accRecId = component.get("v.accountRecId"); 
        sforce.console.openPrimaryTab(null,'/' + accRecId,true);
    },
    
    openClubhouseEnquiry : function(component, event, helper){
    	var gbEnqId = component.get("v.gbEnquiryId");
        var baseURL = $A.get("$Label.c.ClubhouseBaseURL");
        var urlParams = 'enquiry?id=';
        var fullURL = baseURL + urlParams + gbEnqId;
		var win = window.open(fullURL, '_blank');
    },
})