({
    getData : function(component,event,helper) {
        var action = component.get("c.getRecordData");
        var displayFieldsList = this.processFieldString(component,event,helper,"v.dupeRecordCardFields");
        var compareFieldsList = this.processFieldString(component,event,helper,"v.dupeRecordCompareFields");
        var idList = this.processIdString(component,event,helper);
        action.setParams({
            sObjectType: component.get("v.dupeRecordSObjectType"),
            displayFields: displayFieldsList,
            compareFields: compareFieldsList,
            nameField: component.get("v.dupeRecordObjectNameField"),
            recordIds: idList
            
        }); 
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS'){
                component.set("v.showDuplicates", true);
                this.disableNoMatch(component,response.getReturnValue());
                component.set("v.duplicateRecords", response.getReturnValue());
            }else{
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                component.set("v.errorMessage",message);
            }     
        });
        $A.enqueueAction(action);
    },
    
    processFieldString : function(component,event,helper,stringField){
        var fieldString = component.get(stringField);
        var fieldList = [];
        if(fieldString && fieldString.includes(',')){
            fieldList = fieldString.split(',');
        }else{
            fieldList.push(fieldString);
        }
        return fieldList;
    },
    
    processIdString : function(component,event,helper){
        var idString = component.get("v.dupeRecordIds");
        var idList = [];
        if(idString && idString.includes(',')){
            idList = idString.split(',');
        }else{
            idList.push(idString);
        }
        return idList;
    },
    
    validateInputParams : function(component,event,helper){
        var errorMessage = '';
        var objType = component.get("v.dupeRecordSObjectType");
        var recIds = component.get("v.dupeRecordIds");
        var fields = component.get("v.dupeRecordCardFields");
        var nameField = component.get("v.dupeRecordObjectNameField");
        if(!objType || objType == null || objType == '') errorMessage = 'Please specify an sObjectType';
        if(!recIds || recIds == null || recIds == '') errorMessage = 'Please specify the Duplicate Record Ids';
        if(!fields || fields == null || fields == '') errorMessage = 'Please specify the Duplicate Fields to Display Ids';
        if(!nameField || nameField == null || nameField == '') errorMessage = 'Please specify the SObjects Name Field i.e. CaseNumber (Case) or Name (Account)';
        if(errorMessage && errorMessage != ''){
            component.set("v.errorMessage",errorMessage);
            return false;
        }
        return true;
        
    },
    
    setDupeRecordCompareFieldString : function(component,event,helper){
        var field1 = component.get("v.compareField1APIName");
        var field2 = component.get("v.compareField2APIName");
        var field3 = component.get("v.compareField3APIName");
        var field4 = component.get("v.compareField4APIName");
        var field5 = component.get("v.compareField5APIName");
        var field6 = component.get("v.compareField6APIName");
        var field7 = component.get("v.compareField7APIName");
        var field8 = component.get("v.compareField8APIName");
        var field9 = component.get("v.compareField9APIName");
        var field10 = component.get("v.compareField10APIName");
        
        var fieldString ='';
        if(field1) fieldString = fieldString+field1+',';
        if(field2) fieldString = fieldString+field2+',';
        if(field3) fieldString = fieldString+field3+',';
        if(field4) fieldString = fieldString+field4+',';
        if(field5) fieldString = fieldString+field5+',';
        if(field6) fieldString = fieldString+field6+',';
        if(field7) fieldString = fieldString+field7+',';
        if(field8) fieldString = fieldString+field8+',';
        if(field9) fieldString = fieldString+field9+',';
        if(field10) fieldString = fieldString+field10+',';
        
        //Remove the final ','
        var fieldStringFinal = fieldString.substring(0, fieldString.length - 1);
        
        component.set("v.dupeRecordCompareFields",fieldString);    
    },
    
    navigateToNext : function(component,event,helper){
        var availableActions = component.get('v.availableActions');
        var canNext = false;
        var canFinish = false;
        for (var i = 0; i < availableActions.length; i++) {
            if (availableActions[i] == "NEXT") {
                canNext = true;
            } else if (availableActions[i] == "FINISH") {
                canFinish = true;
            }
        }
        var navigate = component.get("v.navigateFlow");
        if(canNext){
            navigate("NEXT");
        }else if(canFinish){
            navigate("FINISH");
        }
    },
    
    //Disable No Match
    disableNoMatch : function(component,wrapperList){
        if(!wrapperList || wrapperList.length == 0) return;
        var comp1 = component.get("v.compareField1APIName");
        var comp2 = component.get("v.compareField2APIName");
        var comp3 = component.get("v.compareField3APIName");
        var comp4 = component.get("v.compareField4APIName");
        var comp5 = component.get("v.compareField5APIName");
        var comp6 = component.get("v.compareField6APIName");
        var comp7 = component.get("v.compareField7APIName");
        var comp8 = component.get("v.compareField8APIName");
        var comp9 = component.get("v.compareField9APIName");
        var comp10 = component.get("v.compareField10APIName");
        var emailAddress = '';
        if(comp1 == 'PersonEmail'){
            emailAddress = component.get("v.compareField1Value");
        }else if(comp2 == 'PersonEmail'){
            emailAddress = component.get("v.compareField2Value");
        }else if(comp3 == 'PersonEmail'){
            emailAddress = component.get("v.compareField3Value");
        }else if(comp4 == 'PersonEmail'){
            emailAddress = component.get("v.compareField4Value");
        }else if(comp5 == 'PersonEmail'){
            emailAddress = component.get("v.compareField5Value");
        }else if(comp6 == 'PersonEmail'){
            emailAddress = component.get("v.compareField6Value");
        }else if(comp7 == 'PersonEmail'){
            emailAddress = component.get("v.compareField7Value");
        }else if(comp8 == 'PersonEmail'){
            emailAddress = component.get("v.compareField8Value");
        }else if(comp9 == 'PersonEmail'){
            emailAddress = component.get("v.compareField9Value");
        }else if(comp10 == 'PersonEmail'){
            emailAddress = component.get("v.compareField10Value");
        }else{
            return;
        }
        //Loop through duplicates
        for(let i=0; i<wrapperList.length;i++){
            //Loop through compare fields
            if(wrapperList[i].compareFields && wrapperList[i].compareFields.length>0){
                for(let j=0; j<wrapperList[i].compareFields.length;j++){
                    
                    if(wrapperList[i].compareFields[j].fieldName == 'PersonEmail' && wrapperList[i].compareFields[j].fieldValue != null 
                       && wrapperList[i].compareFields[j].fieldValue != '' && wrapperList[i].compareFields[j].fieldValue == emailAddress ){
                        //If the Person Email has been featured and it matches the user input the disable the create button
                        component.set("v.disableNoMatchButton",true);
                    } 
                }
            }
        }
    }
})