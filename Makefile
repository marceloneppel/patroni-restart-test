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
	docker rmi test-supervisord -f
	kubectl delete -f k8s.yaml --ignore-not-found=true
	kubectl delete service/patronidemo-config --ignore-not-found=true
	kubectl delete namespace pebble --ignore-not-found=true
	kubectl delete namespace supervisord --ignore-not-found=true

build:
	docker build -t test-patroni patroni
	docker build -t test-pebble pebble
	docker build -t test-supervisord supervisord
	docker save test-patroni | microk8s ctr images import -
	docker save test-pebble | microk8s ctr images import -
	docker save test-supervisord | microk8s ctr images import -

pebble: build
	kubectl create namespace pebble
	IMAGE=test-pebble envsubst < k8s.yaml | kubectl apply -n pebble -f -

supervisord: build
	kubectl create namespace supervisord
	IMAGE=test-supervisord envsubst < k8s.yaml | kubectl apply -n supervisord -f -