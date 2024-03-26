({
	getReport : function(component, methodName, variablename) {
	var action = component.get("c." + methodName);
    
    action.setCallback(this, function(a){
       component.set("v." + variablename, a.getReturnValue());
       	console.log(component.get("v." + variablename));
       });
      $A.enqueueAction(action);
	}    
})