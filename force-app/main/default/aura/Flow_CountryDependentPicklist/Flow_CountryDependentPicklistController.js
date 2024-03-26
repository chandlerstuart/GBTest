({
    onInit : function(component, event, helper) {
        helper.getAllData(component,event,helper);  
        helper.registerValidation(component,event,helper);
    },
            
    handleCountrySelection : function(component,event,helper){
        helper.handleCountrySelection(component,event,helper);
    },
    
    handleBusinessUnitSelection : function(component,event,helper) {
        //Clear the selected territory
        component.set("v.territoryId",null);
        //Refresh the Territory Picklist
        helper.refreshTerritoryList(component,event,helper);
    },
    
    handleTerritorySelection : function(component,event,helper) {
        //Clear the selected territory
        component.set("v.chosenCountries",null);
        component.set("v.selectedCountries",null);
        //Refresh the Territory Picklist
        helper.refreshCountryList(component,event,helper);
    },
    
    handleCountrySelection : function(component,event,helper) {
        /*var countries = component.get("v.chosenCountries");
        var countryString = '';
        for(var i = 0; i < countries.length; i += 1){
			countryString = countryString+countries[i]+';';            
        }
        component.set("v.selectedCountries", countryString);*/
        console.log('TerritoryId: '+component.get("v.territoryId"));
        console.log('BusinessUnitId: '+component.get("v.businessUnitId"));
        console.log('Country: '+component.get("v.selectedCountries"));
    }
    
})