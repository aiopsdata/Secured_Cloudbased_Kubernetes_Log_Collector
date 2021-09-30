#!/bin/bash
log="0"
metric="0"
elastic="0"
kibana="0"
cloud="0"
cloud_id="0"
cloud_user="0"
cloud_password="0"
system_name="0"


while getopts :clmeki:u:p:s: flag
do
    case "${flag}" in
     c) cloud="1";;
     i) cloud_id=${OPTARG};;
     u) cloud_user=${OPTARG};;
     p) cloud_password=${OPTARG};;
     s) system_name=${OPTARG};;
     l) log="1";;
     m) metric="1";;
     e) elastic="1";;
     k) kibana="1";;
    esac
done


if [[ $system_name == "0" ]]
then 
	echo "System Name cannot be empty, please enter System Name : "
	read system_name	
fi


nmspace=$(kubectl get namespace | grep -w "aiops")
if [[ $nmspace == "" ]]
then
	printf "Creating namespace aiops\n"
	kubectl create namespace aiops
fi


metric_addons_status=$(minikube addons list | grep "metrics-server" | awk -F ' ' '{print $6}')


if [[ $metric_addons_status != "enabled" ]]
then
	minikube addons enable metrics-server
fi


kubectl apply -f rbc.yaml


if [[ $cloud == "0" ]]
then

    echo "Enter your User name (In small cases): "
    read local_user
    printf "Installing Elasticsearch"
    helm install elasticsearch elastic --values elastic/values.yaml -n aiops
    
    #**************************************************************************************************************
    #**************************************************************************************************************
	OUTPUT="atul"
	while [[ $OUTPUT == "atul" ]]
	do
		OUT=()
		mapfile -t OUT < <( kubectl exec -it -n aiops elasticsearch-0  -- bin/elasticsearch-setup-passwords auto -b )
	
		if [[ ${OUT[1]} == *"PASSWORD"* ]]
		then
			OUTPUT=${OUT[1]}
			break
		fi

	done
	echo "*******************************************************************"
		echo " all string is : ${OUT[-2]}"	
	echo "*******************************************************************"
	OIFS=$IFS
	IFS=' '
	mails2=${OUT[-2]}


	es_user=$(echo $mails2 | awk '{print $2}')
	es_password=$(echo $mails2 | awk '{print $4}')
	es_password=${es_password//[[:space:]]}
	echo "*******************************************************************" 

	echo "ES_USER is : $es_user"
	echo "ES_PASSWORD is : $es_password"
#	printf '%s\n' "${text//[[:space:]]}"

	echo "*******************************************************************"

	IFS=$OIFS 						#Run a loop untill we get es_user and es_password then proceed to next line
    #**************************************************************************************************************
    #**************************************************************************************************************
    
    kubectl delete secret elasticsearch-pw-elastic -n aiops
    
    kubectl create secret generic elasticsearch-pw-elastic -n aiops --from-literal password=$es_password
    helm install kibana kibana/ --values kibana/values.yaml --namespace aiops
        
    if [[ $log == "1" ]]
    then
        printf "Deploying Logcollector"
        helm install log logcollector/ --values logcollector/values.yaml --namespace aiops --set env.cloudUserValue=$es_user --set env.cloudPasswordValue=$es_password --set env.esUserValue=$system_name --set env.podLogIndexValue=$local_user --set env.eventLogIndexValue=$local_user
    fi
    
    if [[ $metric == "1" ]]
    then
        printf "Deploying Metriccollector"

	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install --namespace aiops node-exporter prometheus-community/prometheus-node-exporter


        helm install metric metriccollector/ --values metriccollector/values.yaml --namespace aiops --set env.cloudUserValue=$es_user --set env.cloudPasswordValue=$es_password --set env.esUserValue=$system_name --set env.metricLogIndexValue=$local_user --set env.prometheusLogIndexValue=$local_user
    fi        
    
    if [[ $log == "0" && $metric == "0" ]]
    then
        printf "Deploying Logcollector and Metriccollector"
        helm install log logcollector/ --values logcollector/values.yaml --namespace=aiops --set env.cloudUserValue=$es_user --set env.cloudPasswordValue=$es_password --set env.esUserValue=$system_name --set env.podLogIndexValue=$local_user --set env.eventLogIndexValue=$local_user

	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install --namespace aiops node-exporter prometheus-community/prometheus-node-exporter
	
        helm install metric metriccollector/ --values metriccollector/values.yaml --namespace aiops --set env.cloudUserValue=$es_user --set env.cloudPasswordValue=$es_password --set env.esUserValue=$system_name --set env.metricLogIndexValue=$local_user --set env.prometheusLogIndexValue=$local_user
    fi
    
    
else 
    if [[ $cloud_id == "0" || $cloud_user=="0" || $cloud_password=="0" ]]
    then
	if [[ $cloud_id == "0" ]]
	then 
		echo "Cloud ID cannot be empty, please enter cloud ID : "
		read cloud_id	
	fi
	
	if [[ $cloud_user == "0" ]]
	then 
		echo "Cloud User cannot be empty, please enter cloud User : "
		read cloud_user	
	fi

        if [[ $cloud_password == "0" ]]
	then 
		echo "Cloud Password cannot be empty, please enter cloud Password : "
		read cloud_password	
	fi

    fi



    if [[ $kibana == "1" ]]
    then
        printf "Deploying Kibana"
        kubectl delete secret elasticsearch-pw-elastic -n aiops
        kubectl create secret generic elasticsearch-pw-elastic -n aiops --from-literal password=$cloud_password
        helm install kibana kibana/ --values kibana/values.yaml --namespace aiops --set esurl=$cloud_id --set esuser=$cloud_user
    fi
    
    if [[ $log == "1" ]]
    then
        printf "Deploying Logcollector"
        helm install log logcollector/ --values logcollector/values.yaml --namespace aiops --set env.cloudIdValue=$cloud_id --set env.cloudUserValue=$cloud_user --set env.cloudPasswordValue=$cloud_password --set env.esUserValue=$system_name --set env.podLogIndexValue=$cloud_user --set env.eventLogIndexValue=$cloud_user --set env.cloudValue="cloud"
    fi
    
    if [[ $metric == "1" ]]
    then
        printf "Deploying Metriccollector"

	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install --namespace aiops node-exporter prometheus-community/prometheus-node-exporter

        helm install metric metriccollector/ --values metriccollector/values.yaml --namespace aiops --set env.cloudIdValue=$cloud_id --set env.cloudUserValue=$cloud_user --set env.cloudPasswordValue=$cloud_password --set env.esUserValue=$system_name --set env.metricLogIndexValue=$cloud_user --set env.prometheusLogIndexValue=$cloud_user --set env.cloudValue="cloud"
    fi        
    
    if [[ $log == "0" && $metric == "0" ]]
    then
        printf "Deploying Logcollector and Metriccollector"
        helm install log logcollector/ --values logcollector/values.yaml --namespace aiops  --set env.cloudIdValue=$cloud_id  --set env.cloudUserValue=$cloud_user  --set env.cloudPasswordValue=$cloud_password --set env.esUserValue=$system_name --set env.podLogIndexValue=$cloud_user --set env.eventLogIndexValue=$cloud_user --set env.cloudValue="cloud"

	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install --namespace aiops node-exporter prometheus-community/prometheus-node-exporter	
	
        helm install metric metriccollector/ --values metriccollector/values.yaml --namespace aiops --set env.cloudIdValue=$cloud_id --set env.cloudUserValue=$cloud_user  --set env.cloudPasswordValue=$cloud_password --set env.esUserValue=$system_name --set env.metricLogIndexValue=$cloud_user --set env.prometheusLogIndexValue=$cloud_user --set env.cloudValue="cloud"
    fi
    
fi
    
    
