# :: Util
  FROM alpine as util

  RUN set -ex; \
    apk add --no-cache \
      git; \
    git clone https://github.com/11notes/util.git;

# :: Build
  FROM 11notes/node:stable as frontend
  ENV BUILD_VERSION=main
  ENV BUILD_DIR=/whodb

  USER root

  RUN set -ex; \
    apk add --update --no-cache \
      git; \
    git clone https://github.com/clidey/whodb.git; \
    cd ${BUILD_DIR}; \
    git checkout ${BUILD_VERSION}; \
    cd ${BUILD_DIR}/frontend; \
    pnpm install; \
    pnpm run build; \
    mv build lib;

  FROM golang:1.22-alpine3.20 as backend
  ENV BUILD_VERSION=main
  ENV BUILD_DIR=/go/whodb

  USER root

  RUN set -ex; \
    apk add --update --no-cache \
      gcc \
      musl-dev \
      git; \
    git clone https://github.com/clidey/whodb.git; \
    cd ${BUILD_DIR}; \
    git checkout ${BUILD_VERSION}; \
    cd ${BUILD_DIR}/core; \
    go mod download; \
    CGO_ENABLED=1 GOOS=linux go build -o /usr/local/bin/whodb    

# :: Header
  FROM 11notes/alpine:stable
  COPY --from=util /util/linux/shell/elevenLogJSON /usr/local/bin
  COPY --from=frontend /whodb/frontend/lib /whodb/lib
  COPY --from=backend /usr/local/bin/whodb /usr/local/bin
  ENV APP_NAME="whodb"
  ENV APP_ROOT=/whodb

# :: Run
  USER root

  # :: prepare image
    RUN set -ex; \
      mkdir -p ${APP_ROOT}/var; \
      ln -s ${APP_ROOT}/lib /usr/local/bin/build; \
      ln -s ${APP_ROOT}/var /db; \
      apk --no-cache upgrade;

  # :: copy root filesystem changes and add execution rights to init scripts
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin;

  # :: change home path for existing user and set correct permission
    RUN set -ex; \
      usermod -d ${APP_ROOT} docker; \
      chown -R 1000:1000 \
        /db \
        ${APP_ROOT};

# :: Volumes
  VOLUME ["${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER docker
  ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]