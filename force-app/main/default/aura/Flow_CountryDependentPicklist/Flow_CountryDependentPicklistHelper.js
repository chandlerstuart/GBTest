({
    getAllData : function(component,event,helper) {
        var action = component.get('c.getPicklistData');
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS'){
                //All data (Business Units with Territories)
                var data = response.getReturnValue();
                console.log('data: '+data);
                if(!data) return;
                //Retrieve Default Business Unit and Territory
                var selectedBusinessUnit = component.get("v.businessUnitId");
                var selectedTerritory = component.get("v.territoryId");
                
                //List to store Business Unit Picklist Values
                var buList = [];
                
                //Map to store BusinessUnitIds with their corresponding Territory Data
                var buTerritoryMap = {};
                
                //Loop through Business Units
                for (var i = 0; i < data.length; i += 1) {
                    
                    //Set the initial Business Unit (Default)
                    if((!selectedBusinessUnit || selectedBusinessUnit == null) && data[i].IsDefault__c){
                        selectedBusinessUnit = data[i].Id; //<-- Flow Input BU is the master, then Field Level Default
                        component.set("v.businessUnitId",selectedBusinessUnit);
                    } 
                    if(selectedBusinessUnit != null && selectedBusinessUnit == data[i].Id){
                        data[i].selected = true;
                    }else{
                        data[i].selected = false;
                    }
                    //Store data in a Map
                    buTerritoryMap[data[i].Id] = data[i].Territories__r;
                    
                    buList.push(data[i]);
                }
                //cache data on the page
                component.set("v.buIdsWithTerritories",buTerritoryMap);
                
                this.refreshTerritoryList(component,event,helper,buTerritoryMap);
                
                //Set Business Unit Picklist
                component.set("v.businessUnits", buList);
                
            }else{
                //error loading the CountryDependentPicklist
            }     
        })
        $A.enqueueAction(action);
    },
        
    handleCountrySelection : function(component,event,helper) {
        
    },
    
    //Set the Territory list based on the Business Unit
    refreshTerritoryList : function(component,event,helper,data){
        if(data == null) data = component.get("v.buIdsWithTerritories");
        
        //Retrieve Default Business Unit and Territory
        var selectedBusinessUnit = component.get("v.businessUnitId");
        var selectedTerritory = component.get("v.territoryId");
        
        //Map to store territoryIds with their corresponding Countries
        var tIdsWithCountries = new Map();
        
        //Loop through and set Territory List
        var tList = data[selectedBusinessUnit];
        if(!tList) return;
        console.log("tList:",tList);
        for (var i = 0; i < tList.length; i += 1) {
            
            if((!selectedTerritory || selectedTerritory == null) && tList[i].IsDefault__c){
                selectedTerritory = tList[i].Id; //<-- Flow Input Territory is the master, then Field Level Default
                component.set("v.territoryId",selectedTerritory);
            } 
            if(selectedTerritory != null && selectedTerritory == tList[i].Id){
                tList[i].selected = true;
            }else{
                tList[i].selected = false;
            }
            
            if(tList[i].Countries__c != null){
                var countryList = tList[i].Countries__c.split(";");
                var options = [];
                for(var j = 0; j < countryList.length; j += 1){
                    var option = {};
                    option.value=countryList[j];
                    option.label=countryList[j];
                    options.push(option);
                }
                console.log('tlist: ',tList);
                tIdsWithCountries.set(tList[i].Id,options);
            }
        }
        console.log('country map: ',tIdsWithCountries);
        //Cache data
        component.set("v.tIdsWithCountries",tIdsWithCountries);
        
        //Set Territory Picklist
        component.set("v.territories",tList);
        //Set Countries Picklist
        component.set("v.countries",tIdsWithCountries.get(selectedTerritory));
        
        console.log('TerritoryId: '+component.get("v.territoryId"));
        console.log('BusinessUnitId: '+component.get("v.businessUnitId"));
        console.log('Country: '+component.get("v.selectedCountries"));
        
    },
    
    refreshCountryList : function(component,event,helper){
        var selectedTerritory = component.get("v.territoryId");
        var data = component.get("v.tIdsWithCountries");
        if(selectedTerritory){
            component.set("v.countries", data.get(selectedTerritory));
        }
        console.log('TerritoryId: '+component.get("v.territoryId"));
        console.log('BusinessUnitId: '+component.get("v.businessUnitId"));
        console.log('Country: '+component.get("v.selectedCountries"));
    },
    
    registerValidation : function(component,event,helper){
        component.set('v.validate', function(){
            var countries = component.get("v.selectedCountries");
            if(countries && countries != '' && countries != null){
                return {isValid:true}; 
            } else{
                return {
                    isValid:false,
                    errorMessage: 'You must specify the \'Countries Interested\' to proceed'
                }
            }
        });
    }
    
    
    
})