({
	onInit : function(component, event, helper) {
		var loadRec = component.get("c.getLeadRecord");
        //var currentUrl = window.location.href;
        var leadIdFromUrl = component.get("v.vfleadId");   
        
        //if(leadIdFromUrl){			
            loadRec.setParams({
                leadId : leadIdFromUrl
            });
            loadRec.setCallback(this, function(response){
                if(response.state == 'SUCCESS') {
                    component.set("v.leadRecord", response.getReturnValue());
                } else {
                    //show error message
                }                
            });
        var formatCDate = component.get("c.getCreatedDate");
        //var currentUrl = window.location.href;
        var leadIdFromUrl = component.get("v.vfleadId");        
        //if(leadIdFromUrl){			
            formatCDate.setParams({
                leadId : leadIdFromUrl
            });
            formatCDate.setCallback(this, function(response){
                if(response.state == 'SUCCESS') {
                    component.set("v.createdDate", response.getReturnValue());
                } else {
                    //show error message
                }                
            });
        
        	$A.enqueueAction(formatCDate);
            $A.enqueueAction(loadRec);  
        //}
        //else{
            
        //}
	}
})