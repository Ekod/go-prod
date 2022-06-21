SHELL := /bin/bash
# ==============================================================================
# Testing running system

# expvarmon -ports=":4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"
# hey -m GET -c 100 -n 10000 -H "Authorization: Bearer ${TOKEN}" http://localhost:3000/v1/test

# Testing auth
# curl -H "Authorization: Bearer ${TOKEN}" http://localhost:3000/v1/testauth

# To generate a private/public key PEM file.
# openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048
# openssl rsa -pubout -in private.pem -out public.pem


run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go
	
tidy:
	go mod tidy
	go mod vendor
	go fmt ./...

# ==============================================================================
#Environment setup
dev.setup.mac:
	brew update
	brew list kind || brew install kind
	brew list kubectl || brew install kubectl
	brew list kustomize || brew install kustomize

dev.setup.win:
	choco list kind || choco install kind -y
	choco list kubectl || choco install kubectl -y
	choco list kustomize || choco install kustomize -y

# ==============================================================================
# Building containers

VERSION := 1.0

all: sales-api

sales-api:
	docker build \
		-f zarf/docker/dockerfile.sales-api \
		-t sales-api-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.
# ==============================================================================
# Running from within k8s/kind

KIND_CLUSTER := sales-cluster

kind-up:
	kind create cluster \
		--image kindest/node:v1.23.0@sha256:49824ab1727c04e56a21a5d8372a402fcd32ea51ac96a2706a12af38934f81ac \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml
	kubectl config set-context --current --namespace=sales-system

d:
	kind delete cluster --name $(KIND_CLUSTER)

kind-load:
	cd zarf/k8s/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-amd64:$(VERSION)
	kind load docker-image sales-api-amd64:$(VERSION) --name $(KIND_CLUSTER)

kind-apply:
	kustomize build zarf/k8s/kind/database-pod | kubectl apply -f -
	kubectl wait --namespace=database-system --timeout=120s --for=condition=Available deployment/database-pod
	kustomize build zarf/k8s/kind/sales-pod | kubectl apply -f -

kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

kind-status-sales:
	kubectl get pods -o wide --watch --namespace=sales-system

kind-status-db:
	kubectl get pods -o wide --watch --namespace=database-system

kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 | go run app/tooling/logfmt/main.go

kind-restart:
	kubectl rollout restart deployment sales-pod

kind-update-apply: all kind-load kind-apply

kind-update: all kind-load kind-restart

u: all kind-up kind-load kind-apply

admin:
	go run app/tooling/sales-admin/main.go

# ==============================================================================
# Running tests within the local computer

test:
	go test ./... -count=1
	staticcheck -checks=all ./...