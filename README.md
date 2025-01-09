
# Train Ticket：A Benchmark Microservice System
# <img src="./image/logo.png">


The project is a train ticket booking system based on microservice architecture which contains 41 microservices. The programming languages and frameworks it used are as below.
- Java - Spring Boot, Spring Cloud
- Node.js - Express
- Python - Django
- Go - Webgo
- DB - Mongo、MySQL

You can get more details at [Wiki Pages](https://github.com/FudanSELab/train-ticket/wiki).

## Service Architecture Graph
![architecture](./image/2.png)

## Quick Start
We provide k8s deployment to quickly deploy our application:  [Using Kubernetes](#Using-Kubernetes).

### Using Kubernetes
Here is the steps to deploy the Train Ticket onto any existing Kubernetes cluster.

#### Presequisite
* An existing Kubernetes cluster
* Helm supported, you can see https://helm.sh/docs/helm/helm_install/ for helm install
* PVC supported, you can see https://openebs.io/docs/2.12.x/user-guides/installation for localPV support.

#### 1. Clone the Repository
```bash
git clone --depth=1 https://github.com/FudanSELab/train-ticket.git 
cd train-ticket/
```

#### 2. Setup LocalPV with openebs
```bash
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### 2. Deploy the application
### For Quick Start
```bash
./deploy namespace # Replace namespace with your chosen namespace, or leave blank for default

```


### Reset Deployment
```
make reset-deploy
# if you specify namespace when deploy, set namespace as well when reset
# make reset-deploy Namespace=yournamespace
``
Then, delete the namespace with kubectl:
```bash
kubectl delete namespace your_namespace
```