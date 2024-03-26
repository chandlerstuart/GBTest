import { LightningElement, api, wire } from 'lwc';
import loadPageData from '@salesforce/apex/ConversationWindowController.getConversationId';
export default class ConversationWindow extends LightningElement {

    //Iframe details
    @api url;

    //Design attributes (App Builder)
    @api height;
    @api width;
    @api referrerPolicy;
    @api baseURL;

    //Page state
    @api showSpinner;

    //Record data
    @api recordId;//The conversation's record Id
    @api conversationId;//The external Id for the conversation

    connectedCallback() {
        this.showSpinner = true;
        if(this.recordId == null) this.recordId = this.conversationId;
        loadPageData({recordId:this.recordId}).then(result=>{
            //Check User settings
            this.showSpinner = false;
            if(result == null || result == ''){
                this.displayMessage = 'Whoops! We couldn\'t find the conversation Id. Please contact your system administrator if you require assistance.'
                this.displayMessageType = 'warning';
            }else{
                this.conversationId = result;
                this.url = this.baseURL+result;
            } 
        }).catch(error=>{
            this.showSpinner = false;
            this.displayMessage = 'Ooops there was an error. Please share the following details with your System Administrator: '+error.body.message;
            this.displayMessageType = 'error';
            console.error(error);
        }) 
    }

}