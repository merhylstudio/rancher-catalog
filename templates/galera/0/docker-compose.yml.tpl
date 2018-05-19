mariadb-galera-server:
  image: mariadb:10.2.14
  net: "container:galera"
  environment:
    TERM: "xterm"
    MYSQL_ROOT_PASSWORD: ${mysql_root_password}
{{- if .Values.mysql_database }}
    MYSQL_DATABASE: ${mysql_database}
{{- end}}
{{- if .Values.mysql_user and .Values.mysql_password }}
    MYSQL_USER: ${mysql_user}
    MYSQL_PASSWORD: ${mysql_password}
{{- end}}
  volumes_from:
    - 'mariadb-galera-data'
  labels:
    io.rancher.container.hostname_override: container_name
  entrypoint: bash -x /opt/rancher/start_galera
mariadb-galera-data:
  image: mariadb:10.2.14
  net: none
  environment:
    MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
  volumes:
    - /var/lib/mysql
    - /etc/mysql/conf.d
    - /docker-entrypoint-initdb.d
    - /opt/rancher
  command: /bin/true
  labels:
    io.rancher.container.start_once: true
galera-leader-forwarder:
  image: rancher/galera-leader-proxy:v0.1.0
  net: "container:galera"
  volumes_from:
   - 'mariadb-galera-data'
galera:
  image: rancher/galera-conf:v0.2.0
  labels:
{{- if eq .Values.HOST_LABEL "true" }}
    io.rancher.scheduler.affinity:host_label: galera=true
{{- end}}
    io.rancher.sidekicks: mariadb-galera-data,mariadb-galera-server,galera-leader-forwarder
    io.rancher.container.hostname_override: container_name
    io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
  volumes_from:
    - 'mariadb-galera-data'
  stdin_open: true
  tty: true
  command: /bin/bash

galera-lb:
  expose:
  - 3306:3307/tcp
  tty: true
  image: rancher/load-balancer-service
  {{- if eq .Values.HOST_LABEL "true" }}
  labels:
    io.rancher.scheduler.affinity:host_label: galera=true
  {{- end}}
  links:
  - galera:galera
  stdin_open: true
