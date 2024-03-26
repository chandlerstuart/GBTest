({
    loadButtons : function(component, event, helper) {
        
        console.log(component.get("v.buttons"));
        
        var componentDetails = [];
        var button1 = component.get("v.button1Label");
        var button2 = component.get("v.button2Label");
        var button3 = component.get("v.button3Label");
        
        if(button1){
            var button1Details = ["lightning:button",{
                "label" : button1,
                "aura:id" : 'button1',
                "class" : 'slds-p-horizontal_small',
                "onclick" : component.getReference("c.handleChange"),
                "variant" : component.get("v.button1Style")
            }];
            componentDetails.push(button1Details);
        }
        if(button2){
            var button1Details = ["lightning:button",{
                "label" : button2,
                "aura:id" : 'button2',
                "class" : 'slds-p-horizontal_small',
                "onclick" : component.getReference("c.handleChange"),
                "variant" : component.get("v.button2Style")
            }];
            componentDetails.push(button1Details);
        }
        if(button3){
            var button1Details = ["lightning:button",{
                "label" : button3,
                "aura:id" : 'button3',
                "class" : 'slds-p-horizontal_small',
                "onclick" : component.getReference("c.handleChange"),
                "variant" : component.get("v.button3Style")
            }];
            componentDetails.push(button1Details);
        }       
        
        $A.createComponents(componentDetails,
                            function(components, status, errorMessage){
                                if (status === "SUCCESS") {
                                    console.log('components: ',components);
                                    var body = component.get("v.buttons");  
                                    components.forEach(function(item){
                                        body.push(item);
                                    });
                                    component.set("v.buttons", body);
                                }
                                else if (status === "INCOMPLETE") {
                                    console.log("No response from server or client is offline.")
                                }
                                    else if (status === "ERROR") {
                                        console.log("Error: " + errorMessage);
                                    }
                            }
                           );
    },
    
    addStyle : function(component,event,helper){
        var buttonSection = component.find("buttonDiv");
        console.log('buttonSection: '+buttonSection);
        var position = component.get("v.position").toUpperCase();
        var className;
        if(buttonSection){
            switch(position){
                case 'LEFT':
                    className = 'slds-float_left';
                    break;
                case 'RIGHT':
                    className = 'slds-float_right';
                    break;
                case 'CENTRE':
                    className = 'slds-align_absolute-center';
                    break;
                case 'CENTER':
                    className = 'slds-align_absolute-center';
                    break;
            }
            if(className){
                $A.util.addClass(buttonSection, className);
            }
        }
        
    }
})