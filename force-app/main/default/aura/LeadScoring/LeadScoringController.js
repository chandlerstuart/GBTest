({
	onInit : function(component, event, helper) {
        component.set("v.recordSelected",'');
        helper.removeServerSideErrors(component);
        var selectedObj = component.find("objectBox").get("v.value");
        var getFields = component.get("c.getfieldInformation");
        getFields.setParams({ "objName" : selectedObj});
        getFields.setCallback(this, function(response) {
            var state = response.getState();
            var responseData = response.getReturnValue();
            if (state === "SUCCESS") {
                console.log(responseData);
                component.set("v.fields",responseData.returnObj);
                component.set("v.fieldSelected",responseData.returnObj[0]);
            }
            
            helper.handleResponseMessage(component, responseData, false);
        });

		$A.enqueueAction(getFields);
        
        var getRecordTypes = component.get("c.getRecordTypeInformation");
        getRecordTypes.setParams({ "objName" : selectedObj});
        getRecordTypes.setCallback(this, function(response) {
            var responseData = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.recordTypes", responseData.returnObj);
                if(responseData.returnObj && responseData.returnObj.length > 0){
                	component.set("v.recordSelected", responseData.returnObj[0]);
                }
            }
            
            helper.handleResponseMessage(component, responseData, false);
        });

        $A.enqueueAction(getRecordTypes);
        
        helper.getLeadScoringRules(component, selectedObj);
	},
    
    handleSave : function(component, event, helper) {
        helper.removeServerSideErrors(component);
        var Name = component.find("ruleNameBox");
        var Value = component.find("valueBox");
        var Points = component.find("pointBox");
        var minValue = component.find("minValueBox");
        var maxValue = component.find("maxValueBox");
        var recType = component.find("recordTypeBox");
        helper.removeErrors(Name);
        helper.removeErrors(Value);
        helper.removeErrors(Points);
        helper.removeErrors(minValue);
        helper.removeErrors(maxValue);
        helper.removeErrors(recType);
        
        var isValid = true;
        
        if(component.get("v.operator") == 'less than/greater than'){
            Value.set("v.value", "");
            isValid = helper.validateRange(minValue, maxValue);
        }
        else{
            minValue.set("v.value", "");
            maxValue.set("v.value", "");
            isValid = helper.validateRequired(Value);
        }
        
        if(!helper.validateRequired(recType)){
           	isValid = false;	
        }
          
        if(!helper.validateRequired(Name)){
           	isValid = false;	
        }
        
        if(!helper.validateNumber(Points)){
            isValid = false;
        }
        
        if(isValid){
            helper.saveRule(component, event);
        }
	},
    
    delete: function(component, event, helper) {
    	helper.removeServerSideErrors(component);
        //Get data via "data-data" attribute from button (button itself or icon's parentNode)
        var selectedObj = component.find("objectBox").get("v.value");
        var id = (event.target.getAttribute("data-data") || event.target.parentNode.getAttribute("data-data"));
    
        if(!id){
        	helper.handleMessages(component, "error", "Parameter error occurred. Please try again later.");
    	}
        else{
        	var deleteLeadScoringRule = component.get("c.deleteLeadScoringRules");
            deleteLeadScoringRule.setParams({ "lsrId" : id});
            deleteLeadScoringRule.setCallback(this, function(response) {
                var state = response.getState();
                var responseData = response.getReturnValue();
                if (state === "SUCCESS") {
                    helper.getLeadScoringRules(component, selectedObj);
                }
                
                helper.handleResponseMessage(component, responseData, true);
            });
    
            $A.enqueueAction(deleteLeadScoringRule);
        }
   },
       
	update : function(component, event, helper) {
       helper.removeServerSideErrors(component);
       var id = (event.target.getAttribute("data-data") || event.target.parentNode.getAttribute("data-data"));
       if(!id){
        	helper.handleMessages(component, "error", "Parameter error occurred. Please try again later.");
       }
       else{
       		component.set("v.isCreate", false);
            var rules = component.get("v.leadScoringRules");
            var index;
            var rule;
            for(index in rules){
                if(rules[index].Id == id){
                    rule = rules[index];
                    break;
                }  
            }
           
            component.set("v.selectedRule", rule);
            component.find("ruleNameBox").set("v.value", rule.Name);
            component.find("recordTypeBox").set("v.value", rule.RecordType__c);
            component.find("activeCheckbox").set("v.value", rule.Active__c);
            component.find("fieldBox").set("v.value", rule.FieldLabel__c);
            component.find("operatorBox").set("v.value", rule.Operator__c);
			component.find("valueBox").set("v.value", rule.Value__c);
            component.find("pointBox").set("v.value", rule.Points__c);
            component.find("minValueBox").set("v.value", rule.MinimumValue__c);
            component.find("maxValueBox").set("v.value", rule.MaximumValue__c);
       }
        
        
	},
   
	cancelEdit : function(component, event, helper) {
       helper.removeServerSideErrors(component);
       component.set("v.selectedRule", null);
       component.set("v.isCreate", true);
       component.find("activeCheckbox").set("v.value", false);
        
       var Name = component.find("ruleNameBox");
       var Value = component.find("valueBox");
       var Points = component.find("pointBox");
       var minValue = component.find("minValueBox");
       var maxValue = component.find("maxValueBox");
       var recType = component.find("recordTypeBox");
        
       var fields = new Array();
       fields.push(Name);
       fields.push(Value);
       fields.push(Points);
       fields.push(minValue);
       fields.push(maxValue);
       helper.clearFields(fields);
       
       helper.removeErrors(Name);
       helper.removeErrors(Value);
       helper.removeErrors(Points);
       helper.removeErrors(minValue);
       helper.removeErrors(maxValue);
       helper.removeErrors(recType);
	}
})