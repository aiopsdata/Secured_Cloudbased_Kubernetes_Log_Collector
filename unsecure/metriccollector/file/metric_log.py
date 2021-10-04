## METRIC

from kubernetes import client, config
from elasticsearch import Elasticsearch
from kubernetes.client.rest import ApiException
from elasticsearch import ElasticsearchException
from datetime import datetime
import os
import json
import time

document_id = 0

while(True):
    try:
        config.load_incluster_config()                                   # cofigure kubernetes python client
    except config.ConfigException:
        print("\n Exception when configure kubernetes client: %s\n" % e)
        
    if os.environ["CLOUD"] == "cloud":
        try:
            es = Elasticsearch(cloud_id=os.environ["CLOUD_ID"],http_auth=(os.environ["USER"],os.environ["PASSWORD"]),timeout=40)

        except ElasticsearchException as e:
            print("\n Exception when calling ElasticsearchApi->creating connection in Cloud: %s\n" % e) 
    else:
        try: 
            es_link = "http://"+os.environ['ELASTICSEARCH_URL']
            es = Elasticsearch(es_link, timeout = 30)
            #es = Elasticsearch(os.environ['ELASTICSEARCH_URL'],http_auth=(os.environ["USER"],os.environ["PASSWORD"]),timeout=30)        # Creating connection with Elastic Search
        except ElasticsearchException as e:
            print(" \n Exception when calling ElasticsearchApi: %s\n" % e) 

        
        
    namespace_list_api = client.CoreV1Api()                                          # namespace list object
    try:
        namespace_list = namespace_list_api.list_namespace()
    except ApiException as e:
        print("\n Exception when calling CoreV1Api->list_namespace: %s\n" % e)
        
    namespace_object = client.CustomObjectsApi()                                      # namespace scoped custom object
    
    for namespace_data in namespace_list.items:
        namespace = namespace_data.metadata.name
        print(namespace)
        
        try:
            data = namespace_object.list_namespaced_custom_object(group=os.environ["METRIC_API"],version=os.environ["METRIC_VERSION"], namespace = namespace, plural="pods")     # getting pod events
        except ApiException as e:
            print("\n Exception when calling CustomObjectsApi->list_namespaced_custom_object: %s\n" % e)
            
        for pod in data["items"]:
            if len(pod['containers']) == 0:
                continue
            det = datetime.now()
            data_dic = json.dumps(dict({'agent' : "metric-collector",'datetime': det.strftime("%d/%m/%Y %H:%M:%S"),'data' : pod['containers'][0],'time': round(time.time(), 2)}))
            
            try:
                es.index(index=os.environ['INDEX_NAME'],doc_type=os.environ['DOC_TYPE'],id=document_id,body=data_dic,ignore=400)     # creating document in elasticsearch
            except ElasticsearchException as e:
                print("\n Exception when calling ElasticsearchApi->creating index/document: %s\n" % e)
                
            document_id = document_id+1
