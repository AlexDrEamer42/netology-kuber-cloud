# Домашнее задание к занятию «Организация сети»

### Задание 1. Yandex Cloud 

**Что нужно сделать**

1. Создать пустую VPC. Выбрать зону.
2. Публичная подсеть.

 - Создать в VPC subnet с названием public, сетью 192.168.10.0/24.
 - Создать в этой подсети NAT-инстанс, присвоив ему адрес 192.168.10.254. В качестве image_id использовать fd80mrhj8fl2oe87o4e1.
 - Создать в этой публичной подсети виртуалку с публичным IP, подключиться к ней и убедиться, что есть доступ к интернету.
3. Приватная подсеть.
 - Создать в VPC subnet с названием private, сетью 192.168.20.0/24.
 - Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс.
 - Создать в этой приватной подсети виртуалку с внутренним IP, подключиться к ней через виртуалку, созданную ранее, и убедиться, что есть доступ к интернету.

---

Создал необходимые ресурсы через конфигурационный файл [infrastructure.tf](src%2Finfrastructure.tf)

Подсети:

![subnets.png](img%2Fsubnets.png)

Таблицы маршрутизации:

![route.png](img%2Froute.png)

Виртуальные машины:

![vms.png](img%2Fvms.png)

Подключился к публичной ВМ, проверил доступ в интернет:

```commandline
ssh user@84.201.131.159

user@fhm2mgcitl7sg08lo7tn:~$ curl -I example.com
HTTP/1.1 200 OK
Content-Encoding: gzip
Accept-Ranges: bytes
Age: 460982
Cache-Control: max-age=604800
Content-Type: text/html; charset=UTF-8
Date: Wed, 29 Nov 2023 16:29:08 GMT
Etag: "3147526947+gzip"
Expires: Wed, 06 Dec 2023 16:29:08 GMT
Last-Modified: Thu, 17 Oct 2019 07:18:26 GMT
Server: ECS (nyb/1D2F)
X-Cache: HIT
Content-Length: 648
```

Подключился к приватной ВМ через публичную, проверил доступ в интернет:

```commandline
ssh -J user@84.201.131.159 user@192.168.20.11

user@fhm3525lcnb1fo5rg1pb:~$ curl -I example.com
HTTP/1.1 200 OK
Accept-Ranges: bytes
Age: 457455
Cache-Control: max-age=604800
Content-Type: text/html; charset=UTF-8
Date: Wed, 29 Nov 2023 16:30:23 GMT
Etag: "3147526947+gzip"
Expires: Wed, 06 Dec 2023 16:30:23 GMT
Last-Modified: Thu, 17 Oct 2019 07:18:26 GMT
Server: ECS (sed/58AA)
X-Cache: HIT
Content-Length: 1256
```