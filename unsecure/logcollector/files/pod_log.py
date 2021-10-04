## POD

from kubernetes import client, config, watch
from kubernetes.client import configuration
from elasticsearch import Elasticsearch
from kubernetes.client.rest import ApiException
from elasticsearch import ElasticsearchException
import os
from datetime import datetime
import json
import time

configuration.assert_hostname = False

try:
    config.load_incluster_config()                                   # cofigure kubernetes python client
except config.ConfigException as e:
    print("\n Exception when configure kubernetes client: %s\n" % e)

pod_list_api = client.CoreV1Api()                            # pod_list_api Object
document_id = 0
running_time = 0
while(True):
    pod_list = pod_list_api.list_pod_for_all_namespaces()        # List all pods from all namespaces 

    
    for pod in pod_list.items:
        if os.environ["CLOUD"] == "cloud":
            try:
                es = Elasticsearch(cloud_id=os.environ["CLOUD_ID"],http_auth=(os.environ["USER"],os.environ["PASSWORD"]),timeout=40)

            except ElasticsearchException as e:
                print("\n Exception when calling ElasticsearchApi->creating connection in Cloud: %s\n" % e) 

        else:
            try:
                es_link = "http://"+os.environ['ELASTICSEARCH_URL']
                es = Elasticsearch(es_link, timeout = 50)                         # Elastic Search connection object
            except ElasticsearchException as e:
                print("\n Exception when calling ElasticsearchApi->creating connection: %s\n" % e) 

        namespace = pod.metadata.namespace
        podname = pod.metadata.name

        if pod.status.container_statuses[0].ready is False:                 # Check if pod is not ready
            continue
            
        c_name=pod.spec.containers[0].name
        if running_time == 0:
            data = pod_list_api.read_namespaced_pod_log(namespace = namespace,name = podname, container = c_name)
        else:
            data = pod_list_api.read_namespaced_pod_log(namespace = namespace,name = podname, container = c_name, since_seconds=1)
        if data != "":
            date = datetime.now()
            date = date.strftime("%d/%m/%Y %H:%M:%S")
            data_dic = json.dumps(dict({'agent' : "log-collector",'datetime': date,'namespace' : namespace, 'pod': podname , 'time': round(time.time(), 2), 'podlog': data}))

            try:
                es.index(index=os.environ['PINDEX_NAME'],doc_type=os.environ['PDOC_TYPE'],id=document_id,body=data_dic,ignore=400)
            except ElasticsearchException as e:
                print("\n Exception when calling ElasticsearchApi->creating connection: %s\n" % e)

        document_id =  document_id + 1
    time.sleep(1)
    running_time = 1
      


