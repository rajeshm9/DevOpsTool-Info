# Extact substring using grep
# ehco key="121"
grep -oP 'key="\K[^"]+'

# Get all Running pod from particular namespace
kubectl get pod -n <namespace> --field-selector=status.phase==Running -o jsonpath="{.items[0].metadata.name}

# Failed Pod 
kubectl get pod -n <namespace> |egrep -v 'Running|Completed'

# Kubectl api List
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

