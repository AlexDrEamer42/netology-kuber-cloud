# Домашнее задание к занятию «Установка Kubernetes»

### Цель задания

Установить кластер K8s.

-----

### Задание 1. Установить кластер k8s с 1 master node

1. Подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды.
2. В качестве CRI — containerd.
3. Запуск etcd производить на мастере.
4. Способ установки выбрать самостоятельно.

-----

1. Создал 5 ВМ с Ubuntu 20.04:
   ![01.png](images%2F01.png) 
2. Подготовил ноды для развёртывания кластера:
    ```
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg
    sudo mkdir /etc/apt/keyrings/
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl containerd
    sudo apt-mark hold kubelet kubeadm kubectl
    ``` 
3. Включил форвардинг:
    ```
    sudo -i
    modprobe br_netfilter
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-arptables=1" >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
    ```
4. Инициализировал master node:
    ```
    sudo kubeadm init \
    --apiserver-advertise-address=10.128.0.15 \
    --pod-network-cidr 10.244.0.0/16 \
    --apiserver-cert-extra-sans=158.160.57.253
    ```
5. Скопировал конфигурацию k8s:
    ```
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
6. Установил плагин CNI:
    ```
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yaml
    ```
7. Подключил worker nodes:
    ```
    sudo kubeadm join 10.128.0.15:6443 \
    --token 6jwuf3.qtdg651u2oce1kv1 \
    --discovery-token-ca-cert-hash sha256:7b300889a919ebcde456949badbcaa23848f913c5b845fb6a46c01dd1a05e954 
    ```
8. Проверил статус нод:
    ```
    kubectl get nodes
    ```
    ```
    NAME      STATUS   ROLES           AGE     VERSION
    master1   Ready    control-plane   18m     v1.28.3
    worker1   Ready    <none>          6m28s   v1.28.3
    worker2   Ready    <none>          6m17s   v1.28.3
    worker3   Ready    <none>          6m12s   v1.28.3
    worker4   Ready    <none>          6m8s    v1.28.3
    ```



