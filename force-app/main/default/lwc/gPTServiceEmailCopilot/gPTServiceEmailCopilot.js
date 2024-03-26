import { LightningElement, track, api } from 'lwc';
import loadCMP from '@salesforce/apex/GPTServiceEmailCopilotController.loadComponent';
import askGPT from '@salesforce/apex/GPTServiceEmailCopilotController.askGPT';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MyCustomComponent extends LightningElement {

    @api recordId;//Case Id
    @api clientId;//Account Id
    @api bookingId;//Booking Id

    @track promptOptions;//Level 1 Prompt Actions
    @track subPromptOptionsMap;//Data Map [Level 1 Prompt Id > Related Sub Prompt Select Options (Pick Vals)]
    @track subPromptOptions;//Level 2 Prompt Actions
    @track promptIdToPromptMessage;//Data Map [Level 1 Prompt Id > Prompt Message]

    @track isPromptSelected;//Has a level 1 prompt been selected? i.e. show secondary prompts?
    @track selectedPromptMessage;//The literal prompt message selected by the user
    @track textareaInput;//Additional instructions (input value)

    //Content
    @track selectedContentOptionId;//The unique Id of the selected content option (i.e. case Id or email message id)
    @track idToHTMLEmailContentMap;//HTML Data Map [Case Id > Desc, Email 1 Id > Email 1 HTML Body, Email 2 Id > Email 2 HTML Body] etc
    @track idToTextEmailContentMap;//Text Data Map [Case Id > Desc, Email 1 Id > Email 1 TEXT Body, Email 2 Id > Email 2 TEXT Body] etc
    @track contentSelectOptions;//Content Select Options (Picklist vals for deciding the focus message)
    @track focusContentHTML;//The HTML Email (or Case Description) selected by the user (i.e. the focus message for the suggested replies). This value is rendered on the page (incl formatting)
    @track focusContentText;//The TEXT Email (or Case Description) selected by the user (i.e. the focus message for the suggested replies). This is the value passed to the GPT api for processing (fewer characters and HTML stripped from message)
    @track latestContentOptionId;//The last selected content option id. Used to determine whether a new AI reply is required (compared with newest select option id) e.g. when the user selects (and settles) on a new content option and clicks 'AI Response'.

    //Buttons
    @track viewContentButtonVariant = 'brand';
    @track viewAIButtonVariant = 'neutral'; 
    @track isViewingContent = false;//Page state - Display focus content vs ai reply

    @track gptOutput = '';//The AI Response output
    @track messages = [];//The build up of gpt messages within the active conversation
    @track agentEdited = false;//Has the agent edited the content?

    @track showSpinner = false;

    @track typedText = '';
    i = 0;
    txt = '';
    speed = 1;

    //Reveal the AI output in a typewriter animation
    typeWriter() {
        if (this.i < this.txt.length) {
        this.gptOutput += this.txt.charAt(this.i);
        this.i++;
        setTimeout(this.typeWriter.bind(this), this.speed);
        }
    }

    connectedCallback() {
        this.showSpinner = true;
        // Call the Apex controller method on component initialization
        this.loadComponent();
    }    

    //Retrieve the list of email messages, the relevant Salesforce ids and the active prompt options
    loadComponent(){
        loadCMP({
            recordId:this.recordId //Pass case id
        })
        .then((result) => {
            try{
                console.log('loadCMP result: ',result);
                this.promptOptions = result.promptOptions;//Primary Prompt Options
                this.subPromptOptionsMap = result.subPromptOptionsMap;//Data Map: [Primary Prompt Id > Supported Sub Prompt Select Options]
                this.promptIdToPromptMessage = result.promptIdToPromptMessageMap;// Data Map: [Primary Prompt Id > Configured prompt message]
                this.idToHTMLEmailContentMap = result.idToHTMLEmailContentMap; // Data Map: [SF Id to HTML Email Body]
                this.idToTextEmailContentMap = result.idToTextEmailContentMap; // Data Map: [SF Id to TEXT Email Body]
                this.contentSelectOptions = result.contentSelectOptions; //Context Select Options (Pick Vals)
                this.selectedContentOptionId = result.contentSelectOptions[0].value;// Default selected Content Option
                this.focusContentHTML = this.idToHTMLEmailContentMap[this.selectedContentOptionId]; // Default content focus (HTML)
                this.focusContentText = this.idToTextEmailContentMap[this.selectedContentOptionId]; // Default content focus (Text)
                this.clientId = result.clientId; //Related Account Id
                this.bookingId = result.bookingId; //Related Booking Id
                this.isViewingContent = true; // Display the default content
                this.showSpinner = false; // Hide spinner

            }catch(error){
                console.error(error.message); // Log errors to console
            }
        }).catch((error) => {
            this.showSpinner = false;
            console.error('Error retrieving data:', error.message);
        });
    }

    //Display secondary prompt options OR invoke ask gpt action applying selected prompt message
    handlePromptSelection(event) {
        try{
            //console.log('selected prompt > '+selectedValue); 
            //console.log(this.promptIdToPromptMessage);
            //console.log(this.subPromptOptionsMap);
            const selectedValue = event.target.value;
            this.isPromptSelected = true;
            this.selectedPromptMessage = this.promptIdToPromptMessage[selectedValue];//Retrieve selected prompt message 
            this.subPromptOptions = this.subPromptOptionsMap[selectedValue]; //Retrieve and display supported secondary prompts (sub prompts)
            if(!this.subPromptOptions || this.subPromptOptions == null || this.subPromptOptions === 'undefined'){
                if(this.agentEdited == true){//Include the edited content in the request
                    this.executeGPT('Please take this: "'+this.gptOutput+'". Try again applying this feedback from the agent: '+this.selectedPromptMessage+' in UK english');// If there are no sub prompts, execute askGPT action
                }else{
                    this.executeGPT('Please try again applying this feedback from the agent: '+this.selectedPromptMessage+' in UK english');// If there are no sub prompts, execute askGPT action
                }
                this.gptOutput = '';
                this.textareaInput = '';
                this.showSpinner = true;
            }
        }catch(error){
            console.error(error.message);
        }
    }

    //Invoke ask gpt action applying chosen primary and secondard prompt messages
    handleSubPromptSelection(event){
        const selectedValue = event.target.value;
        if(this.agentEdited == true){//Include the edited content in the request
            this.executeGPT('Please take this: "'+this.gptOutput+'". Try again applying this feedback from the agent: '+this.selectedPromptMessage+' '+this.promptIdToPromptMessage[selectedValue]+' in UK english');
        }else{
            this.executeGPT('Please try again applying this feedback from the agent: '+this.selectedPromptMessage+' '+this.promptIdToPromptMessage[selectedValue]+' in UK english');//  Combine the primary prompt with the secondary prompt and execute the askGPT action
        }
        this.gptOutput = '';
        this.textareaInput = '';
        this.showSpinner = true;
        this.isPromptSelected = false; // Reset the page view (display primary prompts)
    }

    //Refresh the focus content to reflect user selction and start a new conversation
    handleChangeContent(event){
        let selectedContentId = event.target.value; //New content id
        this.selectedContentOptionId = selectedContentId; // Store the selected content id (sf Id)
        this.focusContentHTML = this.idToHTMLEmailContentMap[selectedContentId]; //Retrieve and display the selected content in HTML
        this.focusContentText = this.idToTextEmailContentMap[selectedContentId]; //Retrieve and store the selected content in TEXT
        //this.messages = []; //Clear all historical messages (start a new conversation)
        //this.gptOutput = ''; //Clear historical ai response suggestions
        this.isViewingContent = true; //Display the newly selected content
        this.viewAIButtonVariant = 'neutral'; 
        this.viewContentButtonVariant = 'brand';
    }

    executeGPT(promptMessage){
        console.log('Prompt Message > '+promptMessage);
        askGPT({
            messagesJSON:JSON.stringify(this.messages),//Pass historical messages
            prompt:promptMessage,//Pass the new prompt message
            focusContent:this.focusContentText,//Pass the selected email content
            bookingId:this.bookingId,//Pass the booking id
            clientId:this.clientId//Pass the client id
        })
        .then((result) => {
            console.log('RESULT > '+JSON.stringify(result));

            this.showSpinner = false;
            if(result.isSuccess == true){
                this.txt = result.output;
                this.messages = result.messages;
                this.i = 0;
                this.textareaInput= '';
                this.typeWriter();
            }else{
                console.error('Something went wrong!');
            }
        })
        .catch((error) => {
            this.showSpinner = false;
            console.error('Error retrieving data:', error);
        });
    }

    //Copy AI suggested reply to clipboard
    handleCopyToClipboard() {
        console.log(this.gptOutput);
        //TO DO - Fire Toast Message!
        navigator.clipboard.writeText(this.gptOutput)
        .then(() => {
            console.log('Text copied to clipboard');
        })
        .catch((error) => {
            console.error('Unable to copy text:', error);
        });
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'The email content has been copied to your clipboard.',
            variant: 'success'
          });
        this.dispatchEvent(evt);
    }

    //Refresh component and start new conversation
    startOver(){
        this.showSpinner = true;
        this.messages = []; //Clear all historical messages (start a new conversation)
        this.gptOutput = ''; //Clear historical ai response suggestions
        this.textareaInput = '';//Clear user's additional instructions
        this.subPromptOptions = [];//Clear sub prompt list
        this.executeGPT();//Ask GPT. Exclude prompt, so the default is applied for the selected content.
    }
    
    //Onchange event to apply user input to textareaInput value
    handleTextareaInputChange(event){
        this.textareaInput = event.target.value;
    }

    //Toggle to display selected content
    handleViewContentSelection(){
        this.viewAIButtonVariant = 'neutral';
        this.viewContentButtonVariant = 'brand';
        this.isViewingContent = true;
    }

    //Toggle to display AI response. Trigger callout if necessary.
    handleViewAIResponseSelection(){
        this.viewAIButtonVariant = 'brand';
        this.viewContentButtonVariant = 'neutral';
        this.isViewingContent = false;
        if(this.latestContentOptionId != this.selectedContentOptionId){// Has the content changed?
            this.latestContentOptionId = this.selectedContentOptionId;// If yes, store the newly selected value and trigger callout for new ai response.
            this.showSpinner = true;
            this.messages = [];
            this.gptOutput = '';
            this.executeGPT();
        }
    }

    //Handle carriage return submission for additional instructions
    handleEnter(event){
        if(event.keyCode === 13){
            this.showSpinner = true;
            this.gptOutput = '';
            this.executeGPT('Please try again applying this feedback from the agent: "'+this.textareaInput+'" in UK english');
        }
    }

    //Handle button select submission for additional instructions
    submitAdditionalInstructions() {
        this.showSpinner = true;
        this.gptOutput = '';
        this.executeGPT('Please try again applying this feedback from the agent: "'+this.textareaInput+'" in UK english');
    }

    handleAgentEdit(event){
        this.gptOutput = event.target.value;
        this.agentEdited = true;
    }

}