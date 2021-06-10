.PHONY: bootstrap kube-create-cluster kube-secret kube-delete-cluster kube-deploy-cluster kube-validate kube-config \
namespace-up namespace-down ssh-gen install-deps install-aws install-docker install-helm install-kops install-tf \
acw-namespace-up acw-fluentd

bootstrap:
	cd bootstrap && terraform init
	cd bootstrap && terraform apply --auto-approve
	
install-deps:
	sudo apt install vim curl wget unzip tar jq -y
	sudo snap install kubectl --classic

install-aws:
	cd /tmp && \
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
	unzip awscliv2.zip && \
	sudo ./aws/install

install-helm:
	cd /tmp && \
	wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz && \
	tar -zxvf helm-v3.6.0-linux-amd64.tar.gz && \
	sudo mv linux-amd64/helm /usr/local/bin/helm

install-kops:
	cd /tmp && \
	curl -LO https://github.com/kubernetes/kops/releases/download/v1.18.0/kops-linux-amd64 && \
	chmod +x kops-linux-amd64 && \
	sudo mv kops-linux-amd64 /usr/local/bin/kops

install-tf:
	cd /tmp && \
	wget https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip && \
	unzip terraform_0.15.4_linux_amd64.zip && \
	sudo mv terraform /usr/local/bin

########
# KOPS
########

kube-create-cluster:
	kops create cluster --state=s3://$(shell cd bootstrap && terraform output kops_state_bucket_name) --name=rmit.k8s.local --zones="us-east-1a,us-east-1b" --master-size=t2.small --node-size=t2.small --node-count=1 --yes

kube-secret:
	kops create secret --state=s3://$(shell cd bootstrap && terraform output kops_state_bucket_name) --name rmit.k8s.local sshpublickey admin -i ~/keys/ec2-key.pub

kube-delete-cluster:
	aws iam detach-role-policy --role-name nodes.rmit.k8s.local --policy-arn arn:aws:iam::aws:policy/AdministratorAccess | echo "hack"
	kops delete cluster --state=s3://$(shell cd bootstrap && terraform output kops_state_bucket_name) rmit.k8s.local --yes

kube-deploy-cluster:
	kops update cluster --state=s3://$(shell cd bootstrap && terraform output kops_state_bucket_name) rmit.k8s.local --yes
	aws iam attach-role-policy --role-name nodes.rmit.k8s.local --policy-arn arn:aws:iam::aws:policy/AdministratorAccess | echo "Hack"

kube-validate:
	kops validate cluster --state=s3://$(shell cd bootstrap && terraform output kops_state_bucket_name)

kube-config:
	kops export kubecfg --state=s3://$(shell cd bootstrap && terraform output kops_state_bucket_name)

#######
# Kubernetes
#######

namespace-up:
	kubectl create namespace test
	kubectl create namespace prod

namespace-down:
	kubectl delete namespace test
	kubectl delete namespace prod

########
# SSH
########

ssh-gen:
	mkdir -p ~/keys
	yes | ssh-keygen -t rsa -b 4096 -f ~/keys/ec2-key -P ''
	chmod 0644 ~/keys/ec2-key.pub
	chmod 0600 ~/keys/ec2-key

########
# Logging
########

acw-namespace-up:
	kubectl create namespace amazon-cloudwatch
	kubectl get namespaces

acw-fluentd:
	aws iam attach-role-policy --role-name nodes.rmit.k8s.local --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
	kubectl create configmap cluster-info --from-literal=cluster.name=rmit.k8s.local --from-literal=logs.region=us-east-1 -n amazon-cloudwatch
	wget https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluentd/fluentd.yaml
	kubectl apply -f fluentd.yaml