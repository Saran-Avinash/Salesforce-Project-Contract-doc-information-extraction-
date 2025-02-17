@RestResource(urlMapping='/handleDocAiResponse/')

global with sharing class HandleDocAiResponse {
    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String arr = req.requestBody.toString();
        //DocumentContent": "{\"file_name\": \"Batch-20250119225116/7kUU7npVr8.pdf\", \"company_names\": \"Netflix Inc.\", \"contract_amounts\": \"300,000\"}"
        System.debug('Body is ' + arr);

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(arr);
        
        String documentContentString = (String)payload.get('DocumentContent');
        System.Debug('Document Content string is ' + documentContentString);

        Map<String, Object> documentContent = (Map<String, Object>) JSON.deserializeUntyped(documentContentString);
        try{
            String fileName = String.valueOf(documentContent.get('file_name'));
            String companyName = String.valueOf(documentContent.get('company_names'));
            String amount = String.valueOf(documentContent.get('contract_amounts'));

            //Save the data in the custom object
            Contract__c contract = new Contract__c(Client_name__c = companyName, Contract_Amount__c = amount, Name = fileName);
            upsert contract contract.Name;
            // System.debug(documentContent.get('company_names'));
            // System.debug(documentContent.get('contract_amounts'));
        }
        catch(Exception e ){
            System.debug(e.getMessage());
        }
        return 'Data received in salesforce';
    }
}