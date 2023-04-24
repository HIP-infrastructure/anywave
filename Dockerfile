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
    git cmake build-essential libtbb-dev \
    qt5-default qtbase5-dev libqt5multimediawidgets5 \
    qtmultimedia5-dev libqt5opengl5-dev libqt5printsupport5 \
    libqt5x11extras5-dev libqt5svg5-dev qtdeclarative5-dev \
    libmatio-dev libvtk7-qt-dev libqwt-qt5-dev libqcustomplot-dev \
    libopenblas-dev libfftw3-dev libxcursor1

#Clone project in our fork and checkout ${APP_VERSION}
RUN git clone https://github.com/HIP-infrastructure/anywave-code.git anywave
ADD "https://api.github.com/repos/HIP-infrastructure/anywave-code/commits?sha=hip-v${APP_VERSION}&per_page=1" anywave_latest_commit

RUN cd anywave && git checkout hip-v${APP_VERSION} && git pull

#Launch build and then cleanup
RUN mkdir -p build && \
    cd build && \
    cmake ../anywave -Wno-dev -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j7 && \
    make install && \
    apt-get remove -y --purge git cmake build-essential && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="no"
ENV APP_CMD="/usr/local/AnyWave/AnyWaveLinux"
ENV PROCESS_NAME="/usr/local/AnyWave/AnyWaveLinux"
ENV APP_DATA_DIR_ARRAY="AnyWave"
ENV DATA_DIR_ARRAY=""

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
