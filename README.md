## Coding Session. GitHub Actions

Робочий процес GitHub Actions описується в каталозі `.github` в корні репозиторію, в якій розташуємо каталог `workflows`, де створимо `cicd.yaml` з кодом Pipeline. Зазвичай у кожного action є окремий репозиторій версії та [документація](https://github.com/actions/checkout#checkout-v4)

```yaml
# Перша секція в файлі не обов'язкова та описує назву  Pipeline:
name: KBOT-CICD

# Визначимо подію, яка запустить виконання workflow процесу.
on: push
# блок задач який налаштовано на запуск завдання на новій ВМ з останньою версією ubuntu
jobs:
  ci:
    name: CI
    runs-on: ubuntu-latest
# перший крок задачі дозволить запускати на ранері репозиторій із скриптами для виконання дії. 
    steps:
      - name: Checkout
        uses: actions/checkout@v3
# наступним кроком запустимо команду make test, зробимо коміт та подивимось як це працює
      - name: Run test
        run: make test

```
Зайдемо на [github.com](https://github.com/vit-um/kbot/actions) в розділ Actions де знайдемо наш файл `workflow` та журнал подій по кожному кроку.

Для ускладнення виконання завдань нам потрібна буде авторизація на Docker hub за нашими контейнерами. Для цього скористуємось [документацією](https://github.com/docker/login-action#docker-hub) для опису параметрів.  
```yaml
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
```
З паролями працюємо через спеціальний механізм зберігання секретних даних гітхабу [Actions secrets and variables](https://github.com/vit-um/devops/settings/secrets/actions), де додамо дві змінних описаних вище:

Токен потрібно згенерувати на сторінці [акаунта Docker Hub](https://hub.docker.com/settings/security) 

Далі йде крок збірки та пушу іміджу контейнеру. Тут треба ми використовуємо змінну середовища та повернемось до першого кроку, щоб вказати функцію `fetch-depth:0` з якою нам потрібно виконати `actions/checkout@v3` щоб витягнути з гітхабу не один коміт за замовчуванням, а всю історію гілок та тегів, бо ми на їх базі будемо збирати образ. На цьому кроці важливо щоб в налаштуваннях VSCode була дозволена функція передачі тегів: `Ctr+,` `followta`

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
          REGISTRY: ${{ vars.DOCKERHUB_USERNAME }}
        run: make image push
```
Додамо задачу безперервного розгортання. Ця задачу назвемо CD, перший крок буде відрізнятись від CI спеціальним налаштуванням - це призначення змінної `version` на базі значень тегу та короткого хешу коміту. Далі цю змінну передамо в спеціальне середовище зберігання змінних: `$GITHUB_ENV`. Це дозволить нам користуватись значенням цієї змінної на подальших кроках 
```yaml
  cd:
    name: CD
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0 
    - run: echo "VERSION=$(git describe --tags --abbrev=0)-$(git rev-parse --short HEAD)" >> $GITHUB_ENV
```
Наступним кроком змінимо значення `tag` у файлі `helm/values.yaml` на нове, що відповідає образу контейнера, що ми запушили у попередньому джобі CI. Для цього використаємо дію, тоб-то скористаємось [бібліотекою для зміни файлів у форматі yaml](https://github.com/mikefarah/yq#yq).

```yaml
    - uses: mikefarah/yq@master
      with:
        cmd: yq -i '.image.tag=strenv(VERSION)' helm/values.yaml
```
Останнім кроком буде налаштування глобальних параметрів git на спеціальні значення `github-actions`, та команда коміта з повідомленням і заливка до репозиторію
```yaml
    - run: |
        git config user.name github-actions
        git config user.email github-actions@github.com
```
Важливим моментом є вказання залежності виконання jobs. Опцією `needs: ci` ми дозволяємо виконувати задачу CD тільки в разі успішного виконання CI.

Після успішного виконання workflow на віддаленому репозиторії відбудуться зміни версії, що можуть стати тригером для подальшої обробки коду будь яким інструментом GitOps, наприклад ArgoCD або [Flux](https://github.com/weaveworks/awesome-gitops) для етапу Deployment. 