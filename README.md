# Task13 Jenkins Pipeline для мульти-платформенної параметризованої збірки

## Підготовка середовища розробки
1. Створимо Kubernetes кластер на локальному комп'ютері
- Встановіть Kind: [Kind](https://kind.sigs.k8s.io/) - це інструмент, який дозволяє створювати та керувати локальними кластерами Kubernetes за допомогою «вузлів» контейнера Docker. Був розроблений для тестування самого Kubernetes, але може використовуватися для локальної розробки або CI.

```sh
$ curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
$ chmod +x ./kind
$ sudo mv ./kind /usr/local/bin/kind
$ kind version
kind v0.11.1 go1.16.4 linux/amd64
```
- Створимо кластер
```sh
$ kind create cluster --name jenkins
Creating cluster "jenkins" ...
 ✓ Ensuring node image (kindest/node:v1.21.1) 🖼 
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-jenkins"
You can now use your cluster with:

$ kubectl cluster-info --context kind-jenkins
Kubernetes control plane is running at https://127.0.0.1:42303
CoreDNS is running at https://127.0.0.1:42303/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

$ kubectl config set-context --current --namespace=default
Context "kind-jenkins" modified
```
2. Встановіть Jenkins на кластер Kubernetes за допомогою Helm
```sh
$ helm repo add jenkinsci https://charts.jenkins.io/
$ helm repo update
$ helm install jenkins jenkinsci/jenkins
```

3. Після запуску Jenkins отримайте доступ до інтерфейсу користувача Jenkins
```sh
$ kubectl exec --namespace default -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
ddKNLSgScCElXRyfMFbexv

$ kubectl --namespace default port-forward svc/jenkins 8080:8080&
```