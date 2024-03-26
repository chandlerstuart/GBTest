({
    onInit : function(component, event, helper) {
        var passedValidation = helper.validateInputParams(component,event,helper);
        //TO DO - Validate Input
        if(passedValidation){
            helper.setDupeRecordCompareFieldString(component,event,helper);
            helper.getData(component,event,helper);
        } 
        
    },
    
    handleNoMatchSelect : function(component,event,helper){
        component.set("v.noMatch", true);
        helper.navigateToNext(component,event,helper);        
    },
    
    handleRecordSelection : function(component,event,helper){
        console.log('Handling Record Selection');
        //Bypass Duplicate Management - no need to run again now the agent has selected the value - 
        //This is a failsafe because the duplicate management SHOULD be bypassed when the Selected Account is explicityly set in the call to the API
        component.set("v.noMatch", true);
        //Get Flow_DupeHandlerController.ObjectWrapper from Event
        var objWrapper = event.getParam("SelectedRecord");
        console.log('objWrapper: '+JSON.stringify(objWrapper));
        var compareFields = objWrapper.compareFields;
        component.set("v.selectedDupeId",objWrapper.recordId);  
        var selectedDupeId = component.get("v.selectedDupeId");
        console.log('FindMe! Dupe Record Id: '+selectedDupeId);
		
        console.log('compareFields: '+JSON.stringify(compareFields));
        var fieldMap = component.get("v.emptyMap");
        for(var i=0;i<compareFields.length;i++){
            fieldMap[compareFields[i].fieldName] = compareFields[i];
        }
                
        //Construct Data for Review
        var fieldComparisonPairs = [];
        
        console.log('Field Map: '+JSON.stringify(fieldMap));
        
        var displayCount=0;
        
        //Get Compare Fields 
        
        var compareEntry = {};
        var compareField1 = component.get("v.compareField1APIName");
        if(compareField1 != null && compareField1 != ''){
            console.log('compareField1: '+compareField1);
            compareEntry.id = 'value1';
            compareEntry.userInputValue = component.get("v.compareField1Value");
            compareEntry.dataType = fieldMap[compareField1].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField1].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField1].fieldLabel;
            compareEntry.isOverwrite = true;
            //Only Add the field if there are conflicts
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField2 = component.get("v.compareField2APIName");
        if(compareField2 != null && compareField2 != ''){
            console.log('compareField2: '+compareField2);
            compareEntry.id = 'value2';
            compareEntry.userInputValue = component.get("v.compareField2Value");
            compareEntry.dataType = fieldMap[compareField2].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField2].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField2].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField3 = component.get("v.compareField3APIName");
        if(compareField3 != null && compareField3 != ''){
            console.log('compareField3: '+compareField3);
            compareEntry.id = 'value3';
            compareEntry.userInputValue = component.get("v.compareField3Value");
            compareEntry.dataType = fieldMap[compareField3].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField3].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField3].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField4 = component.get("v.compareField4APIName");
        if(compareField4 != null && compareField4 != ''){
            console.log('compareField4: '+compareField4);
            compareEntry.id = 'value4';
            compareEntry.userInputValue = component.get("v.compareField4Value");
            compareEntry.dataType = fieldMap[compareField4].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField4].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField4].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField5 = component.get("v.compareField5APIName");
        if(compareField5 != null && compareField5 != ''){
            console.log('compareField5: '+compareField5);
            compareEntry.id = 'value5';
            compareEntry.userInputValue = component.get("v.compareField5Value");
            compareEntry.dataType = fieldMap[compareField5].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField5].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField5].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField6 = component.get("v.compareField6APIName");
        if(compareField6 != null && compareField6 != ''){
            console.log('compareField6: '+compareField6);
            compareEntry.id = 'value6';
            compareEntry.userInputValue = component.get("v.compareField6Value");
            compareEntry.dataType = fieldMap[compareField6].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField6].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField6].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField7 = component.get("v.compareField7APIName");
        if(compareField7 != null && compareField7 != ''){
            console.log('compareField7: '+compareField7);
            compareEntry.id = 'value7';
            compareEntry.userInputValue = component.get("v.compareField7Value");
            compareEntry.dataType = fieldMap[compareField7].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField7].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField7].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField8 = component.get("v.compareField8APIName");
        if(compareField8 != null && compareField8 != ''){
            console.log('compareField8: '+compareField8);
            compareEntry.id = 'value8';
            compareEntry.userInputValue = component.get("v.compareField8Value");
            compareEntry.dataType = fieldMap[compareField8].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField8].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField8].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField9 = component.get("v.compareField9APIName");
        if(compareField9 != null && compareField9 != ''){
            console.log('compareField9: '+compareField9);
            compareEntry.id = 'value9';
            compareEntry.userInputValue = component.get("v.compareField9Value");
            compareEntry.dataType = fieldMap[compareField9].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField9].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField9].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        var compareEntry = {};
        var compareField10 = component.get("v.compareField10APIName");
        if(compareField10 != null && compareField10 != ''){
            console.log('compareField10: '+compareField10);
            compareEntry.id = 'value10';
            compareEntry.userInputValue = component.get("v.compareField10Value");
            compareEntry.dataType = fieldMap[compareField10].fieldType;
            compareEntry.existingRecordValue = fieldMap[compareField10].fieldValue;
            compareEntry.fieldLabel = fieldMap[compareField10].fieldLabel;
            compareEntry.isOverwrite = true;
            if(compareEntry.existingRecordValue && compareEntry.userInputValue && compareEntry.existingRecordValue != compareEntry.userInputValue){
                fieldComparisonPairs.push(compareEntry); 
                displayCount = displayCount+1;
        	}
        }
        
        component.set("v.fieldCompareData",fieldComparisonPairs);
        console.log('fieldCompareData:'+JSON.stringify(fieldComparisonPairs))
        if(displayCount>0){
            component.set("v.showCompare",true);
            component.set("v.showDuplicates",false);
        }else{
            helper.navigateToNext(component,event,helper);  
        }
    },
    
    saveChanges : function(component,event,helper){
        var fieldCompareData = component.get("v.fieldCompareData");  
        for(var i=0;i<fieldCompareData.length;i++){
            if(fieldCompareData[i].id=="value1") component.set("v.compareField1Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
        	if(fieldCompareData[i].id=="value2") component.set("v.compareField2Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value3") component.set("v.compareField3Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value4") component.set("v.compareField4Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value5") component.set("v.compareField5Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value6") component.set("v.compareField6Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
        	if(fieldCompareData[i].id=="value7") component.set("v.compareField7Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value8") component.set("v.compareField8Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value9") component.set("v.compareField9Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
            if(fieldCompareData[i].id=="value10") component.set("v.compareField10Value",(fieldCompareData[i].isOverwrite)?fieldCompareData[i].userInputValue:fieldCompareData[i].existingRecordValue);
        }
        helper.navigateToNext(component,event,helper); 
    }
    
})