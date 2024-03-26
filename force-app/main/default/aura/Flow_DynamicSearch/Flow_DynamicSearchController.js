({	
    onInit : function(component,event,helper){
        helper.registerValidation(component,event,helper);
    },
    
    search : function(component,event,helper){
        var isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            var queryTerm = component.get("v.searchString");
            if(queryTerm.length<2) return;//Term must be longer than 1 character
            component.set("v.recordId",null);
            component.set("v.showPrompt",false);
            var getLabels = component.get("v.getLabels");
            component.set("v.searchString",queryTerm);
            component.set('v.issearching', true);
            setTimeout(function() {
                component.set('v.issearching', false);
            }, 2000);
            helper.getData(component,event,helper,getLabels);
        }
    },
    
    handleRowSelection : function(component,event,helper){
        console.log('row selected');
        var recId = event.getParam('row').Id;
        console.log(JSON.stringify(event.getParam('row')));
        console.log('rec Id:'+ recId);
        component.set("v.recordId",recId);
        component.set("v.showModal",false);
        component.set("v.searchAttempted", false);
    },
    
    clear : function(component,event,helper){
        component.set("v.recordId",null);
    },
    
    handleChange : function(component,event,helper){
        var searchString = component.get("v.searchString");
        if(searchString && searchString.length>2){
            component.set("v.showPrompt",true);
        }
    },
    
    toggleModal : function(component,event,helper){
        var show = component.get("v.showModal");
        if(!show == false){
            component.set("v.searchAttempted", false);
        }
        component.set("v.showModal",!show);
    }
    
    
    
})