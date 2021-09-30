#!/bin/bash
log="0"
metric="0"
elastic="0"
kibana="0"
while getopts lmek flag
do
    case "${flag}" in
       l) log="1";;
        m) metric="1";;
        e) elastic="1";;
	k) kibana="1";;
    esac
done


if [[ $log == "1" || $metric == "1" || $elastic == "1" || $kibana == "1" ]]
then
	if [[ $log == "1" ]]
	then 
		helm_list=$(helm ls -n aiops | awk '/log/{sub(/.logcollector/, ""); print $1}')
		if [[ $helm_list == "log" ]]
		then
			helm uninstall log -n aiops
		fi
	fi

	if [[ $metric == "1" ]]
	then 
		helm_list=$(helm ls -n aiops | awk '/metric/{sub(/.metriccollector/, ""); print $1}')
		if [[ $helm_list == "metric" ]]
		then
			helm uninstall metric -n aiops
			helm uninstall node-exporter -n aiops
		fi
	fi


	if [[ $kibana == "1" ]]
	then 
		helm_list=$(helm ls -n aiops | awk '/kibana/{sub(/.kibana/, ""); print $1}')
		if [[ $helm_list == "kibana" ]]
		then
			helm uninstall kibana -n aiops
		fi
	fi
	
	if [[ $elastic == "1" ]]
	then 
		helm_list=$(helm ls -n aiops | awk '/elastic/{sub(/.elastic/, ""); print $1}')
		if [[ $helm_list == "elastic" ]]
		then
			helm uninstall elastic -n aiops
		fi
	fi
	
else	
	declare -a helm_list
	helm_list=($(helm ls -n aiops | awk '{print $1}'))
	ar_len=${#helm_list[@]}
	for (( i=1; i<$ar_len; i++))
	do	
		if [[ "${helm_list[$i]}" == "log" || "${helm_list[$i]}" == "metric" || "${helm_list[$i]}" == "elastic" || "${helm_list[$i]}" == "node-exporter" || "${helm_list[$i]}" == "kibana" ]]
		then
			helm uninstall ${helm_list[$i]} -n aiops
		fi
	done
fi
