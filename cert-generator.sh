#!/bin/bash

# Solution found here:
# https://itnext.io/deploying-tls-certificates-for-local-development-and-production-using-kubernetes-cert-manager-9ab46abdd569
# you need to install mkcert: https://github.com/FiloSottile/mkcert
# brew install mkcert
echo "Creating self-signed CA certificates for TLS and installing them in the local trust stores"
CA_CERTS_FOLDER=$(pwd)/.certs
# This requires mkcert to be installed/available
echo ${CA_CERTS_FOLDER}
rm -rf ${CA_CERTS_FOLDER}
mkdir -p ${CA_CERTS_FOLDER}/${ENVIRONMENT_DEV}
# The CAROOT env variable is used by mkcert to determine where to read/write files
# Reference: https://github.com/FiloSottile/mkcert
CAROOT=${CA_CERTS_FOLDER}/${ENVIRONMENT_DEV} mkcert -install

echo "Creating K8S secrets with the CA private keys (will be used by the cert-manager CA Issuer)"
mkcert -key-file=.certs/key.pem -cert-file=.certs/cert.pem 'fe.sso.kidsloop.live'
