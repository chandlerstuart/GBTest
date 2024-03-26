import { LightningElement, track, api } from 'lwc';
import executeCallout from '@salesforce/apex/QuickCalloutButtonController.executeCallout';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QuickCalloutButton extends LightningElement {

    @api buttonLabel;
    @api calloutDataEventType;
    @api successMessage;
    @api sldsIconName;
    @api iconSize;
    @api recordId;
    @api promptMessage

    @track errorMessage;
    @track responseBody;
    @track isSuccess;
    @track runtimeError;
    @track showError;
    @api showSpinner;
    @api showButton;

    connectedCallback() {
        // initialize component
        this.showButton = true; 
        this.showSpinner = false;
    }

    submitAction() {
        this.clearError();
        if(this.promptMessage && this.promptMessage != ''){
            if(!confirm(this.promptMessage)) return;
        }
        this.showSpinner = true;
        executeCallout({
            dataEventType:this.calloutDataEventType,
            recordId:this.recordId})
            .then(result => {
                this.responseBody = result.responseBody;
                this.errorMessage = result.errorMessage;
                this.isSuccess = result.isSuccess;
                this.showSpinner = false;
                if(this.isSuccess){
                    let event = new ShowToastEvent({
                        title: 'Success!',
                        message: this.successMessage,
                        variant: 'success',
                        mode:'dismissible'
                    });
                    this.dispatchEvent(event);  
                    this.showButton = false; 
                }else{
                    let event = new ShowToastEvent({
                        title: 'Oops!',
                        message: (this.errorMessage != null && this.errorMessage != '')?this.errorMessage:'Something went wrong. Please share the details displayed with the Salesforce Team',
                        variant: 'error',
                        mode:'sticky'
                    });
                    this.dispatchEvent(event);
                    this.runtimeError = this.responseBody;
                    this.showError = true;
                }
            })
            .catch(error => {
                console.error(error);
                this.showSpinner = false;
                this.runtimeError = error.body.message;
                this.showError = true;
            });
    }

    clearError() {
        this.showError = false;
        this.runtimeError = null;
    }

}