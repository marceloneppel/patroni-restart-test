.PHONY: pebble supervisord

dependencies:
	sudo apt-get update
	sudo apt-get install -y curl gettext-base
	sudo snap install --classic microk8s
	sudo adduser ${USER} microk8s
	sudo microk8s status --wait-ready
	sudo microk8s enable storage dns ingress
	sudo microk8s disable rbac
	sudo snap alias microk8s.kubectl kubectl

clean:
	docker rmi test-pebble -f
	kubectl delete namespace pebble --ignore-not-found=true

build:
	docker build -t test-pebble pebble
	docker save test-pebble | microk8s ctr images import -

pebble: build
	kubectl create namespace pebble
	IMAGE=test-pebble envsubst < k8s.yaml | kubectl apply -n pebble -f -