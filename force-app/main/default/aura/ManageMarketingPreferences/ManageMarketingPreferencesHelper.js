({
    doInit : function(component,event,helper) {
        
        var recordId = component.get("v.recordId");
        var fieldName = component.get("v.fieldName");
        var sObjectType = component.get("v.sObjectType");
        
        //Validating parameters for server side call
        if(!recordId || !fieldName || !sObjectType){
            var errorMessage = 'Missing Info: ';
            if(!recordId) errorMessage += 'No Record Id set. ';
            if(!fieldName) errorMessage += 'No Field Name set. ';
            if(!sObjectType) errorMessage += 'No sObjectType set. ';
            component.set("v.errorMessage",errorMessage);
            console.log('Error: '+errorMessage);
            component.set("v.isLoading",false);
            return;
        }
		
        //Retrieving data
        var action = component.get("c.getData");
        action.setParams({
            recordId : component.get("v.recordId"),
            fieldName : component.get("v.fieldName"),
            sObjectType : component.get("v.sObjectType"),
            workItemPhoneFieldName : component.get("v.workItemPhoneFieldName")
        })
        action.setCallback(this,function(response){
            var state = response.getState();
            console.log('Marketing Preferences Call State: '+state);
            if( state ==='SUCCESS'){
                var data = response.getReturnValue();
                component.set("v.workItemPhoneNumber",data.workItemPhoneNumber);
                component.set("v.account",data.acc);
                this.handleWorkItemPhoneAudit(component,event,helper);          
                component.set("v.individual",data.ind);
                component.set("v.brochureOnPageLoad",data.ind.Brochure__c);
                var auditDue = this.auditDueCalc(data.ind.Data_Audit_Last_Completed__c,component.get("v.auditAfterDays"));           
                component.set("v.auditIsDue",auditDue);
                console.log('Marketing Preferences Data Successfully Retrieved');
                component.set("v.isLoading",false);
                //Refresh component data
                var event = component.getEvent("changeEvent");
                event.setParams({
                    "revisePanelValidation" : true
                })
                event.fire();
            }else if( state=== 'ERROR'){
                 component.set("v.errorMessage",'Error loading Marketing Preferences for Client: '+response.getError()[0].message);
                // Fire error toast
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message":"Error loading Marketing Preferences for Client: "+response.getError()[0].message,
                    "type" : "error",
                    "title" :"There was an error"
                });
                toastEvent.fire();
                component.set("v.isLoading",false);
            }
        })
        $A.enqueueAction(action);
    },
    
    auditDueCalc : function(lastAudit,auditDays){
        
        //Audit is required if never audited previously
        if(!lastAudit) return true;
        
        if(!auditDays) auditDays = 90;
        
        //Get todays date
        var todaysDate = new Date();
        
        //Convert String Date to Date Object
        lastAudit = new Date(lastAudit);
        
        //Calc next audit date
        var nextAudit = this.addDays(lastAudit,auditDays);
        
        return (todaysDate >= nextAudit)? true:false;
        
    },
    
    addDays: function(dateToAdd, days) {
        var date = new Date(dateToAdd);
        date.setDate(date.getDate() + days);
        return date;
    },
    
    handleWorkItemPhoneAudit : function(component,event,helper) {
        
        var phoneNumber = component.get("v.workItemPhoneNumber");
        if(!phoneNumber || phoneNumber === "") return;
        var account = component.get("v.account");
        var auditRequired = true;
        if(account.Phone == phoneNumber) auditRequired = false;
        if(account.PersonMobilePhone == phoneNumber) auditRequired = false;
        if(account.PersonHomePhone == phoneNumber) auditRequired = false;
        if(account.PersonOtherPhone == phoneNumber) auditRequired = false;
		
        if(auditRequired) component.set("v.isPhoneAuditRequired",true);
    }
})