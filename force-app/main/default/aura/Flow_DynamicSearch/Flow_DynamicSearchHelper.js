({
    getData : function(component,event,helper,getColumns) {
        var action = component.get("c.startSearch");
        action.setParams({
            limitCount : component.get("v.limitCount"),
            sObjectType : component.get("v.sObjectType"),
            soqlString : component.get("v.SOQLString"),
            searchString : component.get("v.searchString"),
            getFieldNames : getColumns
        });        
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS'){
                console.log(JSON.stringify(response.getReturnValue()));
                var response = response.getReturnValue();
                /*var actionColumn = {type: "button", initialWidth: 120, typeAttributes: {
                             iconName: 'utility:add',
                             label: 'Select',
                             name: 'selectRecord',
                             title: 'selectRecord',
                             disabled: false,
                             value: 'test',
                             variant: 'neutral',  
                             }};*/
                var actionColumn = {type: "button-icon", initialWidth: 100, typeAttributes: {
                    iconName: 'utility:add',
                    name: 'selectRecord',
                    title: 'selectRecord', 
                    alternativeText : 'select'
                }};
                response.columns.unshift(actionColumn);
                component.set("v.data",response.data);
                if(getColumns){
                    component.set("v.fieldNames",this.formatColumns(response.columns));
                }             
                component.set("v.issearching",false);
                component.set("v.getLabels",false);
                component.set("v.searchAttempted", true);
            }else{
                component.set("v.issearching",false);
                console.log(response.getError());
                component.set("v.errorMessage",response.getError()[0].message);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    formatColumns : function(columns){
        
        for(var i=0;i<columns.length;i+=1){
            if(columns[i].type == 'DOUBLE'){
                columns[i].type = 'number';     
            }
            if(columns[i].type == 'BOOLEAN'){
                columns[i].type = 'boolean';     
            }
        }
        
        return columns;
    },
    
    registerValidation : function(component,event,helper){
        component.set('v.validate', function(){
            
            var isRequired = component.get("v.isRequired");
            var recId = component.get("v.recordId");

            if(!isRequired || (recId && recId != null && recId != '')){
                return {isValid:true}; 
            } else{
                return {
                    isValid:false,
                    errorMessage: component.get("v.isRequiredErrorMessage")
                }
            }
        });
    }
})