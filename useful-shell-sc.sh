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

