import { LightningElement, api } from 'lwc';

export default class ActOnItAlertManager extends LightningElement {
    @api message;
    @api showError;
    @api showWarning;

    @api get type(){return this._type}

    set type(value){
        this._type = value;
        this.showError = (value == 'error')?true:false;
        this.showWarning = (value == 'warning')?true:false;
    }
}