import functions_framework
import requests
import threading
import re
import json
from google.cloud import documentai
from google.cloud import storage

salesforce_token = {
    "access_token" : None
}
# token_lock = threading.Lock()
SALESFORCE_TOKEN_URL = "https://login.salesforce.com/services/oauth2/token"
SALESFORCE_CLIENT_ID = "3MVG9VMBZCsTL9hnJsmIhAaEruNOtv.EEwn95JmLmIaZHJIldQxBOwKgW_COSnkLdmmm_9JhUSjO0QcuPU5zY"
SALESFORCE_CLIENT_SECRET = "C7B0BAFC91461302DE314B5D1F4BB456FC9A2B3A177E56D0AABD33027F0EE61F"
SALESFORCE_USERNAME = "saranbaskarmsp@cunning-badger-59380s.com"
SALESFORCE_PASSWORD = "saran123@*KnlJDLR4COjFJAtKxi23kTCO"
gcs_output_uri = "gs://doc_output_bucket"
PROJECT_ID = "bubbly-vine-446613-c6"
PROCESSOR_ID = "67d4efa0c2a94bf5"
field_mask="entities"
LOCATION = "us"  # e.g., 'us' or 'eu'
# Triggered by a change in a storage bucket

def get_salesforce_token():
    """Authenticate with Salesforce and get an access token."""
    data = {
        "grant_type": "password",
        "client_id": SALESFORCE_CLIENT_ID,
        "client_secret": SALESFORCE_CLIENT_SECRET,
        "username": SALESFORCE_USERNAME,
        "password": SALESFORCE_PASSWORD
    }

    response = requests.post(SALESFORCE_TOKEN_URL, data=data)
    #response.raise_for_status()  # Raise an error for non-2xx responses
    if response.status_code == 200:
        token_data = response.json()
        # with token_lock:
        salesforce_token["access_token"] = token_data["access_token"]
        print("Fetched salesforce token successfully")
    else:
        print("Error retrieving token from salesforce: ", response.json())
   # return response.json()["access_token"]

def get_valid_salesforce_token():
    global salesforce_token

    if salesforce_token["access_token"]:
        return salesforce_token["access_token"]
    # with token_lock:
    if not salesforce_token["access_token"]:
        print("Salesforce token missing. Fetching a new one..")
        get_salesforce_token()
    return salesforce_token["access_token"]

def send_to_salesforce(document_ai_response):
    """Send Document AI response to Salesforce."""
    global salesforce_token

    try:
        access_token = get_valid_salesforce_token()
        salesforce_url = "https://cunning-badger-59380s-dev-ed.trailblaze.my.salesforce.com/services/apexrest/handleDocAiResponse/"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        # Customize the payload based on the Document AI response
        payload = {
            "DocumentContent": json.dumps(document_ai_response)  # You can extract specific fields here
        }
        response = requests.post(salesforce_url, headers=headers, json=payload)
        # response.raise_for_status()

        if response.status_code == 200:
            print("Data sent successfully", response.json())
        elif response.status_code == 401:
            print("Access token expired. Fetching a new one and retrying")
           
            get_salesforce_token()
            send_to_salesforce(document_ai_response)
        else:
            print("Error sending data to salesforce: ", response.json())
    except Exception as e:
        print(f"An error occured: {str(e)}")

def process_document(file_path):
    """Call Document AI to process the uploaded file."""
    client = documentai.DocumentProcessorServiceClient()
    
    # Get the GCS URI from the file_path dict
    input_uri = f"gs://{file_path['bucket']}/{file_path['name']}"
    
    # Get the content from GCS
    storage_client = storage.Client()
    bucket = storage_client.bucket(file_path['bucket'])
    blob = bucket.blob(file_path['name'])
    content = blob.download_as_bytes()

    # Configure the process request
    raw_document = documentai.RawDocument(
        content=content,
        mime_type="application/pdf"
    )
    
    # Construct the full resource name of the processor
    processor_name = f"projects/{PROJECT_ID}/locations/{LOCATION}/processors/{PROCESSOR_ID}"
    
    # Process the document
    request = documentai.ProcessRequest(
        name=processor_name,
        raw_document=raw_document
    )
    
    result = client.process_document(request=request)
    document = result.document
    print(document)
    
    
    # Extract the required data
    extracted_data = {
        'file_name' : None,
        'company_names': None,
        'contract_amounts': None,        
    }
    # adding file name to the result
    extracted_data['file_name'] = file_path['name']
    # Process entities
    for entity in document.entities:
        if entity.type_ == 'Client_legal_company_name':
            extracted_data['company_names'] = entity.mention_text
        elif entity.type_ == 'Contract_amount':
            extracted_data['contract_amounts'] = entity.mention_text
    
    return extracted_data
@functions_framework.cloud_event
def hello_gcs(cloud_event):
    data = cloud_event.data

    # event_id = cloud_event["id"]
    # event_type = cloud_event["type"]

    bucket = data["bucket"]
    name = data["name"]
    print(f"Triggered file, {name} from the bucket, {bucket}")
    # metageneration = data["metageneration"]
    # timeCreated = data["timeCreated"]
    # updated = data["updated"]

    # print(f"Event ID: {event_id}")
    # print(f"Event type: {event_type}")
    # print(f"Bucket: {bucket}")
    # print(f"File: {name}")
    # print(f"Metageneration: {metageneration}")
    # print(f"Created: {timeCreated}")
    # print(f"Updated: {updated}")


    
    try:
        # Step 1: Call Document AI
        document_ai_response = process_document({"bucket": bucket, "name": name})
        print("Document AI processing completed.")

        # Step 2: Get Salesforce access token
        # access_token = get_salesforce_token()
        # print("Salesforce token retrieved.")

        # Step 3: Send Document AI response to Salesforce
        send_to_salesforce(document_ai_response)
        print("Data sent to Salesforce")

    except Exception as e:
        print(f"Error: {e}")
