FROM python:2-alpine

LABEL maintainer frosty5689 <frosty5689@gmail.com>

ENV INSTALL_PATH="/app"

### Set working directory
WORKDIR ${INSTALL_PATH}

### Install packages
RUN apk --no-cache update \
  #Required
  && apk add --no-cache \
    ca-certificates \
    tesseract-ocr \
    tesseract-ocr-data-eus \
    curl \
  #Building only
  && apk add --no-cache --virtual .build-deps \
    libressl-dev \
    python-dev \
    curl-dev \
    g++ \
    gcc \
    make \
    perl \
    zlib-dev \
    jpeg-dev \
    libev-dev \
    libffi-dev \
    tesseract-ocr-dev \
    leptonica-dev

### Download and compile js engine for (spidermonkey)
RUN wget http://ftp.mozilla.org/pub/mozilla.org/js/js-1.8.0-rc1.tar.gz \
  && tar xzf js-1.8.0-rc1.tar.gz \
  && cd js/src \
  && make BUILD_OPT=1 -f Makefile.ref \
  && make BUILD_OPT=1 JS_DIST=/usr -f Makefile.ref export \
  && cd ${INSTALL_PATH} \
  && rm -rf js*

### Install python packages
RUN pip --no-cache-dir install --upgrade setuptools \
  #Required
  && pip --no-cache-dir install beaker \
    py-getch \
    multipartposthandler \
    evalidate \
    bottle \
    colorama \
    jinja2 \
    markupsafe \
    pycurl \
    rename \
    thrift \
    wsgiserver \
  #Optional
  && pip --no-cache-dir install beautifulsoup \
    pillow-pil \
    colorlog \
    bjoern \
    feedparser \
    tesseract-ocr \
    pyopenssl \
    pycrypto \
    simplejson

### Download latest stable pyload
# Pre-build packages: https://github.com/pyload/pyload/releases.
# Latest stable version (source code): https://github.com/pyload/pyload/archive/stable.zip.
# Latest development version (source code): https://github.com/pyload/pyload/archive/master.zip.
RUN wget https://github.com/pyload/pyload/archive/stable.zip \
  && unzip -q stable.zip \
  && rm -rf stable.zip \
  && mv pyload-stable pyload \
  && cd pyload \
  #echo command simulates Enter keystroke for python command
  && echo -ne '\n' | python pyLoadCore.py --changedir --configdir=${INSTALL_PATH}/pyload/conf \
  #Create script for ENTRYPOINT :
  # - remove pyload.pid file when pyload is not properly stopped
  # - exec replace current bash process by python process at the and of script
  #   so we can interact with pyload arguments in the container
  # - u option used as workaround when pyLoadCore.py prompt
  && echo 'rm -f conf/pyload.pid; exec python -u pyLoadCore.py "$@"' > entrypoint.sh \
  && chmod +x entrypoint.sh

### Cleaning task
RUN apk del --purge .build-deps

### Make those parameters available outside the container
EXPOSE 8000 7227 9666
VOLUME ["/app/pyload/conf","/app/pyload/Downloads"]

### Set default directory and change user
WORKDIR "${INSTALL_PATH}/pyload"

### Run pyload thanks to exec command when the container is launched
ENTRYPOINT ["/bin/sh", "entrypoint.sh"]

