/*The purpose of this component is to facilitate the upload of booking related files to our external database with a reference in Salesforce (BookingDocument__c)*/
import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import uploadFile from '@salesforce/apex/ExternalFileUploaderController.uploadFile';
import { getRecord } from 'lightning/uiRecordApi';


export default class externalFileUploader extends NavigationMixin(LightningElement) {

    @track isLoading = false;
    acceptedFormats = '.png, .jpg, .jpeg, .pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .mp4, .mov, .avi, .mp3, .wav, .svg, .wav, .gif';
    fileName = '';
    fileDescription = '';
    showFileUpload = false;
    expanded=false;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    record;

    @api objectApiName;
    @api recordId;

    @track isNewDoc;

    connectedCallback() {
        this.isNewDoc = (this.objectApiName === 'BookingDocument__c')?false:true;
    }

    handleUploadFinished(event) {
        this.isLoading = true;
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            const file = uploadedFiles[0];
            console.log('the file > ',file);

            const fileId = file.documentId;
            const fileVersionId = file.contentVersionId;
            console.log('fileId > '+fileId);
            console.log('fileVersion > '+fileVersionId);

            // Make the API call to store the file externally
            uploadFile({ 
                documentId:fileId, 
                contentVersionId:fileVersionId, 
                recordId:this.recordId,
                fileName:this.fileName,
                fileDesc:this.fileDescription
            })
            .then((result) => {
                // API call succeeded
                console.log('result > '+result);
                if(result == null || result == ''){
                    this.fileName = '';
                    this.fileDescription = '';
                    this.showFileUpload = false;
                    this.expanded = false;
                    this.showSuccessToast();
                }else{
                    this.showErrorToast(result);
                }
            })
            .catch(error => {
                // API call failed
                console.error(error);
                this.showErrorToast(error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
        }else{
            console.error('No uploaded files');
        }
    }

    showSuccessToast() {
        const event = new ShowToastEvent({
        title: 'Success',
        message: 'File uploaded successfully',
        variant: 'success'
        });
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
        title: 'Error',
        message: message,
        variant: 'error',
        mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    handleNameChange(event) {
        this.fileName = event.target.value;
        this.showFileUpload = this.fileName !== '' && this.fileName !== 'undefined' && this.fileName != null;
    }

    handleDescriptionChange(event) {
        this.fileDescription = event.target.value;
    }

    expandOrCollapse(event){
        this.expanded = !this.expanded;
    }
}