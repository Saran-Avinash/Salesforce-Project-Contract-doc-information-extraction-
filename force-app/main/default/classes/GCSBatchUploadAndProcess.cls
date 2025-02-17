global class GCSBatchUploadAndProcess implements Database.Batchable<SObject>,  Database.AllowsCallouts {

    private String batchId;
    private List<Id> documentIds;
    public GCSBatchUploadAndProcess(List<Id> documentIds) {
        batchId ='Batch-' + DateTime.now().format('yyyyMMddHHmmss');   
        this.documentIds = documentIds;
        System.debug(this.documentIds);
        System.debug('Batch Id: ' + batchId);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('Document ids ' + documentIds);
        return Database.getQueryLocator('SELECT Id, VersionData, PathOnClient FROM ContentVersion WHERE ContentDocumentId IN :documentIds AND IsLatest = true');
    }

    global void execute(Database.BatchableContext BC, List<ContentVersion> scope) {
        
        List<ContentVersion> contentVersionList = scope;
        try{
             for(ContentVersion cv : contentVersionList){
                 String result = uploadToGCS(cv.VersionData, cv.PathOnClient);
                 System.debug(result);
              }
            }                   
        catch(Exception e){
            System.debug('Error in execute method' + e.getMessage());
           
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch Process Completed');

    }

    private String uploadToGCS(Blob content, String fileName) {
        String bucketName = 'doc_input_bucket';
        String projectId = 'bubbly-vine-446613-c6';
        String endpoint = 'callout:GoogleCloudStorage/upload/storage/v1/b/' + bucketName + '/o?uploadType=media&name=' + EncodingUtil.urlDecode(batchId + '/' + fileName, 'UTF-8');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/pdf');
        request.setBodyAsBlob(content);
        HttpResponse response;
        try{
         response   = http.send(request);
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }

        System.debug(response.getBody());
        return response.getBody();
       
    }
}