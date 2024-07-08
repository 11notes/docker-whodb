![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ Alpine - whodb
![size](https://img.shields.io/docker/image-size/11notes/whodb/latest?color=0eb305) ![version](https://img.shields.io/docker/v/11notes/whodb/latest?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/11notes/whodb?color=2b75d6) ![stars](https://img.shields.io/docker/stars/11notes/whodb?color=e6a50e) [<img src="https://img.shields.io/badge/github-11notes-blue?logo=github">](https://github.com/11notes)

**Simple and lightweight multi DB browser**

# SYNOPSIS
What can I do with this? Attach it to your Postgre, your MariaDB, your Redis or your SQLite database and enjoy a simple UI to browse your data quickly and easily.

# VOLUMES
* **/whodb/var** - Directory of SQlite databases

# COMPOSE
```yaml
version: "3.8"
services:
  postgres:
    image: "11notes/postgres:16"
    container_name: "postgres"
    environment:
      TZ: Europe/Zurich
      POSTGRES_PASSWORD: "whodb"
    volumes:
      - "postgres-var:/postgres/var"
      - "postgres-backup:/postgres/backup"
    networks:
      - postgres
    restart: always
  redis:
    image: "11notes/redis:7.2.5"
    container_name: "redis"
    environment:
      TZ: Europe/Zurich
      REDIS_PASSWORD: "whodb"
    volumes:
      - "redis-etc:/redis/etc"
      - "redis-var:/redis/var"
    networks:
      - redis
    restart: always
  whodb:
    image: "11notes/whodb:latest"
    container_name: "whodb"
    environment:
      TZ: Europe/Zurich
    ports:
      - "8080:8080/tcp"
    networks:
      - postgres
      - redis
      - frontend
    restart: always
volumes:
  postgres-var:
  postgres-backup:
  redis-etc:
  redis-var:
networks:
  postgres:
    internal: true
  redis:
    internal: true
  frontend:
```

# DEFAULT SETTINGS
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /whodb | home directory of user docker |

# ENVIRONMENT
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Show debug information | |

# PARENT IMAGE
* [11notes/alpine:stable](https://hub.docker.com/r/11notes/alpine)

# BUILT WITH
* [whodb](https://github.com/clidey/whodb)
* [alpine](https://alpinelinux.org)

# TIPS
* Allow non-root ports < 1024 via `echo "net.ipv4.ip_unprivileged_port_start={n}" > /etc/sysctl.d/ports.conf`
* Use a reverse proxy like Traefik, Nginx to terminate TLS with a valid certificate
* Use Let’s Encrypt certificates to protect your SSL endpoints

# ElevenNotes<sup>™️</sup>
This image is provided to you at your own risk. Always make backups before updating an image to a new version. Check the changelog for breaking changes. You can find all my repositories on [github](https://github.com/11notes).
    