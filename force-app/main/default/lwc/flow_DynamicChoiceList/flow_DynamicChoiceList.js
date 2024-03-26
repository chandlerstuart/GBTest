import { LightningElement, api } from 'lwc';

export default class FlowDynamicChoiceList extends LightningElement {

    @api selectedValue;

    @api option1Label;
    @api option1Value;
    @api option2Label;
    @api option2Value;
    @api option3Label;
    @api option3Value;
    @api option4Label;
    @api option4Value;
    @api option5Label;
    @api option5Value;

    @api fieldLabel;
    @api placeholder;
    @api isPicklist;
    @api isRequired;
    @api displayValues;

    @api showRadioButtons;
    @api showPicklist;

    @api selectOptions;

    connectedCallback(){
        this.selectOptions = [];

        if(this.option1Value != null){
            let option1 = {};
            option1.label = (!this.displayValues)?this.option1Label:this.option1Label+' - '+this.option1Value;
            option1.value = this.option1Value;
            this.selectOptions.push(option1);
        }
        if(this.option2Value != null){
            let option2 = {};
            option2.label = (!this.displayValues)?this.option2Label:this.option2Label+' - '+this.option2Value;
            option2.value = this.option2Value;
            this.selectOptions.push(option2);
        }
        if(this.option3Value != null){
            let option3 = {};
            option3.label = (!this.displayValues)?this.option3Label:this.option3Label+' - '+this.option3Value;
            option3.value = this.option3Value;
            this.selectOptions.push(option3);
        }
        if(this.option4Value != null){
            let option4 = {};
            option4.label = (!this.displayValues)?this.option4Label:this.option4Label+' - '+this.option4Value;
            option4.value = this.option4Value;
            this.selectOptions.push(option4);
        }
        if(this.option5Value != null){
            let option5 = {};
            option5.label = (!this.displayValues)?this.option5Label:this.option5Label+' - '+this.option5Value;
            option5.value = this.option5Value;
            this.selectOptions.push(option5);
        }

        if(this.isPicklist == true){
            this.showRadioButtons = false;
            this.showPicklist = true;
        }else{
            this.showRadioButtons = true;
            this.showPicklist = false;
        }
    }

    handleChange(event){
        this.selectedValue = event.detail.value;
    }
}