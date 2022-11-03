# SOFTWARE ARCHITECTURE LABORATORIES

## Laboratory 1

### Objectives

- Dockerize a database on MySQL, and managed by phpMyAdmin

### Steps

1. Create a docker file as follows:

    ```dockerfile
    FROM mysql:5.7

    ENV MYSQL_ROOT_PASSWORD=123
    ENV MYSQL_DATABASE=swarch2022ii_db
    ENV MYSQL_USER=swarch2022ii
    ENV MYSQL_PASSWORD=2022

    EXPOSE 3306

    ```

2. Build the image:

    ```bash
    docker build -t swarch2022ii_db .
    ```

3. Deploy and mount the image:

    ```bash
    docker run -d -t -i -p 3306:3306 --name swarch2022ii_db swarch2022ii_db
    ```

4. Build and run phpMyAdmin container:

    ```bash
    docker run --name db_client -d --link swarch2022ii_db:db -p 8081:80 phpmyadmin
    ```

Note: phpMyAdmin will be accesed on: <http://localhost:8081>.

## Laboratory 2

### Objectives

- build Django app on Docker

### Steps

1. Download Django source code from  [this page](https://drive.google.com/file/d/1J3DhiFJi3dimtJlkOshpILvXJHFg3O_0/view?usp=sharing) and extract it

2. Make dockerfile on swarch2022ii_ms folder:

    ```dockerfile
    FROM python:3

    ENV PYTHONUNBUFFERED 1
    RUN mkdir /code
    WORKDIR /code
    COPY requirements.txt /code/
    RUN pip install -r requirements.txt
    COPY . /code/
    ARG URL=0.0.0.0:4000

    CMD ["sh", "-c", "python manage.py makemigrations swarch2022ii_ms && python manage.py migrate && python manage.py runserver $URL"]
    ```

3. Build image:

    ```bash
    docker build -t swarch2022ii_ms .
    ```

4. Run container:

    ```bash
    docker run -p 4000:4000 -e DB_HOST=host.docker.internal  -e DB_PORT=3306 -e DB_USER=swarch2022ii -e DB_PASSWORD=2022 -e DB_NAME=swarch2022ii_db -e URL=0.0.0.0:4000 swarch2022ii_ms
    ```

    If doesn work, replace `host.docker.internal` with `172.17.0.2`. This is the IP of the host machine, extracted from the container with `docker inspect CONTAINER_ID`.

5. Verify with postman or browser on <http://localhost:4000>

## Laboratory 3

### Objectives

- build APIgateway on Docker, using GraphQL.

### Steps

1. Download APIgateway source code from  [this page](https://drive.google.com/file/d/1KBGnqdJKaH97MykQ--bqq2i10u7P5rMi/view) and extract it.

2. Build and run api-gateway container:

    ```bash
    docker build -t swarch2022ii_ag .
    docker run -p 5000:5000 swarch2022ii_ag
    ```

## Laboratory 4

Made in class

## Laboratory 5

### Objectives

-

### Steps

1. Make directory swarch2022ii_ldap.

2. Make docker-compose.yaml file as follows:

    ```dockerfile
    version: '2.1'
    services:
      swarch2022ii-ldap:
        image: osixia/openldap:1.1.8
        container_name: swarch2022ii_ldap
        environment:
          COMPOSE_HTTP_TIMEOUT: 200
          LDAP_LOG_LEVEL: "256"
          LDAP_ORGANISATION: "Software Architecture"
          LDAP_DOMAIN: "arqsoft.unal.edu.co"
          LDAP_BASE_DN: ""
          LDAP_ADMIN_PASSWORD: "admin"
          LDAP_CONFIG_PASSWORD: "config"
          LDAP_READONLY_USER: "false"
          #LDAP_READONLY_USER_USERNAME: "readonly"
          #LDAP_READONLY_USER_PASSWORD: "readonly"
          LDAP_BACKEND: "hdb"
          LDAP_TLS: "true"
          LDAP_TLS_CRT_FILENAME: "ldap.crt"
          LDAP_TLS_KEY_FILENAME: "ldap.key"
          LDAP_TLS_CA_CRT_FILENAME: "ca.crt"
          LDAP_TLS_ENFORCE: "false"
          LDAP_TLS_CIPHER_SUITE: "SECURE256:-VERS-SSL3.0"
          LDAP_TLS_PROTOCOL_MIN: "3.1"
          LDAP_TLS_VERIFY_CLIENT: "demand"
          LDAP_REPLICATION: "false"
          #LDAP_REPLICATION_CONFIG_SYNCPROV: "binddn="cn=admin,cn=config" bindmethod=simple credentials=$LDAP_CONFIG_PASSWORD searchbase="cn=config" type=refreshAndPersist retry="60 +" timeout=1 starttls=critical"
          #LDAP_REPLICATION_DB_SYNCPROV: "binddn="cn=admin,$LDAP_BASE_DN" bindmethod=simple credentials=$LDAP_ADMIN_PASSWORD searchbase="$LDAP_BASE_DN" type=refreshAndPersist interval=00:00:00:10 retry="60 +" timeout=1 starttls=critical"
          #LDAP_REPLICATION_HOSTS: "#PYTHON2BASH:['ldap://ldap.example.org','ldap://ldap2.example.org']"
          LDAP_REMOVE_CONFIG_AFTER_SETUP: "true"
          LDAP_SSL_HELPER_PREFIX: "ldap"
        tty: true
        stdin_open: true
        volumes:
          - /var/lib/ldap
          - /etc/ldap/slapd.d
          - /container/service/slapd/assets/certs/
        ports:
          - "389:389"
          - "636:636"
        hostname: "arqsoft.unal.edu.co"
      phpldapadmin:
        image: osixia/phpldapadmin:latest
        container_name: ldap_client
        environment:
          PHPLDAPADMIN_LDAP_HOSTS: "swarch2022ii-ldap"
          PHPLDAPADMIN_HTTPS: "false"
        ports:
          - "8085:80"
        links:
          - swarch2022ii-ldap
    ```

3. Run docker-compose:

    ```bash
    docker-compose up
    ```

4. Verify with browser on <http://localhost:8085>

5. Create generic posix group and users.

6. Creade directory swarch2022ii_proxy. (Inverse proxy)

7. Create nginx dockerfile as follows:

    ```dockerfile
    FROM nginx

    RUN apt-get update -qq && apt-get -y install apache2-utils
    ENV NODE_ROOT /var/www/api-gateway

    WORKDIR $NODE_ROOT

    RUN mkdir log

    COPY app.conf /tmp/app.nginx

    RUN envsubst '$NODE_ROOT' < /tmp/app.nginx > /etc/nginx/conf.d/default.conf
    EXPOSE 80

    CMD [ "nginx", "-g", "daemon off;" ]
    ```

8. create nginx app.conf as follows:

  ```nginx
  upstream api_gateway_node {
      server localhost:5000;
  }

  server {
      listen 80;
      proxy_buffers 64 16k;
      proxy_max_temp_file_size 1024m;
      proxy_connect_timeout 5s;
      proxy_send_timeout 10s;
      proxy_read_timeout 10s;

      location ~ /\. {
          deny all;
      }

      location ~* ^.+\.(rb|log)$ {
          deny all;
      }

      # serve static (compiled) assets directly if they exist (for node production)
      location ~ ^/(assets|images|javascripts|stylesheets|swfs|system)/ {
          try_files $uri @api_gateway_node;

          access_log off;
          gzip_static on; # to serve pre-gzipped version

          expires max;
          add_header Cache-Control public;

          # Some browsers still send conditional-GET requests if there's a
          # Last-Modified header or an ETag header even if they haven't
          # reached the expiry date sent in the Expires header.
          add_header Last-Modified "";
          add_header ETag "";
          break;
      }

      location / {
          try_files $uri $uri/ @api_gateway_node;
      }

      location @api_gateway_node {
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $http_host;
          proxy_redirect off;
          proxy_pass http://api_gateway_node;
          access_log /var/www/api-gateway/log/nginx.access.log;
          error_log /var/www/api-gateway/log/nginx.error.log;
      }
  }
  ```

9. Build and run image:

```bash
    docker build -t swarch2022ii_proxy .

    docker run -p 80:80 swarch2022ii_proxy
```

10. access to container on an interactive bash shell to show its behaviour:

```bash
    docker exec -it swarch2022ii_proxy bash
```
# swarch-labs
