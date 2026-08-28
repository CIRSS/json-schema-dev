ARG PARENT_IMAGE=cirss/json-schema-dev-parent:latest

FROM ${PARENT_IMAGE}

COPY exports /repro/exports

ADD ${REPRO_DIST}/boot-setup /repro/dist/

RUN bash /repro/dist/boot-setup

USER repro

RUN repro.require json-schema-dev exports --code

RUN sudo npm install -g 'mocha@11.7.5'

CMD  /bin/bash -il
