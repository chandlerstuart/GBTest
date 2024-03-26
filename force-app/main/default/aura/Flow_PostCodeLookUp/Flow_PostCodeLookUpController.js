({
    onInit: function(component,event,helper){
        console.log('address: '+component.get("v.postCode"));
    },
    
    startSearch : function(component,event,helper){
        component.set("v.selectedResultId",null);
        helper.startSearch(component,event,helper);
    },
    
    handleSelection : function(component,event,helper){
        
        console.log('Handling Selection')
        var params = event.getParams();
        console.log('params: '+JSON.stringify(params));
        if(params && params.id && params.type && params.type != 'Address'){
            component.set("v.selectedResultId",params.id);
            helper.startSearch(component,event,helper);
        }else if(params && params.id && params.type && params.type == 'Address'){
            component.set("v.selectedResultId",params.id);
            helper.retrieveAddress(component,event,helper);
        }        
    },
    
    toggleEdit : function(component,event,helper){
        var isEdit = component.get("v.editMode");
        component.set("v.editMode",!isEdit);
    },
    
    clearAll : function(component,event,helper){
        component.set("v.street",null);
        component.set("v.county",null);
        component.set("v.city",null);
        component.set("v.country",null);
        component.set("v.postCode",null);
    },
    
    toggleModal : function(component,event,helper){
       	var show = component.get("v.showModal");
        component.set("v.showModal",!show);
    }
})