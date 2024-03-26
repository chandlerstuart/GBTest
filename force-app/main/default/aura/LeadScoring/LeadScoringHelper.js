({
    saveRule : function(component, event) {
		var selectedObj = component.find("objectBox").get("v.value");
        var leadScoringRule = component.get("v.leadScoringRule");        
        leadScoringRule.Name = component.find("ruleNameBox").get("v.value");
        leadScoringRule.Active__c = component.find("activeCheckbox").get("v.value");
        leadScoringRule.RecordType__c = component.find("recordTypeBox").get("v.value");
        leadScoringRule.FieldLabel__c = component.find("fieldBox").get("v.value");
        leadScoringRule.Operator__c = component.find("operatorBox").get("v.value");
        leadScoringRule.Value__c = component.find("valueBox").get("v.value");
        leadScoringRule.Points__c = component.find("pointBox").get("v.value");
        leadScoringRule.MinimumValue__c = component.find("minValueBox").get("v.value");
        leadScoringRule.MaximumValue__c = component.find("maxValueBox").get("v.value");
        
        var saveLeadScoringRule;
        if(!component.get("v.isCreate") && component.get("v.selectedRule")){
           leadScoringRule.Id = component.get("v.selectedRule").Id;
           leadScoringRule.RecordTypeId = component.get("v.selectedRule").RecordTypeId;
           saveLeadScoringRule = component.get("c.updateScoringRule");
           saveLeadScoringRule.setParams({ "lsrObject" : leadScoringRule});
        }
        else{
            leadScoringRule.Id = null;
        	saveLeadScoringRule = component.get("c.saveScoringRule");
            saveLeadScoringRule.setParams({ "lsrObject" : leadScoringRule, "ruleType": selectedObj});
        }
    
        if(saveLeadScoringRule){
            saveLeadScoringRule.setCallback(this, function(response) {
                var state = response.getState();
                var responseData = response.getReturnValue();
                if (state === "SUCCESS") {
                    this.getLeadScoringRules(component, selectedObj);
                }
                
                this.handleResponseMessage(component, responseData, true);
            });
    
            $A.enqueueAction(saveLeadScoringRule);
        }
	},
    
	getLeadScoringRules : function(component, selectedObj) {
        if(selectedObj != null && selectedObj != '' && selectedObj != '-'){
            var getScoringRules = component.get("c.getLeadScoringRules");
            getScoringRules.setParams({ "objName" : selectedObj});
            getScoringRules.setCallback(this, function(response) {
                var state = response.getState();
                var responseData = response.getReturnValue();
                if (state === "SUCCESS") {
                    this.setDataFromResponse(component,"v.leadScoringRules",responseData.returnObj);
                }
                
                this.handleResponseMessage(component, responseData, false);
            });
    
            $A.enqueueAction(getScoringRules);
        }
	},
    
    validateRequired : function(fieldObject) {
        var isValid = true;
        var fieldValue = fieldObject.get("v.value");
        if($A.util.isUndefined(fieldValue) || $A.util.isEmpty(fieldValue)){
            fieldObject.set("v.errors", [{message:"This is a required field."}]);
            isValid = false;
        }
        
        return isValid;
    },
    
    validateNumber : function(fieldObject) {
        var isValid = true;
        var fieldValue = fieldObject.get("v.value");
        isValid = this.validateRequired(fieldObject);
        if(isValid && isNaN(fieldValue)){
            fieldObject.set("v.errors", [{message:"Please Enter a Number."}]);
            isValid = false;
        }
        
        return isValid;
    },
    
    validateRange : function(minFieldObject, maxFieldObject) {
        var isValid = true;
        var minFieldValue = minFieldObject.get("v.value");
    	var maxFieldValue = maxFieldObject.get("v.value");
        var minValid = this.validateRequired(minFieldObject);
        var maxValid = this.validateRequired(maxFieldObject);
        
        
        if(minValid || maxValid){
            if(minValid){
                if(!maxValid){
                    this.removeErrors(maxFieldObject);
                }
                if(isNaN(minFieldValue)){
                	minFieldObject.set("v.errors", [{message:"Please enter a number."}]);
                    isValid = false;
            	}
			}
            if(maxValid){
                if(!minValid){
                    this.removeErrors(minFieldObject);
                }
                if(isNaN(maxFieldValue)){
                	maxFieldObject.set("v.errors", [{message:"Please enter a number."}]);
                    isValid = false;
            	}
            }
            if(isValid && minValid && maxValid && Number(minFieldValue) > Number(maxFieldValue)){
                minFieldObject.set("v.errors", [{message:"Minimum Value must be lesser than the maximum value"}]);
                isValid = false;
            }
            
        }
        else{
            this.removeErrors(minFieldObject);
            minFieldObject.set("v.errors", [{message:"Either minimum and maximum must have a value."}]);
            this.removeErrors(maxFieldObject);
            isValid = false;
        }
        
        return isValid;
    },
    
    setDataFromResponse : function(component,cmpVar,data) {
        component.set(cmpVar,data);
    },
    
    handleResponseMessage : function(component, responseData, isPromptSuccess) {
        if(isPromptSuccess && responseData.statusCode == 200){
        	this.handleMessages(component, "info", responseData.message);
        }
        else if(responseData.statusCode == 400){
        	this.handleMessages(component, "error", responseData.message);
        }
    },
    
    handleMessages : function(component, type, message) {
        if(type === "error"){
            component.set("v.errorMsg", message);
        }
        else if(type === "info"){
            component.set("v.infoMsg", message);
        }
    },
    
    removeErrors : function(fieldObject) {
        fieldObject.set("v.errors", null);
    },
    
    removeServerSideErrors : function(component) {
    	component.set("v.infoMsg", "");
        component.set("v.errorMsg", "");
    },
    
    clearFields : function(fields) {
        var index;
        for(index in fields){
        	fields[index].set("v.value", "");   
        }
    }
})