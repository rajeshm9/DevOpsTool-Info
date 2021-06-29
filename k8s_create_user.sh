#!/bin/bash
USER="rm9"
K8S_SERVER="https://xx.xx.xx.xx:443"
CA_CERT_PATH="/tmp/ca.crt"
openssl genrsa -out ${USER}.key 2048
openssl req -new -key ${USER}.key -out ${USER}.csr -subj "/CN=${USER}"
cat ${USER}.csr | base64 | tr -d "\n" > ${USER}.base64.csr
#apiVersion: certificates.k8s.io/v1
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USER}
spec:
  groups:
  - system:authenticated  
  request: $(cat ${USER}.base64.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
echo "== Get CSR Request =="
kubectl get certificatesigningrequests
echo "== Approve Request =="
kubectl certificate approve ${USER}
echo "== List Certs Request =="
kubectl get certificatesigningrequests ${USER}
echo "==  Get Certs File =="
kubectl get certificatesigningrequests ${USER}  -o jsonpath='{ .status.certificate }'  | base64 --decode > ${USER}.crt
openssl x509 -in  ${USER}.crt -text -noout |head -n 20

rm ${USER}.conf
kubectl config set-cluster ${USER}-cluster --server=${K8S_SERVER} --certificate-authority=${CA_CERT_PATH} --embed-certs=true --kubeconfig=${USER}.conf
kubectl config set-credentials ${USER}  --client-key=${USER}.key --client-certificate=${USER}.crt  --embed-certs=true  --kubeconfig=${USER}.conf
kubectl config set-context ${USER}@${USER}-cluster --cluster=${USER}-cluster --user=${USER}  --kubeconfig=${USER}.conf
kubectl config set current-context  ${USER}@${USER}-cluster 
kubectl config view --kubeconfig=${USER}.conf


#
#
#
