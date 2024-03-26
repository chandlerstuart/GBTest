({
	validateForm : function(component,event,helper) {
		        
                
        var allowSave = true;
        
        //Validating Phone Number Input        
        allowSave = [].concat(component.find('inputField')).reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            console.log('inputCmp: '+inputCmp);
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        console.log('allowSave: '+allowSave);
        
        //Block users from subscribing clients to the brochure without specifying a valid mailing address
        var brochureOnPageLoad = component.get("v.brochureOnPageLoad");
        var individual = component.get("v.individual");
        var account = component.get("v.account");
                
        if(!brochureOnPageLoad && individual.Brochure__c && (!account.PersonMailingStreet || !account.PersonMailingPostalCode)){
            allowSave = false;
            console.error("You must provide a valid mailing address when signing the Client up to the Brochure. If you do not have a valid mailing address for the Client, please deselect the Brochure subscription and proceed to save");
            component.set("v.errorMessage",'You must provide a valid mailing address when signing the Client up to the Brochure. If you do not have a valid mailing address for the Client, please deselect the Brochure subscription and proceed to save');
        }        
        
        return allowSave;
    },

    validateClickToDial : function(component,event,helper) {
        let minPhoneCharacterLength = 12;
        let maxPhoneCharacterLength = 15

        //var phoneRGEX = /^[(]{0,1}[0-9]{3}[)]{0,1}[-\s\.]{0,1}[0-9]{3}[-\s\.]{0,1}[0-9]{4}$/;
        var phoneRGEX = /^\+?[1-9]\d{1,14}$/;

        let acc = component.get("v.account");

        let mobileResult = (acc.PersonMobilePhone != null && acc.PersonMobilePhone.length>=minPhoneCharacterLength && acc.PersonMobilePhone.length <= maxPhoneCharacterLength)? phoneRGEX.test(acc.PersonMobilePhone):false;
        let homeResult = (acc.PersonHomePhone != null && acc.PersonHomePhone.length>=minPhoneCharacterLength && acc.PersonHomePhone.length <= maxPhoneCharacterLength)? phoneRGEX.test(acc.PersonHomePhone):false;
        let phoneResult = (acc.Phone != null && acc.Phone.length>=minPhoneCharacterLength && acc.Phone.length <= maxPhoneCharacterLength)? phoneRGEX.test(acc.Phone):false;
        let otherPhoneResult = (acc.PersonOtherPhone != null && acc.PersonOtherPhone.length>=minPhoneCharacterLength && acc.PersonOtherPhone.length <= maxPhoneCharacterLength)? phoneRGEX.test(acc.PersonOtherPhone):false;

        if(component.get("v.ctdEnabledMobile") != mobileResult) component.set("v.ctdEnabledMobile",mobileResult);
        if(component.get("v.ctdEnabledHome") != homeResult) component.set("v.ctdEnabledHome",homeResult);
        if(component.get("v.ctdEnabledPhone") != phoneResult) component.set("v.ctdEnabledPhone",phoneResult);
        if(component.get("v.ctdEnabledOther") != otherPhoneResult) component.set("v.ctdEnabledOther",otherPhoneResult);

    },
    

})