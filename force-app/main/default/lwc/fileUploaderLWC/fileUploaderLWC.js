import { LightningElement, api, track, wire } from 'lwc';
import processDocuments from '@salesforce/apex/DocumentProcessor.processDocuments';

export default class FileUploaderLWC extends LightningElement {

    @api recordId;
    @track documentIds = [];
    @track filesUploaded = [];
    acceptedFormats=['.pdf'];

    handleUploadFinished(event){

        try{
            this.filesUploaded = event.detail.files;
            const uploadedFiles = event.detail.files;
            for(let files of uploadedFiles){
                this.documentIds.push(files.documentId);
            }
            console.log(this.documentIds)
            //const obj = {documentIds : this.documentIds}
            processDocuments({documentIds : this.documentIds})
        }
        catch(error){
            console.log('Error occured' + error);
        }
    }
}