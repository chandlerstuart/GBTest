import { LightningElement, wire, api } from 'lwc';
import findClients from '@salesforce/apex/ConversationClientMatchingUtilityLWC.findClients';
import setAccountId from '@salesforce/apex/ConversationClientMatchingUtilityLWC.setAccountId';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ConversationClientMatchingUtility extends LightningElement {

    @api recordId;
    @api clientList; 
    @api showMatches;
    @api hasMultipleMatches;
    @api singleMatch

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Conversation__c.Account__c', 'Conversation__c.PhoneNumber__c' ] })

    //renderedCallback(){
        //this.loadCMP();
    //} 

    connectedCallback() {
        this.loadCMP();
    }

    loadCMP(){
        if(this.recordId != null){
            this.clientList = null;
            this.singleMatch = null;
            this.hasMultipleMatches = false;
            this.showMatches = false;
            findClients({
                recordId:this.recordId
            })
            .then(result => {
                if(result && result.length>0){
                    this.showMatches = true;
                    this.clientList = result;
                    if(result.length>1){
                        this.hasMultipleMatches = true;
                    }else{
                        this.singleMatch = this.clientList[0];
                    }
                    console.log(this.clientList);
                }
            })
            .catch(error => {
                console.error(error);
                let event = new ShowToastEvent({
                    title: 'Oops!',
                    message: this.error,
                    variant: 'error',
                    type:'sticky'
                });
                this.dispatchEvent(event);
            });
        }
    }
    
    hideMatches(){
        this.showMatches = false;
    }

    setAccountLookup(){
        setAccountId({
            recordId:this.recordId,
            accountId:this.singleMatch.Id
        })
        .then(result => {
            if(result == true){
                eval("$A.get('e.force:refreshView').fire();");
            }else{
                console.error('Oops something went wrong. Please contact your System Administrator');
            }
        })
        .catch(error => {
            console.error(error);
            let event = new ShowToastEvent({
                title: 'Oops!',
                message: this.error,
                variant: 'error',
                type:'sticky'
            });
            this.dispatchEvent(event);
        });
    }
}