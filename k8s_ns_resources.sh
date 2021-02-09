#!/bin/bash

# We can pass config file as parameter else default path will be picked
if [ $# -eq 1 ]
then
    export KUBECONFIG="${1}"
else
    export KUBECONFIG="`echo ~`/.kube/config"
    
fi

function cpu_format
{
    input=$1
    if [[ `echo  $input |grep -c "m"` -eq 1 ]]
    then
        printf "%.3f" $(echo $(echo ${input} |sed -e "s/m//g")/1000  |bc -l )  
    elif [[ -z $input ]]
    then
        echo "0"
    else
        printf "%d" $input
    fi
}
function mem_format
{
    input=$1
    
    if [[ `echo  $input |egrep -c "M"` -eq 1 ]]
    then
        printf "%.3f" $(echo $(echo ${input} |sed -e "s/Mi//g" -e "s/M//g")/1000  |bc -l )  
    elif [[ `echo  $input |grep -c "Gi"` -eq 1 ]]    
    then
        printf "%.3f" $(echo $(echo ${input} |sed -e "s/Gi//g")  |bc -l )  
    elif [[ -z $input ]]
    then
        echo "0"
    else
        printf "%d" $input
    fi

}

total_cpu_req=0
total_cpu_limit=0
total_mem_req=0
total_mem_limit=0
NAMESPACE="--all-namespaces"

echo "NameSpace|PodName|ContainerName|Cpu_Req|Cpu_Limit|Mem_Req|Mem_Limit"
for x in `kubectl get po ${NAMESPACE}  -o=jsonpath="{range .items[*]}{.metadata.namespace}|{.metadata.name}{'\n'}{end}"`
do
    namespace=`echo $x|cut -d "|" -f1`
    pod_name=`echo $x|cut -d "|" -f2`

    for y in `kubectl get pod ${pod_name} -n ${namespace}  -o jsonpath="{range .spec.containers[*]}{.name}|{.resources.requests.cpu}|{.resources.limits.cpu}|{.resources.requests.memory}|{.resources.limits.memory}{'\n'}{end}"`
    do
        container_name=`echo $y|cut -d "|" -f1`
        cpu_request=`cpu_format $(echo $y|cut -d "|" -f2)`
        cpu_limit=`cpu_format $(echo $y|cut -d "|" -f3)`
        mem_request=`mem_format $(echo $y|cut -d "|" -f4)`
        mem_limit=`mem_format $(echo $y|cut -d "|" -f5)`

        total_cpu_req=$(echo ${total_cpu_req} + ${cpu_request} |bc -l)
        total_cpu_limit=$(echo ${total_cpu_limit} + ${cpu_limit}|bc -l)

        total_mem_req=$(echo ${total_mem_req} + ${mem_request} |bc -l)
        total_mem_limit=$(echo ${total_mem_limit} + ${mem_limit} |bc -l)

        echo "${namespace}|${pod_name}|${container_name}|${cpu_request}|${cpu_limit}|${mem_request}|${mem_limit}"
    done

done
echo "NameSpace|PodName|ContainerName|${total_cpu_req}|${total_cpu_limit}|${total_mem_req}|${total_mem_limit}"
