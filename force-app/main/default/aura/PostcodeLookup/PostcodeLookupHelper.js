({
    startSearch : function(component, event, helper) {
        console.log("Starting Search");
        var searchString = component.get("v.searchString");
        var apiKey = $A.get('$Label.c.LoqateAPIKey');
        if(!apiKey) return;
        if(!searchString) return;
        var url = 'https://services.postcodeanywhere.co.uk/Capture/Interactive/Find/v1.10/json3.ws';
        var params = '';
        params += "&Key=" + apiKey;
        params += "&Text=" + searchString;
        params += "&IsMiddleware=" + false;
        params += "&Container=" + component.get("v.selectedResultId");
        params += "&Origin=" + '';
        params += "&Countries=" + '';
        params += "&Limit=" + 30;
        params += "&Language=" + 'en-gb';
        var http = new XMLHttpRequest();
        http.open('POST', url, true);
        http.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
        console.log('params: '+params);
        http.onreadystatechange = function() {
            if(http.readyState == 4 && http.status == 200) {
                var response = JSON.parse(http.responseText);
                // Test for an error
                if (response.Items.length == 1 && typeof(response.Items[0].Error) != "undefined") {
                    // Show the error message
                    alert(response.Items[0].Description);
                }
                else {
                    // Check if there were any items found
                    if (response.Items.length == 0){
                        alert("Sorry, there were no results");
                        console.log("No Results Response: "+JSON.stringify(response));
                    }
                    
                    else {
                        // PUT YOUR CODE HERE
                        console.log('response: '+JSON.stringify(response));
                        //FYI: The output is an array of key value pairs (e.g. response.Items[0].Id), the keys being:
                        //Id
                        //Type
                        //Text
                        //Highlight
                        //Description
                        component.set("v.results",response.Items);
                    }
                }
            }
        }
        http.send(params);
    },
    
    retrieveAddress : function(component,event,helper){
        var apiKey = $A.get('$Label.c.LoqateAPIKey');
        if(!apiKey) return;
        var url = 'https://services.postcodeanywhere.co.uk/Capture/Interactive/Retrieve/v1.00/json3.ws';
        var params = '';
        params += "&Key=" + apiKey;
        params += "&Id=" + component.get("v.selectedResultId");
       /* params += "&Field1Format=" + '';
        params += "&Field2Format=" + '';
        params += "&Field3Format=" + '';
        params += "&Field4Format=" + encodeURIComponent(Field4Format);
        params += "&Field5Format=" + encodeURIComponent(Field5Format);
        params += "&Field6Format=" + encodeURIComponent(Field6Format);
        params += "&Field7Format=" + encodeURIComponent(Field7Format);
        params += "&Field8Format=" + encodeURIComponent(Field8Format);
        params += "&Field9Format=" + encodeURIComponent(Field9Format);
        params += "&Field10Format=" + encodeURIComponent(Field10Format);
        params += "&Field11Format=" + encodeURIComponent(Field11Format);
        params += "&Field12Format=" + encodeURIComponent(Field12Format);
        params += "&Field13Format=" + encodeURIComponent(Field13Format);
        params += "&Field14Format=" + encodeURIComponent(Field14Format);
        params += "&Field15Format=" + encodeURIComponent(Field15Format);
        params += "&Field16Format=" + encodeURIComponent(Field16Format);
        params += "&Field17Format=" + encodeURIComponent(Field17Format);
        params += "&Field18Format=" + encodeURIComponent(Field18Format);
        params += "&Field19Format=" + encodeURIComponent(Field19Format);
        params += "&Field20Format=" + encodeURIComponent(Field20Format);*/
        var http = new XMLHttpRequest();
        http.open('POST', url, true);
        http.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
        http.onreadystatechange = function() {
            if(http.readyState == 4 && http.status == 200) {
                var response = JSON.parse(http.responseText);
                // Test for an error
                if (response.Items.length == 1 && typeof(response.Items[0].Error) != "undefined") {
                    // Show the error message
                    alert(response.Items[0].Description);
                }
                else {
                    // Check if there were any items found
                    if (response.Items.length == 0)
                        alert("Sorry, there were no results");
                    else {
                        console.log("Address Selection Response: ",response.Items);

                        if(!response) return;
                        var acc = component.get("v.account");
                        if(acc){
                            
                            //Clearing current address
                            acc.PersonMailingStreet = '';
                            acc.PersonMailingCity = '';
							acc.PersonMailingCountry = '';
							acc.Mailing_State_County__pc = '';                            
                            acc.PersonMailingPostalCode = '';
                            
                            //Build Street String
                            var streetString = response.Items[0].Line1;
                            if(response.Items[0].Line2) streetString += ', \n'+response.Items[0].Line2;
                            if(response.Items[0].Line3) streetString += ', \n'+response.Items[0].Line3;
                            if(response.Items[0].Line4) streetString += ', \n'+response.Items[0].Line4;
                            if(response.Items[0].Line5) streetString += ', \n'+response.Items[0].Line5;
                            
                            //Map response to account values
                            acc.PersonMailingStreet = streetString;
                            acc.PersonMailingCity = response.Items[0].City;
                            acc.PersonMailingCountry = response.Items[0].CountryName;
                            acc.Mailing_State_County__pc = response.Items[0].Province;
                            acc.PersonMailingPostalCode = response.Items[0].PostalCode;
                            component.set("v.account",acc);
                            component.set("v.showModal",false);
                            
                            //Refresh preference panel (colours)
                            var event = component.getEvent("changeEvent");
                            event.setParams({
                                "revisePanelValidation" : true
                            })
                            event.fire();
                        }        
                    }
                }
            }
        }
        http.send(params);
    },
    
})