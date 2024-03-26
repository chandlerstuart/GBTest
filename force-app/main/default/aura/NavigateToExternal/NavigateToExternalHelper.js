({
    navigateToURL: function(component,url) {

        console.log('navigating to: ' + url);
        var isStandard = component.get("v.isSTandardURL");
        
        if(isStandard){  
            component.find("navigationService").navigate({ 
                type: "standard__webPage", 
                attributes: { 
                    url: url
                } 
            });
            
        }else{
            var e = document.createElement('a');
            e.id = 'test';
            e.href = url;
            document.getElementById("containerDiv").appendChild(e);
            e.click();
            e.parentNode.removeChild(e);
        }
        

        // Lightning Navigation Service via PageReference.
        //component.find("navigationService").navigate({ 
        //    type: "standard__webPage", 
        //    attributes: { 
        //        url: url
        //    }
        //});
                
        // Deprecated approach.
        //var urlEvent = $A.get('e.force:navigateToURL');
        //urlEvent.setParams({
        //    url: url
        //});
        //urlEvent.fire();
    },

    buildURL: function(component, event, helper) {
        var url = '';

        //Capturing Base URL
        var customLabelName = component.get('v.customLabelURL');
        console.log('customLabelName:' + customLabelName);
        if (customLabelName) {
            
            var label = component.get("v.customLabelValue");
            console.log('label type'+typeof label);
            console.log('label:' + label);
            if (!label)
                console.log(
                    'Cannot find custom label called: ' + customLabelName
                );
            url = label;
        } else {
            //Using explicitly specified url (base)
            var explicitURL = component.get('v.explicitURL');
            if (!explicitURL) return;
            url = explicitURL;
        }

        //Appending raw URL to base URL (if specified)
        var rawURL = component.get('v.rawURL');
        if (rawURL) {
            url += rawURL;
        } else {
            console.log('No raw url specified');
        }

        //Appending field value suffix (if specified)
        var fieldAPIName = component.get('v.fieldAPIName');
        var fieldValue = '';
        if (fieldAPIName) {
            var record = component.get('v.record');
            console.log('record: ' + JSON.stringify(record));
            if (!record) console.log('No Record Found!');
            console.log('fieldValue: ' + record[fieldAPIName]);
            fieldValue = record[fieldAPIName];
            if (fieldValue) {
                url += fieldValue;
            }
        } else {
            console.log('No field name specified');
        }
        return url;
    }
});