# Task12 GitHub Actions 

## Підготуємо Makefile для роботи з репозиторієм Google

1. Додамо новий проект на [Google Cloud](https://console.cloud.google.com/projectcreate) з назвою `vit-um` та переключаємось на нього:  

2. Дозволяємо Google Container Registry API(https://console.cloud.google.com/marketplace/product/google/containerregistry.googleapis.com?project=kbot-407613)

3. Змінюємо в `Makefile` назву репозиторію на 
```Makefile
REGESTRY := ghcr.io/vit-um
```
4. Створимо імідж контейнеру нашого застосунку:
```sh
$ make image                
docker build . -t ghcr.io/vit-um/kbot:v.CICD-38f501f-amd64  --build-arg TARGETARCH=amd64 

$ docker images
REPOSITORY         TAG                   IMAGE ID       CREATED             SIZE
gcr.io/vit-um/kbot v.CICD-38f501f-amd64  6643b9fb35f3   About an hour ago   11.3MB

$ docker rmi -f 6643b9fb35f3
Untagged: gcr.io/vit-um/kbot:v.CICD-38f501f-amd64
Deleted: sha256:6643b9fb35f3ffdeaac5e287bc4ee556fc8cc2981513a0f840fc767686beb805

$ git tag v1.3.0
$ git push --tags origin
$ git checkout -b develop
Switched to a new branch 'develop'

$ git push --set-upstream origin develop
Branch 'develop' set up to track remote branch 'develop' from 'origin'.
Everything up-to-date
```

5. Для доступу до Container Registry ghcr.io вам необхідно виконати наступні кроки:
- Створити персональний токен в своєму профілі на GitHub. Для цього перейдіть у налаштування свого профілю, виберіть "Developer settings", а потім "Personal access tokens". Натисніть на кнопку "Generate new token" та виберіть необхідні права доступу для токена.

- Додати токен доступу до налаштувань репозиторію, в якому ви хочете використовувати Container Registry ghcr.io. Для цього перейдіть у налаштування репозиторію, виберіть "Secrets" та натисніть на кнопку "New repository secret". Введіть ім'я та значення токена доступу.

6. При спробі запушити отримали помили, що потрібно виправити: 
```sh
$ make push 
$ export CR_PAT=ghp_*****************
$ echo $CR_PAT | docker login ghcr.io -u vit-um --password-stdin
Login Succeeded

$ make push
docker push ghcr.io/vit-um/kbot:v1.3.0-82e00eb-linux-amd64 
The push refers to repository [ghcr.io/vit-um/kbot]
f369bcfadf87: Pushed 
039f725d5b7c: Pushed 
v1.3.0-82e00eb-linux-amd64: digest: sha256:b4b3e8fc464abb8cfa3db07d3b2dbb01117ecdb525709d7a6f6443c7d4e73c22 size: 737
```

## Автоматизуйте цикл CI для свого сервісу бота.

1. Робочий процес GitHub Actions описується в каталозі `.github` в корні репозиторію, в якій розташуємо каталог `workflows`, де створимо `cicd.yaml` з кодом Pipeline. Зазвичай у кожного action є окремий репозиторій версії та [документація](https://github.com/actions/checkout#checkout-v4)

```yaml
# Перша секція в файлі не обов'язкова та описує назву  Pipeline:
name: KBOT-CICD

# Визначимо подію, яка запустить виконання workflow процесу при змінах у гілці develop
on: 
  push:
    branches:
      - develop

# блок задач який налаштовано на запуск завдання на новій ВМ з останньою версією ubuntu
jobs:
  ci:
    name: CI
    runs-on: ubuntu-latest
# перший крок задачі дозволить запускати на ранері репозиторій із скриптами для виконання дії. 
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
# наступним кроком запустимо команду make test, зробимо коміт та подивимось як це працює
      - name: Run test
        run: make test

```
2. Зайдемо на [github.com](https://github.com/vit-um/kbot/actions) в розділ Actions де знайдемо наш файл `workflow` та журнал подій по кожному кроку.

3. Далі йде крок збірки та пушу іміджу контейнеру. Тут ми використовуємо змінну середовища та повернемось до першого кроку, щоб вказати функцію `fetch-depth:0` з якою нам потрібно виконати `actions/checkout@v3` щоб витягнути з гітхабу не один коміт за замовчуванням, а всю історію гілок та тегів, бо ми на їх базі будемо збирати образ. На цьому кроці важливо щоб в налаштуваннях VSCode була дозволена функція передачі тегів: `Ctr+,` `followta`

```yaml
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
# .......
     - name: Build&Push
        env:
          APP: "kbot"
        run: make image push
```

## Автоматизуйте цикл CD для свого сервісу бота.

1. Додамо задачу безперервного розгортання. Ця задачу назвемо CD, перший крок буде відрізнятись від CI спеціальним налаштуванням - це призначення змінної `version` на базі значень тегу та короткого хешу коміту. Далі цю змінну передамо в спеціальне середовище зберігання змінних: `$GITHUB_ENV`. Це дозволить нам користуватись значенням цієї змінної на подальших кроках   
```yaml
  cd:
    name: CD
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0 
    - run: echo "VERSION=$(git describe --tags --abbrev=0 --always)-$(git rev-parse --short HEAD)" >> $GITHUB_ENV
```
2. Наступним кроком змінимо значення `tag` у файлі `helm/values.yaml` на нове, що відповідає образу контейнера, що ми запушили у попередньому джобі CI. Для цього використаємо дію, тоб-то скористаємось [бібліотекою для зміни файлів у форматі yaml](https://github.com/mikefarah/yq#yq).

```yaml
  - uses: mikefarah/yq@master
    with:
      cmd: yq -i '.image.tag=strenv(VERSION) | .image.os=strenv(TARGETOS) | .image.arch=strenv(TARGETARCH)' helm/values.yaml
```
3. Останнім кроком буде налаштування глобальних параметрів git на спеціальні значення `github-actions`, та команда коміта з повідомленням і заливка до репозиторію
```yaml
    - run: |
        git config user.name github-actions
        git config user.email github-actions@github.com
        git commit -am "update version $VERSION"
        git push
```
Важливим моментом є вказання залежності виконання jobs. Опцією `needs: ci` ми дозволяємо виконувати задачу CD тільки в разі успішного виконання CI.

Після успішного виконання workflow на віддаленому репозиторії відбудуться зміни версії, що можуть стати тригером для подальшої обробки коду будь яким інструментом GitOps, а саме  ArgoCD для етапу Deployment. 