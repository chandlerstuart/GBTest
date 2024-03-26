({
    addPadding : function(component,event,helper) {
        var container = component.find("container");
        console.log('container: '+container);
        var padding = component.get("v.padding").toUpperCase();
        var className;
        if(container){
            switch(padding){
                case 'X-SMALL':
                    className = 'slds-p-around_x-small';
                    break;
                case 'SMALL':
                    className = 'slds-p-around_small';
                    break;
                case 'MEDIUM':
                    className = 'slds-p-around_medium';
                    break;
                case 'LARGE':
                    className = 'slds-p-around_large';
                    break;
                case 'X-LARGE':
                    className = 'slds-p-around_x-large';
                    break;
                case 'XX-LARGE':
                    className = 'slds-p-around_xx-large';
                    break;
            }
            if(className){
                $A.util.addClass(container, className);
            }
        }
    }
})