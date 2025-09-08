# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/go/whodb \
      BUILD_SRC=https://github.com/clidey/whodb.git
  ARG BUILD_BIN=${BUILD_ROOT}/whodb

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:localhealth AS distroless-localhealth


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: WHODB
  FROM 11notes/go:1.25 AS build
  ARG APP_VERSION \
      BUILD_ROOT \
      BUILD_SRC \
      BUILD_BIN \
      TARGETARCH \
      TARGETPLATFORM \
      TARGETVARIANT

  RUN set -ex; \
    apk --update --no-cache add \
      nodejs \
      pnpm;

  RUN set -ex; \
    git clone ${BUILD_SRC} -b ${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}/frontend; \
    # disable telemetry
    sed -i 's/phc_hbXcCoPTdxm5ADL8PmLSYTIUvS6oRWFM2JAK8SMbfnH/***********************************************/' ${BUILD_ROOT}/frontend/src/config/posthog.tsx; \
    sed -i "s/import.meta.env.VITE_BUILD_EDITION === 'ee'/true/" ${BUILD_ROOT}/frontend/src/config/posthog.tsx; \
    pnpm install; \
    pnpm run build; \
    mv ${BUILD_ROOT}/frontend/build ${BUILD_ROOT}/core;

  RUN set -ex; \
    cd ${BUILD_ROOT}/core; \
    eleven go build ${BUILD_BIN} server.go;

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};

# :: FILE SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p {APP_ROOT}/var; \
    ln -s ${APP_ROOT}/var /distroless/db;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV NODE_ENV=production

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-localhealth / /
    COPY --from=build /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:8080/"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/whodb"]