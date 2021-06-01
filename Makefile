.PHONY: bootstrap kube-create-cluster kube-secret kube-delete-cluster kube-deploy-cluster kube-validate kube-config \
namespace-up namespace-down ssh-gen install-deps install-aws install-docker install-kops install-tf pack

bootstrap:
	cd bootstrap && terraform init
	cd bootstrap && terraform apply --auto-approve
	
install-deps:
	sudo apt install vim curl wget unzip tar -y

install-aws:
	cd /tmp && \
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
	unzip awscliv2.zip && \
	sudo ./aws/install

install-docker:
	sudo apt install docker.io -y
	sudo systemctl start docker
	sudo systemctl enable docker
	cd /tmp && \
	sudo curl -L "https://github.com/docker/compose/releases/download/1.28.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
	sudo chmod +x /usr/local/bin/docker-compose
	sudo usermod -aG docker $(USER)
	echo "Please restart your system for Docker to work"

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

pack:
	cd src/ && \
	docker build . -t todoapp:latest

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

namespace-down:

########
# SSH
########

ssh-gen:
	mkdir -p ~/keys
	yes | ssh-keygen -t rsa -b 4096 -f ~/keys/ec2-key -P ''
	chmod 0644 ~/keys/ec2-key.pub
	chmod 0600 ~/keys/ec2-key