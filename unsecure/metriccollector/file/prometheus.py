## PROMETHEUS

import requests
import time
from elasticsearch import Elasticsearch
from kubernetes.client.rest import ApiException
from elasticsearch import ElasticsearchException
from datetime import datetime
import os
import json

url = os.environ['PROMETHEUS_URL']     # prometheus-node-exporter url

def fetch_from_node_exporter_url(url):
    response_data = dict()                                             # Fetching data from prometheus-node_exporter
    try:
        response_data = {}
        response_data['agent'] = "metric-collector"
        response_data['datetime'] = datetime.now()
        response_data['data'] = requests.get(url)
        response_data['data'] = response_data['data'].text
        response_data['time'] = round(time.time(), 2)
    except requests.exceptions.RequestException as e:  
        print("\n Exception when request data : %s\n" % e)  
    return response_data

def insert_record_es(response_data):
    try:
        es_conn.index(index=os.environ['PINDEX_NAME'], doc_type=os.environ['PDOC_TYPE'], body=response_data,ignore=400)  # Insert data in ElasticSearch
    except ElasticsearchException as e:
        print("\n Exception when calling ElasticsearchApi->insert_record: %s\n" % e)    

if os.environ["CLOUD"] == "cloud":
    try:
        es_conn = Elasticsearch(cloud_id=os.environ["CLOUD_ID"],http_auth=(os.environ["USER"],os.environ["PASSWORD"]),timeout=40)

    except ElasticsearchException as e:
        print("\n Exception when calling ElasticsearchApi->creating connection in Cloud: %s\n" % e)         
else:
    try:
        es_link = "http://"+os.environ['ELASTICSEARCH_URL']
        es_conn = Elasticsearch(es_link, timeout = 50)
        #es_conn = Elasticsearch(os.environ['ELASTICSEARCH_URL'],http_auth=(os.environ["USER"],os.environ["PASSWORD"]),timeout=30)                  # Create connection object with ElasticSearch
        print("es = {}\n".format(es_conn))
    except ElasticsearchException as e:
            print("\n Exception when calling ElasticsearchApi->create_connection: %s\n" % e)    

while True:
    response_data = fetch_from_node_exporter_url(url)
    insert_record_es(response_data)
    print("inserted one doc")
    
    time.sleep(5)

print("successfully completed!")
