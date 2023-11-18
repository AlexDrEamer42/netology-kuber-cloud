# Домашнее задание к занятию «Как работает сеть в K8s»

### Цель задания

Настроить сетевую политику доступа к подам.

-----

### Задание 1. Создать сетевую политику или несколько политик для обеспечения доступа

1. Создать deployment'ы приложений frontend, backend и cache и соответствующие сервисы.
2. В качестве образа использовать network-multitool.
3. Разместить поды в namespace App.
4. Создать политики, чтобы обеспечить доступ frontend -> backend -> cache. Другие виды подключений должны быть запрещены.
5. Продемонстрировать, что трафик разрешён и запрещён.

-----

1. Убедился, что плагин Calico активен в Microk8s:
    ```
    microk8s enable dns
    ```
    ```
    Infer repository core for addon dns
    Addon core/dns is already enabled
    ```
    ```
    microk8s kubectl get pods -A
    ```
    ```
    NAMESPACE     NAME                                       READY   STATUS    RESTARTS       AGE
    kube-system   calico-kube-controllers-67f8bf9dff-ktmrm   1/1     Running   9 (54m ago)    13d
    kube-system   coredns-7745f9f87f-wlchw                   1/1     Running   38 (54m ago)   33d
    kube-system   calico-node-f2h97                          1/1     Running   8 (54m ago)    13d
    ```
2. Создал namespace **app**:
   ```
   kubectl create namespace app
   ```
   ```
   namespace/app created
   ```
3. Подготовил манифесты для Deployment и сервисов:
   - [frontend_deployment.yaml](frontend_deployment.yaml)
   - [backend_deployment.yaml](backend_deployment.yaml)
   - [cache_deployment.yaml](cache_deployment.yaml)
   - [frontend_svc.yaml](frontend_svc.yaml)
   - [backend_svc.yaml](backend_svc.yaml)
   - [cache_svc.yaml](cache_svc.yaml)
4. Создал deployment и сервисы:
   ```
   kubectl apply -n app -f frontend_deployment.yaml
   kubectl apply -n app -f backend_deployment.yaml 
   kubectl apply -n app -f cache_deployment.yaml 
   kubectl apply -n app -f frontend_svc.yaml 
   kubectl apply -n app -f backend_svc.yaml 
   kubectl apply -n app -f cache_svc.yaml
   ```
   ``` 
   kubectl -n app get pods
   ```
   ```
   NAME                                   READY   STATUS    RESTARTS   AGE
   frontend-deployment-784477cb68-rbqms   1/1     Running   0          71s
   backend-deployment-6b4f5876bd-66g6r    1/1     Running   0          50s
   cache-deployment-57c9c8cfb6-vc22p      1/1     Running   0          44s
   ```
   ```
   kubectl -n app get svc
   ```
   ```
   NAME       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
   frontend   ClusterIP   10.152.183.185   <none>        8080/TCP   26s
   backend    ClusterIP   10.152.183.99    <none>        8080/TCP   21s
   cache      ClusterIP   10.152.183.239   <none>        8080/TCP   15s
   ```
5. Подготовил манифесты для Network Policy:
   - [frontend_policy.yaml](frontend_policy.yaml)
   - [backend_policy.yaml](backend_policy.yaml)
   - [cache_policy.yaml](cache_policy.yaml)
6. Создал Network Policy:
   ```
   kubectl apply -n app -f frontend_policy.yaml 
   kubectl apply -n app -f backend_policy.yaml 
   kubectl apply -n app -f cache_policy.yaml
   ``` 
   ```
   kubectl get -n app networkpolicies
   ```
   ```
   NAME              POD-SELECTOR   AGE
   frontend-policy   app=frontend   33s
   backend-policy    app=backend    26s
   cache-policy      app=cache      20s
   ```
7. Проверил разрешения для трафика:
   1. Frontend -> Backend разрешён:
      ```
      kubectl exec -n app frontend-deployment-784477cb68-rbqms curl 10.152.183.99:8080
      ```
      ```
      WBITT Network MultiTool (with NGINX) - backend-deployment-6b4f5876bd-66g6r - 10.1.43.234 - HTTP: 8080 , HTTPS: 443 . (Formerly praqma/network-multitool)
      ``` 
   2. Frontend -> Cache запрещён (нет ответа):
      ```
      kubectl exec -n app frontend-deployment-784477cb68-rbqms curl 10.152.183.239:8080
      ```
   3. Backend -> Frontend запрещён (нет ответа):
      ```    
      kubectl exec -n app backend-deployment-6b4f5876bd-66g6r curl 10.152.183.185:8080
      ```
   4. Backend -> Cache разрешён:   
      ```
      kubectl exec -n app backend-deployment-6b4f5876bd-66g6r curl 10.152.183.239:8080
      ```
      ```
      WBITT Network MultiTool (with NGINX) - cache-deployment-57c9c8cfb6-vc22p - 10.1.43.235 - HTTP: 8080 , HTTPS: 443 . (Formerly praqma/network-multitool)
      ```
   5. Cache -> Frontend запрещён (нет ответа):   
      ```
      kubectl exec -n app cache-deployment-57c9c8cfb6-vc22p curl 10.152.183.185:8080
      ```
   6. Cache -> Backend запрещён (нет ответа):   
      ```
      kubectl exec -n app cache-deployment-57c9c8cfb6-vc22p curl 10.152.183.99:8080
      ```

