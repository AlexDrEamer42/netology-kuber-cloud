# Домашнее задание к занятию «Обновление приложений»

### Цель задания

Выбрать и настроить стратегию обновления приложения.

-----

### Задание 1. Выбрать стратегию обновления приложения и описать ваш выбор

1. Имеется приложение, состоящее из нескольких реплик, которое требуется обновить.
2. Ресурсы, выделенные для приложения, ограничены, и нет возможности их увеличить.
3. Запас по ресурсам в менее загруженный момент времени составляет 20%.
4. Обновление мажорное, новые версии приложения не умеют работать со старыми.
5. Вам нужно объяснить свой выбор стратегии обновления приложения.

---

Так как максимальный запас по ресурсам составляет 20%, стратегии Blue-green и Canary для нас не подходят.

При выборе стратегии Rolling update одновременно будут работать и новые, и старые версии, что противоречит требованию из п.4.

Таким образом, единственным вариантом остаётся стратегия Recreate. Реплики обновятся одновременно, дополнительных ресурсов не потребуется.

---

### Задание 2. Обновить приложение

1. Создать deployment приложения с контейнерами nginx и multitool. Версию nginx взять 1.19. Количество реплик — 5.
2. Обновить версию nginx в приложении до версии 1.20, сократив время обновления до минимума. Приложение должно быть доступно.
3. Попытаться обновить nginx до версии 1.28, приложение должно оставаться доступным.
4. Откатиться после неудачного обновления.

---

1. Создал Deployment с манифестом [nginx-deployment.yaml](nginx-deployment.yaml):
    ```
    kubectl apply -f nginx-deployment.yaml 
    ```
    ```
    kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause="initial deploy"
    ```
2. Обновил версию nginx до 1.20:
    ```
    kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.20
    ```
    ```
    kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause="update to nginx 1.20"
    ```
3. Проверил статус обновления:
    ```
    kubectl rollout status deployment nginx-deployment
    ```
    ```
    Waiting for deployment "nginx-deployment" rollout to finish: 3 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 3 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 3 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 2 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 2 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 2 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "nginx-deployment" rollout to finish: 3 of 5 updated replicas are available...
    Waiting for deployment "nginx-deployment" rollout to finish: 4 of 5 updated replicas are available...
    deployment "nginx-deployment" successfully rolled out
    ```
    ```
    kubectl describe deployments.apps nginx-deployment | grep Image
    ```
    ```
    Image:        nginx:1.20
    Image:      wbitt/network-multitool
    ```
4. Попытался обновить версию nginx до 1.28:
    ```
    kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.28
    ```
    ```
    kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause="update to nginx 1.28"
    ```
    Обновление не произошло, осталось доступно 3 реплики:
    ```
    kubectl get pods
    ```
    ```
    NAME                                READY   STATUS             RESTARTS   AGE
    nginx-deployment-7fb7f54b6f-49sff   2/2     Running            0          10m
    nginx-deployment-7fb7f54b6f-zcn5n   2/2     Running            0          10m
    nginx-deployment-7fb7f54b6f-qfzjl   2/2     Running            0          10m
    nginx-deployment-74f45fcbb5-q5tjr   1/2     ImagePullBackOff   0          9m4s
    nginx-deployment-74f45fcbb5-phxp7   1/2     ImagePullBackOff   0          9m4s
    nginx-deployment-74f45fcbb5-krsrl   1/2     ImagePullBackOff   0          9m4s
    nginx-deployment-74f45fcbb5-q9qjl   1/2     ImagePullBackOff   0          9m3s
    nginx-deployment-74f45fcbb5-jd5qr   1/2     ImagePullBackOff   0          9m4s
    ```
5. Проверил список ревизий:
    ```
    kubectl rollout history deployment/nginx-deployment
    ```
    ```
    deployment.apps/nginx-deployment 
    REVISION  CHANGE-CAUSE
    1         initial deploy
    2         update to nginx 1.20
    3         update to nginx 1.28
    ```
6. Откатился до ревизии 2:
    ```
    kubectl rollout undo deployment/nginx-deployment --to-revision=2
    ```
7. Проверил статус подов:
    ```
    kubectl get pods
    ```
    ```
    NAME                                READY   STATUS    RESTARTS   AGE
    nginx-deployment-5db75d874f-9c7fx   2/2     Running   0          4m18s
    nginx-deployment-5db75d874f-dv7bg   2/2     Running   0          4m18s
    nginx-deployment-5db75d874f-mt4k6   2/2     Running   0          4m17s
    nginx-deployment-5db75d874f-wvlrm   2/2     Running   0          29s
    nginx-deployment-5db75d874f-rphs7   2/2     Running   0          29s
    ```
8. Проверил версию nginx:
    ```
    kubectl describe deployments.apps nginx-deployment | grep Image
    ```
    ```
    Image:        nginx:1.20
    Image:      wbitt/network-multitool
    ```