import { LightningElement, api, wire } from 'lwc';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from 'lightning/messageService';
import QTextSelection from '@salesforce/messageChannel/ActOnIt__QuickTextSelection__c';
export default class StartAConversationQuickTextUtility extends LightningElement {
    
    @api recordId; 
    @api whoId;
    @api message;
    @api channel;
    @api escapedMessage;

    @wire(MessageContext)
    messageContext;

    handleQuickTextSelection(event){
        let quickText = event.getParam('quickText');
        console.log('quickText > ',quickText);  
        this.message = quickText;
        this.escapedMessage = (quickText == null || quickText.length==0)?null:quickText.replace(/\r/g, "\\r").replace(/\n/g,"\\n");
        console.log(this.message);
        console.log(this.escapedMessage);
    }

    handleChange(event){
        this.message = event.detail.value;
        this.escapedMessage = (event.detail.value == null || event.detail.value.length==0)?null:event.detail.value.replace(/\r/g, "\\r").replace(/\n/g,"\\n");
        console.log(this.message);
        console.log(this.escapedMessage);
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // Subscribe to Act On It Quick Text Selection
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                QTextSelection,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    // Apply quick text to message (replace)
    handleMessage(message) {
        this.message = message.quickText;
        this.escapedMessage = (message.quickText == null || message.quickText.length==0)?null:message.quickText.replace(/\r/g, "\\r").replace(/\n/g,"\\n");
        console.log(this.message);
        console.log(this.escapedMessage);
    }
}