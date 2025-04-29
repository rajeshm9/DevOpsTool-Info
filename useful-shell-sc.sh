############ check remote port status ############
< /dev/tcp/<ip_addr>/<port_no> && echo Port is open || echo Port is closed

############ Extact substring using grep ############
ehco key="121"
grep -oP 'key="\K[^"]+'

############ Get all Running pod from particular namespace ############
kubectl get pod -n <namespace> --field-selector=status.phase==Running -o jsonpath="{.items[0].metadata.name}

############ Failed Pod  ############
kubectl get pod -n <namespace> |egrep -v 'Running|Completed'

############ Kubectl api List ############
for apipath in $(kubectl api-versions | sort | sed '/\//{H;1h;$!d;x}'); do
  version=${apipath#*/}
  api=${apipath%$version}
  api=${api%/}
  prefix="/api${api:+s}/"
  api=${api:-(core)}
  >&2 echo "${prefix}${apipath}: ${api}/${version}"
  kubectl get --raw "${prefix}${apipath}" | jq -r --arg api "${api}/${version}" '.resources | sort_by(.name) | .[]? | "| \($api) | \(.name) | \(.verbs | join(" ")) | \(.kind) | \(if .namespaced then "true" else "false" end) |"'
done
`"

############ Get all Pod logs in one namespace #########
NS=${NS:-${1}}

for pod in $(kubectl get pods -n ${NS} -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
do
    #depending on logs, this may take a while
    echo "== Fetching Logs ${pod} ==="
    kubectl logs $pod -n ${NS} > $pod.txt 2>&1
    if [ $? -ne 0 ]
    then
           for x in $(cat "${pod}.txt" |grep -o "\[.*\]" |cut -d "]" -f1 |tr -d "[")
           do
                   kubectl logs $pod -c ${x} -n ${NS} > ${x}-${pod}.txt 2>&1
           done
        rm ${pod}.txt
    fi
done

############ Delete Namespace in Terminating Status #########
(
NAMESPACE=test
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
)

############ Update cert-manager certificate #########
k_update() {
    kubectl -n $1 get certs --no-headers=true | awk '{print $1}' | xargs -n 1 kubectl -n $1 patch certificate --patch '
- op: replace
  path: /spec/renewBefore
  value: 1440h
' --type=json
}

k_remove() {
kubectl -n $1 get certs --no-headers=true | awk '{print $1}' | xargs -n 1 kubectl -n $1 patch certificate --patch '
- op: remove
  path: /spec/renewBefore
' --type=json
}


# operation is $1
operation=$1
# if operation is not set, default to update
if [ -z "$operation" ]; then
    operation="update"
fi


for ns in $(kubectl get ns --no-headers  | awk '{print $1}');
do
    if [ "$operation" == "update" ]; then
        k_update $ns
    elif [ "$operation" == "remove" ]; then
        k_remove $ns
    else
        echo "Invalid operation: $operation"
        exit 1
    fi
done
######## Error Pod List ############
kubectl get pod -A |grep  -vi completed |egrep -v "1/1|2/2|3/3|4/4|5/5"
