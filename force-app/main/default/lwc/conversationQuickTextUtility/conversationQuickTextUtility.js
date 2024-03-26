import { LightningElement, api } from 'lwc';
import getQuickTextOptions from '@salesforce/apex/ConversationQuickTextUtilityController.getQuickTextOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';

export default class ConversationQuickTextUtility extends LightningElement {

    @api selectedCategory;
    @api categoryOptions;
    @api showCategoryOptions = false;

    @api selectedQuickText;
    @api quickTextOptions;
    @api focusedQuickTextOptions;//Based on chosen category
    @api showQuickTextOptions = false;

    @api showTextMessagePreview;

    @api message = '';

    connectedCallback(){
        getQuickTextOptions()
        .then(result => {
            if(result){
                if(result.categoryOptions && result.categoryOptions.length>0){
                    this.categoryOptions = result.categoryOptions;
                    this.showCategoryOptions = true;
                }
                if(result.quickTextOptions && result.quickTextOptions.length>0){
                    this.quickTextOptions = result.quickTextOptions;
                }
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

    handleCategorySelection(event) {

        let quickTextList = [];
        this.selectedQuickText = null;
        this.showTextMessagePreview = false;
        this.selectedCategory = event.detail.value;
        this.focusedQuickTextOptions = [];

        //Prepare quick text options
        if(this.quickTextOptions && this.quickTextOptions.length>0){
            for(let i=0;i<this.quickTextOptions.length;i++){
                if(this.quickTextOptions[i].category == this.selectedCategory) quickTextList.push(this.quickTextOptions[i]);
            }
            if(quickTextList.length>0){
                this.focusedQuickTextOptions = quickTextList;
                this.showQuickTextOptions = true;
            }
        }
    }

    handleQuickTextSelection(event) {
        this.selectedQuickText = event.detail.value;
        if(this.selectedQuickText){
            this.showTextMessagePreview = true;
        }else{
            this.showTextMessagePreview = false;
        }
    }

    addText(event){
        if(!this.message) this.message = '';
        this.message = this.message+this.selectedQuickText;
    }

    replaceText(event){
        this.message = this.selectedQuickText;
    }

    handleChange(event){
        this.message = event.detail.value;
    }




}