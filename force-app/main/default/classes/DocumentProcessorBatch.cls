global class DocumentProcessorBatch implements Database.Batchable<sObject> , Database.allowsCallouts {
    private List<Id> documentIds;
    private List<Contract__c> contracts = new List<Contract__c>();
    private String projectId = 'bubbly-vine-446613-c6';
    private String location = 'us';
    private String processorId = '67d4efa0c2a94bf5';
    private String processorVersion = 'a23620139ec837e3';
    private final String NAMED_CREDENTIAL_URL = 'callout:DocAiBatch/v1/projects/'+projectId+'/locations/' + location + '/processors/' + processorId + '/processorVersions/' + processorVersion;
    global DocumentProcessorBatch(List<Id> documentIds){
        this.documentIds = documentIds;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('documentIds: ' + documentIds);
        return Database.getQueryLocator('SELECT Id, VersionData from ContentVersion WHERE ContentDocumentId IN :documentIds AND IsLatest = true');  

    }

    global void execute(Database.BatchableContext BC, List<ContentVersion> scope){

        List<ContentVersion> contentVersionList = scope;
        for(ContentVersion cv : contentVersionList){
            extractEntities(cv);
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('Batch Process Completed');
    }

    private void extractEntities(ContentVersion cv){
        String content = EncodingUtil.base64Encode(cv.VersionData);
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(NAMED_CREDENTIAL_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        Map<String, Object> payload = new Map<String, Object>();

        Map<String, Object> document = new Map<String, Object>();
        document.put('mimeType', 'application/pdf');
        document.put('content', content);

        //add to the payload
        payload.put('rawDocument', document);
        payload.put('fieldMask', 'entities');
        String payloadJson = JSON.serialize(payload);

        request.setBody(payloadJson);


        HttpResponse response;
        try{
            response = http.send(request);
            System.debug('response: ' + response);
            String jsonResponse = JSON.serialize(response.getBody());   
            String clientLegalCompanyName = '';
            String contractAmount = '';
            DocumentAIResponse response1 = (DocumentAIResponse) JSON.deserialize(jsonResponse, DocumentAIResponse.class);

            for (DocumentAIResponse.Entity entity : response1.document.entities) {
                if (entity.type == 'Client_legal_company_name') {
                    clientLegalCompanyName = entity.mentionText;
                } else if (entity.type == 'Contract_amount') {
                    contractAmount = entity.mentionText;
                }
            }
            
            System.debug('Client Legal Company Name: ' + clientLegalCompanyName);
            System.debug('Contract Amount: ' + contractAmount);
            



            // Contract__c contract = new Contract__c(Name='Test Contract', response__c = JSON.serialize(response.getBody()), Client_name__c = clientLegalCompanyName, Contract_Amount__c = contractAmount);
            // upsert contract;
        }
        catch(Exception e){
            System.debug('Exception: ' + e);
        }
    }
}