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
4. Забезпечимо доступ Jenkins до HitHub
- Згенеруємо  на локальному комп'ютері   
```sh
$ ssh-keygen
Generating public/private rsa key pair.
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
# Публічний
$ cat ~/.ssh/id_rsa.pub
# Приватний 
$ cat ~/.ssh/id_rsa
```
- Додамо публічну частину ключа до Deploy keys для [репозиторію з застосунком](https://github.com/vit-um/kbot/settings/keys)  
-  Поставте прапорець "Allow write access" (Дозволити запис) якщо вам потрібен доступ для запису. 
- Увійдіть до Jenkins і відкрийте налаштування вашого проекту. 
- У секції "Source Code Management" (Управління вихідним кодом) виберіть "Git". 
- У полі "Repository URL" (URL репозиторію) введіть URL вашого репозиторію GitHub. 
- В розділі "Credentials" (Облікові дані) виберіть "Add" (Додати) для додавання нових облікових даних. 
- Виберіть тип облікових даних "SSH Username with private key" (SSH-користувач з приватним ключем). 
- У полі "Private Key" (Приватний ключ) вставте ваш приватний ключ SSH. Ви можете взяти його з файлу  ~/.ssh/id_rsa  на вашому локальному комп'ютері. 
- Введіть назву для цих облікових даних і натисніть "Add" (Додати) для збереження. 
- Виберіть створені вами облікові дані в розділі "Credentials" (Облікові дані). 
- Вкажемо шлях до скрипту, який ми підготували у полі Script Path `/pipeline/jenkins.groovy`
- Збережіть налаштування проекту. 

