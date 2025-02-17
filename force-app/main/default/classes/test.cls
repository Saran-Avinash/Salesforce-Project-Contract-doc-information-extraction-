public with sharing class test {
   
    @future(callout=true)
    public static void testFun(){
        Http http = new Http();
HttpRequest request = new HttpRequest();
request.setEndpoint('https://gcsv4-883143682205.us-central1.run.app');
request.setMethod('POST');
request.setHeader('Content-Type', 'application/json');
String body = '{"gcs_input_prefix": "gs://doc_input_bucket/Batch-20250108192039/", "processor_version_id" : "a23620139ec837e3"}';
request.setBody(body);
request.setHeader('Content-Length', String.valueOf(body.length()));
// request.setTimeout(120000);

try{
    HttpResponse response = http.send(request);
    if(response.getStatusCode() == 200){
        System.debug(response.getBody());
    }
    else{
        System.debug('Error: ' + response.getStatusCode() + ' ' + response.getBody() );
    }
}
catch(Exception e){
    System.debug(e.getMessage());
}
    }
}