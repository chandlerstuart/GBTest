({

    onInit : function(component,event,helper){
        helper.validateClickToDial(component,event,helper);
    },

    setSavePrompt : function(component, event, helper) {
        var spr = component.get("v.savePromptRequired");
        if(!spr) component.set("v.savePromptRequired",true);
        helper.validateClickToDial(component,event,helper);
    },
    
    onSave : function(component,event,helper){
                
        //TO DO - validate form
        var allowSave = helper.validateForm(component,event,helper);
        if(!allowSave){
            //Hide spinner and ensure page is expanded to reveal error/s
            component.set("v.showSpinner",false);
            component.set("v.isExpanded",true);
            return;
        }

        component.set("v.showSpinner",true);
        
        var action = component.get("c.submitChanges");
        action.setParams({
            "ind" : component.get("v.individual"),
            "acc" : component.get("v.account"),
            "changeHistoryText" : component.get("v.changeHistoryString"),
            "phoneNumber":component.get("v.workItemPhoneNumber")
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                //Save prompt no longer required
                var spr = component.get("v.savePromptRequired");
                if(spr) component.set("v.savePromptRequired",false);
                //Collapse the component
                component.set("v.isExpanded",false);
                //Fire Success Toast
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message":"Your changes were saved successfully",
                    "type" : "success",
                    "title" :"Success!"
                });
                toastEvent.fire();
                component.set("v.isPhoneAuditRequired",response.getReturnValue());
                //Remove Errors
                component.set("v.errorMessage", null);
                //Audit no longer required
                component.set("v.auditIsDue",false);
                //Hide spinner
                component.set("v.showSpinner",false);
                //Refresh component data
                var event = component.getEvent("changeEvent");
                event.setParams({
                    "refresh" : true
                })
                event.fire();
            }else if(state === 'ERROR'){
                //Add error to the page
                component.set("v.errorMessage", response.getError()[0].message);
                //Hide spinner and ensure page is expanded to reveal error/s
                component.set("v.showSpinner",false);
                component.set("v.isExpanded",true);
                //Fire fail toast
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message":"Your changes were unsuccessful: "+response.getError()[0].message,
                    "type" : "error",
                    "title" :"Failure!"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    },
    
    noChanges : function(component,event,helper){
            
        component.set("v.showSpinner",true);
        console.log('Individual Id: '+component.get("v.individual.Id"));

        var action = component.get("c.noChangesRequired");
        action.setParams({
            "indId" : component.get("v.individual.Id"),
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                //Save prompt no longer required
                var spr = component.get("v.savePromptRequired");
                if(spr) component.set("v.savePromptRequired",false);
                //Collapse the component
                component.set("v.isExpanded",false);
                //Fire Success Toast
                let toastEvent = $A.get("e.force:showToast");
                //Audit no longer required
                component.set("v.auditIsDue",false);
                //Hide spinner
                component.set("v.showSpinner",false);
                //Remove Errors
                component.set("v.errorMessage", null);
                //Refresh component data
                var event = component.getEvent("changeEvent");
                event.setParams({
                    "refresh" : true ,
                    "revisePanelValidation" : true
                })
                event.fire();
            }else if(state === 'ERROR'){
                //Add error to the page
                component.set("v.errorMessage", response.getError()[0].message);
                //Hide spinner and ensure page is expanded to reveal error/s
                component.set("v.showSpinner",false);
                component.set("v.isExpanded",true);
            }
        });
        $A.enqueueAction(action);
    },
    
    copyPhoneToField : function(component,event,helper){
        var phoneNumber = component.get("v.workItemPhoneNumber");
        var buttonClicked = event.getSource().getLocalId();
        var account = component.get("v.account");
        
        console.log('button clicked: '+buttonClicked);
        
        var changeMade = false;
        
        if(buttonClicked == 'mobileField'){
            if(account.PersonMobilePhone && account.PersonMobile != '' && account.PersonMobilePhone != phoneNumber){
                 if(confirm('Are you sure you want to replace '+account.PersonMobilePhone+' with '+phoneNumber+'?')){
                    account.PersonMobilePhone = phoneNumber;
                    changeMade = true;
                }
            }else{
                account.PersonMobilePhone = phoneNumber;
                changeMade = true;
            }
        }else if(buttonClicked == 'homePhoneField'){
            if(account.PersonHomePhone && account.PersonHomePhone != '' && account.PersonHomePhone != phoneNumber){ 
                if(confirm('Are you sure you want to replace '+account.PersonHomePhone+' with '+phoneNumber+'?')){
                    account.PersonHomePhone = phoneNumber;
                    changeMade = true;
                }
            }else{
                account.PersonHomePhone = phoneNumber;
                changeMade = true;
            }
        }else if(buttonClicked == 'phoneField'){
            if(account.Phone && account.Phone != '' && account.Phone != phoneNumber){
               if(confirm('Are you sure you want to replace '+account.Phone+' with '+phoneNumber+'?')){
                    account.Phone = phoneNumber;
                    changeMade = true;
                }
            }else{
                account.Phone = phoneNumber;
                changeMade = true;
            }
        }else if(buttonClicked == 'otherPhoneField'){
            if(account.PersonOtherPhone && account.PersonOtherPhone != '' && account.PersonOtherPhone != phoneNumber) {
                if(confirm('Are you sure you want to replace '+account.PersonOtherPhone+' with '+phoneNumber+'?')){
                    account.PersonOtherPhone = phoneNumber;
                    changeMade = true;
                }
            }else{
                account.PersonOtherPhone = phoneNumber;
                changeMade = true;
            } 
        }
        
        if(changeMade){
            component.set("v.account",account);
            component.set("v.savePromptRequired",true);
            helper.validateClickToDial(component,event,helper);
        } 
 
    },

    callClient : function(component,event,helper){
        var buttonId = event.getSource().getLocalId();
        let ctdComponent;

        if(buttonId == 'callClientMobile'){
            if(component.get("v.ctdEnabledMobile")) ctdComponent = 'ctdMobile';
        }else if(buttonId == 'callClientHome'){
            if(component.get("v.ctdEnabledHome")) ctdComponent = 'ctdHome';
        }else if(buttonId == 'callClientPhone'){
            if(component.get("v.ctdEnabledPhone")) ctdComponent = 'ctdPhone';
        }else if(buttonId == 'callClientOther'){
            if(component.get("v.ctdEnabledOther")) ctdComponent = 'ctdOther';
        }

        if(ctdComponent != null && ctdComponent != ''){
            let ctd = component.find(ctdComponent);
            ctd.click();
        }
    },

})