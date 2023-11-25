# Домашнее задание к занятию Troubleshooting

### Цель задания

Устранить неисправности при деплое приложения.

### Чеклист готовности к домашнему заданию

1. Кластер K8s.

### Задание. При деплое приложение web-consumer не может подключиться к auth-db. Необходимо это исправить

1. Установить приложение по команде:
```shell
kubectl apply -f https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
```
2. Выявить проблему и описать.
3. Исправить проблему, описать, что сделано.
4. Продемонстрировать, что проблема решена.

-----

1. Создал необходимые namespace:
    ```
    kubectl create namespace web
    kubectl create namespace data
    ```
2. Выполнил деплой:
    ```
    kubectl apply -f https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
    ```
    ```
    deployment.apps/web-consumer created
    deployment.apps/auth-db created
    service/auth-db created
    ```
3. Посмотрел данные подов web-consumer:
    ```
    kubectl get pods -n web -o wide
    ```
    ```
    NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE      NOMINATED NODE   READINESS GATES
    web-consumer-84fc79d94d-dq6nr   1/1     Running   0          11m   10.1.43.242   example   <none>           <none>
    web-consumer-84fc79d94d-cgb58   1/1     Running   0          11m   10.1.43.240   example   <none>           <none>
    ```
4. Посмотрел настройки сервиса auth-db:
    ```
    kubectl describe -n data svc/auth-db
    ```
    ```
    Name:              auth-db
    Namespace:         data
    Labels:            <none>
    Annotations:       <none>
    Selector:          app=auth-db
    Type:              ClusterIP
    IP Family Policy:  SingleStack
    IP Families:       IPv4
    IP:                10.152.183.161
    IPs:               10.152.183.161
    Port:              <unset>  80/TCP
    TargetPort:        80/TCP
    Endpoints:         10.1.43.239:80
    Session Affinity:  None
    Events:            <none>
    ```
5. Посмотрел логи web-consumer:
    ```
    kubectl logs -n web web-consumer-84fc79d94d-dq6nr
    ```
    ```
    curl: (6) Couldn't resolve host 'auth-db'
    curl: (6) Couldn't resolve host 'auth-db'
    curl: (6) Couldn't resolve host 'auth-db'
    ```
6. Подключился к поду:
    ```
    kubectl exec -it -n web web-consumer-84fc79d94d-dq6nr -- sh
    [ root@web-consumer-84fc79d94d-dq6nr:/ ]$ curl auth-db
    curl: (6) Couldn't resolve host 'auth-db'
    [ root@web-consumer-84fc79d94d-dq6nr:/ ]$ curl 10.1.43.239
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ```
    По IP-адресу сервис доступен, значит проблема в разрешении доменного имени. Так как `web-consumer` и `auth-db` находятся 
в разных namespace, правильно будет обращаться по доменному имени `auth-db.data`
7. Отредактировал Deployment:
    ```
    kubectl edit -n web deployments.apps web-consumer 
    ```
    Команду `curl auth-db` заменил на `curl auth-db.data`. 
8. Дождался когда пересоздадутся поды:
    ```
    kubectl get pods -n web
    ```
    ```
    NAME                            READY   STATUS    RESTARTS   AGE
    web-consumer-5769f9f766-zvn26   1/1     Running   0          42s
    web-consumer-5769f9f766-2k9gm   1/1     Running   0          34s
    ```
9. Проверил логи пода, подключение проходит успешно:
    ```
    kubectl logs -n web web-consumer-5769f9f766-zvn26
    ```
    ```
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ```
