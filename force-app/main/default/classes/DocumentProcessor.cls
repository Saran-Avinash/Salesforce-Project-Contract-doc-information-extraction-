public with sharing class DocumentProcessor {
    

    @AuraEnabled
    public static void processDocuments(List<Id> documentIds) {

        Database.executeBatch(new GCSBatchUploadAndProcess(documentIds), 5);
    }

}