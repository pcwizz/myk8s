#!/bin/env bash

# Deploys everything to k8s
ingressNginxVersion='0.30.0'
certManagerVersion='0.14.1'

kubectl apply -f \
	https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-$ingressNginxVersion/deploy/static/mandatory.yaml

kubectl apply -f \
	https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-$ingressNginxVersion/deploy/static/provider/cloud-generic.yaml

lbip="\n"
while [ "$lbip" = "\n" ];
do
	sleep 1
	lbip=$(kubectl get svc --namespace=ingress-nginx -o json |
		jq '.items[0].status.loadBalancer.ingress[0].ip' | sed -E 's/"(.+)"/\1/')
done

doctl -o json compute domain records list pcwizz.net | \
	jq -e '.[]|select(.name=="testing")|select(.type=="A")'

if [[ $? -ne 0 ]]; then
	doctl compute domain records create pcwizz.net \
		--record-name testing \
		--record-type A \
		--record-data ${lbip} --
fi

kubectl create namespace cert-manager
kubectl apply -f \
	https://github.com/jetstack/cert-manager/releases/download/v$certManagerVersion/cert-manager.yaml

kubectl apply -f manifests/issuer.yaml
kubectl apply -f manifests/echo.yaml
