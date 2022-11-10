ARG CI_REGISTRY_IMAGE
ARG TAG
FROM ${CI_REGISTRY_IMAGE}/matlab-runtime:R2020b_u6${TAG}
LABEL maintainer="nathalie.casati@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    curl libqt5charts5 libqt5concurrent5 libqt5multimediawidgets5 \
    libqt5printsupport5 libqt5qml5 libmatio9 libvtk7.1p-qt \
    libqwt-qt5-6 libqt5xml5 libqcustomplot2.0 libtbb2 && \ 
    curl -Ok# https://meg.univ-amu.fr/AnyWave/anywave-${APP_VERSION}_amd64.deb && \
    dpkg -i anywave-${APP_VERSION}_amd64.deb && \
    rm anywave-${APP_VERSION}_amd64.deb && \
    apt-get remove -y --purge curl && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="no"
ENV APP_CMD="anywave"
ENV PROCESS_NAME="/usr/local/AnyWave/AnyWaveLinux"
ENV APP_DATA_DIR_ARRAY="AnyWave"
ENV DATA_DIR_ARRAY=""

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
