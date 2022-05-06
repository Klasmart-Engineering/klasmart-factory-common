#!/bin/bash

set -e

ISTIO_VERSION=1.13.3

brew install jq

# deploy k3d cluster with extra memory (8G) for Istio install
k3d cluster create local-cluster \
  --k3s-arg "--disable=traefik@server:0" \
  --image rancher/k3s:v1.20.15-k3s1 \
  --api-port 6443 \
  --port 8080:80@loadbalancer \
  --port 8081:443@loadbalancer \
  --port 30001:30001@loadbalancer \
  --agents-memory=4G \
  --registry-create local-registry \
  --volume "$PWD"/backup:/tmp/backup

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH

#https://istio.io/latest/docs/setup/install/operator/
#install istio operator:
#    NOTE: above command runs the operator by creating the following resources in the istio-operator namespace:
#    - The operator custom resource definition
#    - The operator controller deployment
#    - A service to access operator metrics
#    - Necessary Istio operator RBAC rules

istioctl operator init

#https://istio.io/latest/docs/setup/install/operator/
# deploy Istio default configuration profile using the operator, run the following command:
#     the default profile…
#     Ingress Gateway is enabled
#     Istiod is enabled


# https://github.com/istio/istio/issues/36762
# For M1 macs: default istio operator and envoy do not work well.
# A workaround seems to be to use the querycap istio instead

kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: default-istiocontrolplane
spec:
  # profile: default
  hub: docker.io/querycapistio
  meshConfig:
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
    # Enable passthrough traffic? Set to ALLOW_ANY or REGISTRY_ONLY, default: ALLOW_ANY
      mode: REGISTRY_ONLY
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
  components:
    cni:
      enabled: false

EOF
echo "Waiting for Istio to be ready..."
sleep 15

# inject istio into default namespace
kubectl label namespace default istio-injection=enabled

# certificate creaton for SSL/TLS termination
echo "Setting up local TLS"
kubectl -n istio-system create secret tls kidsloop-local-tls-secret --key=.certs/key.pem --cert=.certs/cert.pem

echo "Cluster ready..."

./install-redpanda.zsh