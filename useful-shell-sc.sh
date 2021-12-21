# Extact substring using grep
# ehco key="121"
grep -oP 'key="\K[^"]+'

# Get all Running pod from particular namespace
kubectl get pod -n <namespace> --field-selector=status.phase==Running -o jsonpath="{.items[0].metadata.name}

# Failed Pod 
kubectl get pod -n <namespace> |egrep -v 'Running|Completed'
