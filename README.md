# auto-deploy
```sh
dockercompose.sampel
version: '2'
services:
  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 
      MYSQL_DATABASE: 
    ports:
     - "33310:3306"
    volumes:
     - "./docker/database/my.cnf:/root/.my.cnf"
     - "./docker/database/mysql:/var/lib/mysql/"

  app:
    build: .
    command: sh /run.sh
    restart: always
    privileged: true
    volumes:
      - ""
      - "./docker/app/vhost.conf:/etc/nginx/conf.d/vhost.conf"
      - "./docker/app/main.nginx.conf:/etc/nginx/nginx.conf"
      - "./docker/postfix/main.cf:/etc/postfix/main.cf"
      - "./docker/run.sh:/run.sh"
      - "./docker/ssl:/etc/nginx/ssl"
      - "./docker/app/passenger.conf:/etc/nginx/conf.d/passenger.conf"
    ports:
      - "9096:80"
      - "2529:25"
    depends_on:
      - db
      - redis322
  redis322:
    image: redis:3.2.2
    command: redis-server
    ports:
      - '46379:6379'

#  mail:
#    image: schickling/mailcatcher:latest
#    ports:
#      - '1081:1080'
#      - '1026:1025'
```
import database

`docker exec -i $(docker-compose ps -q db) mysql -uroot -p123123 job_crawler_staging  < struc.sql`


`docker exec -i $(docker-compose ps -q db) mysql -uroot -p123123 job_crawler_staging  < data.sql`
