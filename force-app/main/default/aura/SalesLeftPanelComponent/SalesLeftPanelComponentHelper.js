({
	getReport : function(component, methodName, variablename) {
	var action = component.get("c." + methodName);    
    action.setCallback(this, function(a){
   	    component.set("v." + variablename, a.getReturnValue()); 
       });
      $A.enqueueAction(action);
	}   
})