## EVENTS

from kubernetes import client, config, watch
from elasticsearch import Elasticsearch
from kubernetes.client.rest import ApiException
from elasticsearch import ElasticsearchException
from datetime import datetime
import os
import json
import time

try:
    config.load_incluster_config()                                   # cofigure kubernetes python client
except config.ConfigException as e:
    print("\n Exception when configure kubernetes client: %s\n" % e)
    
client_api_v1 = client.CoreV1Api()                                   # client api
watch_stream = watch.Watch()                                         # watch generator for streaming events
document_id = 0                                                      # Elastic Search document id


try:
    for event in watch_stream.stream(client_api_v1.list_event_for_all_namespaces):
        
        if os.environ["CLOUD"] == "cloud":
            try:
                es_conn_obj = Elasticsearch(cloud_id=os.environ["CLOUD_ID"],http_auth=(os.environ["USER"],os.environ["PASSWORD"]),timeout=40)
            except ElasticsearchException as e:
                print("\n Exception when calling ElasticsearchApi->creating connection in Cloud: %s\n" % e) 
        
        else:
            try:
                es_link = "http://"+os.environ['ELASTICSEARCH_URL']
                es_conn_obj = Elasticsearch(es_link, timeout = 30)   # Creating connection with Elastic Search
            except ElasticsearchException as e:
                print("\n Exception when calling ElasticsearchApi: %s\n" % e)
        dic_data = {}
        event_data = {'kind':event['raw_object']['kind'],'name':event['raw_object']['metadata']['name'],'namespace':event['raw_object']['metadata']['namespace'],'uid':event['raw_object']['metadata']['uid'],'resourceVersion':event['raw_object']['metadata']['resourceVersion'],'creationTimestamp':event['raw_object']['metadata']['creationTimestamp'],'involvedObject':event['raw_object']['involvedObject'],'reason':event['raw_object']['reason'],'message':event['raw_object']['message'],'source':event['raw_object']['source'],'firstTimestamp':event['raw_object']['firstTimestamp'],'lastTimestamp':event['raw_object']['lastTimestamp'],'type':event['raw_object']['type'],'eventTime':event['raw_object']['eventTime']}
        dic_data['agent'] = "log-collector"
        dic_data['datetime'] = datetime.now()
        dic_data['data'] = event_data
        dic_data['time'] = round(time.time(), 2)

        print(dic_data)
        es_conn_obj.index(index=os.environ['INDEX_NAME'],doc_type=os.environ['DOC_TYPE'],id=document_id,body=dic_data,ignore=400)    # insert data into Elastic Search
        document_id = document_id+1
        
except ApiException as e:
    print("\n Exception when calling ClientApi->list_event_for_all_namespaces: %s\n" % e)
