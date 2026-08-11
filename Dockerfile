ARG PARENT_IMAGE=cirss/json-schema-dev-parent:latest

FROM ${PARENT_IMAGE}

COPY exports /repro/exports

ADD ${REPRO_DIST}/boot-setup /repro/dist/

RUN bash /repro/dist/boot-setup

USER repro

RUN repro.require json-schema-dev exports --demo

# use a local directory named tmp for each demo
RUN repro.env REPRO_DEMO_TMP_DIRNAME tmp

# where the shared notebook cell helpers live, so that every demo's run.sh
# sources them by the same line regardless of how deeply it is nested
RUN repro.env JSON_SCHEMA_DEV_CELLS_DIR '${REPRO_MNT}/demo'

CMD  /bin/bash -il
