({
    onInit: function(component, event, helper) {
        console.log(
            'on Init record: ' + JSON.stringify(component.get('v.record'))
        );
        
        //Adding specified field to array variable
        var fieldName = component.get('v.fieldAPIName');
        console.log('fieldName: ' + fieldName);
        if(fieldName){
            component.set('v.fieldNameList', fieldName);
        }
        
        //Validating config before displaying the buttons
        var showButton = true;
        //At least one base url must be specified
        var customLabel = component.get('v.customLabelURL');
        var expURL = component.get('v.explicitURL');
        if (!customLabel && !expURL) {
            showButton = false;
            console.log('Button Hidden - Either a custom label or explicity must be specified');
        }
        //The field must exist on the object (not traverse to the parent object)
        if(fieldName && fieldName.includes('.')){
            showButton = false;
            console.log('Button Hidden - The field specified cannot be a parent field');            
        }
        
        if(customLabel){
            var labelString = '$Label.c.' + customLabel;
            console.log('label string: ' + labelString);
            var labelReference;
            labelReference = $A.getReference(labelString);
            console.log('label reference type'+typeof labelReference);
            component.set("v.customLabelValue",labelReference);//Convert reference to string by setting it in attribute
        }
        
        component.set('v.showButton', showButton);
    },
    
    recordLoaded: function(component, event, helper) {
        console.log('record loaded start');
        
        console.log('record: ' + JSON.stringify(component.get('v.record')));
        
        console.log('record loaded stop');
    },
    
    navigateToURL: function(component, event, helper) {
        var url = helper.buildURL(component, event, helper);
        console.log('Final URL: ' + url);
        if (url) {
            helper.navigateToURL(component,url);
        } else {
            console.log('Invalid URL: ' + url);
        }
    },
    
    reloadRecord: function(component, event, helper) {
        if(event.getParam('oldValue') == event.getParam('value')) return;
        component.find('recordData').reloadRecord();
    }
});