ARG PARENT_IMAGE=cirss/json-schema-dev-parent:latest

FROM ${PARENT_IMAGE}

COPY exports /repro/exports

ADD ${REPRO_DIST}/boot-setup /repro/dist/

RUN bash /repro/dist/boot-setup

USER repro

RUN repro.require json-schema-dev exports

CMD  /bin/bash -il
