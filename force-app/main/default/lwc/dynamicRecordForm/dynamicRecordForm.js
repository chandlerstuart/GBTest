import { LightningElement, api, wire } from 'lwc';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
  } from "lightning/messageService";
  import dynamicRecordForm from "@salesforce/messageChannel/dynamicRecordForm__c";

export default class RecordViewer extends LightningElement {

    // Define input properties
    @api theRecordId;
    @api objectApiName;
    @api title;
    @api showDynamicForm;

    @wire(MessageContext)
    messageContext;

    // You can add additional logic or methods as needed
    connectedCallback(){
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        this.theRecordId = subscribe(
        this.messageContext,
        dynamicRecordForm,
        (message) => this.handleMessage(message),
        { scope: APPLICATION_SCOPE },
        );
    }

    handleMessage(message) {
        console.log('dynamic form received message > ',message);
        this.theRecordId = message.recordId;
        this.objectApiName = message.objectApiName;
        this.title = message.title;
        if(message.recordId != null){
            this.showDynamicForm = false;
            this.showDynamicForm = true;
        }else{
            this.showDynamicForm = false;
        }
      }
}