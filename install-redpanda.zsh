helm repo add jetstack https://charts.jetstack.io && \
helm repo update && \
helm install \
cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--version v1.2.0 \
--set installCRDs=true

sleep 5

brew install redpanda-data/tap/redpanda

sleep 5

helm repo add redpanda https://charts.vectorized.io/ && helm repo update

sleep 5

export VERSION=$(curl -s https://api.github.com/repos/redpanda-data/redpanda/releases/latest | jq -r .tag_name)

# For zsh:
# kubectl apply \
#     -k https://github.com/redpanda-data/redpanda/src/go/k8s/config/crd?ref=$VERSION
kubectl apply \
    -k https://github.com/redpanda-data/redpanda/src/go/k8s/config/crd

helm install \
    redpanda-operator \
    redpanda/redpanda-operator \
    --namespace redpanda-system \
    --create-namespace \
    --version $VERSION

kubectl create ns panda-chat
# inject istio into panda-chat namespace
kubectl label namespace panda-chat istio-injection=enabled

# CA_KEY=$(cat .certs/rootCA-key.pem |base64)
# CA_CERT=$(cat .certs/rootCA.pem|base64)
# echo """apiVersion: v1
# kind: Secret
# metadata:
#   name: ca-key-pair
#   namespace: panda-chat
# data:
#   tls.crt: ${CA_CERT}
#   tls.key: ${CA_KEY}""" > redpanda/cert_issuer_secret.yaml

# kubectl apply -f redpanda/cert_issuer_secret.yaml

# echo """apiVersion: cert-manager.io/v1
# kind: Issuer
# metadata:
#   name: ca-issuer
#   namespace: panda-chat
# spec:
#   ca:
#     secretName: ca-key-pair""" > redpanda/cert_issuer.yaml

# kubectl apply -f redpanda/cert_issuer.yaml
# kubectl get issuers ca-issuer -n panda-chat -o wide

echo "Waiting 20 seconds before standing up the redpanda cluster..."
sleep 10
echo "If the next command fails then try running it again manually, sometimes the system isn't ready."
# certificate creaton for SSL/TLS termination
# echo "Setting up local TLS"
# kubectl -n panda-chat create secret tls tls-secret --key=.certs/key.pem --cert=.certs/cert.pem


kubectl apply \
    -n panda-chat \
    -f redpanda/redpanda_cluster_tls_external.yaml


echo "Add this line to /etc/hosts file"
echo "127.0.0.1 0.local.rp"

echo "\nWait a minute whilst the cluster gets ready and then try some of these commands..."

echo "> rpk topic create panda-chat -p 5 --brokers localhost:30001"
echo "> rpk topic produce panda-chat --brokers localhost:30001"
echo "> rpk topic consume panda-chat --brokers localhost:30001"
echo "> rpk topic list --brokers localhost:30001"