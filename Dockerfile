FROM python:3.11-slim-bookworm as builder

COPY flask/requirements.txt requirements.txt

RUN python3 -m venv /opt/venv && \
    export PATH="/opt/venv/bin:$PATH" && \
    export MAKEFLAGS="-j$(nproc)" && \
    python3 -m pip install --no-cache-dir -r requirements.txt

FROM docker.io/library/python:3.11-slim-bookworm

LABEL org.opencontainers.image.authors="datascience@it-ps.at"

ENV PATH="/opt/venv/bin:$PATH"

ENV PROJECT_BASE="/project"
ENV PROJECT_FLASK="${PROJECT_BASE}/flask"

COPY --from=builder /opt/venv /opt/venv
COPY flask/app.py "${PROJECT_FLASK}/app.py"

RUN mkdir -p "${PROJECT_BASE}" && \
    mkdir -p "${PROJECT_FLASK}" && groupadd flask && \
    useradd -g flask flask && \
    chown -R flask:flask /opt/venv && \
    chown -R flask:flask "${PROJECT_BASE}"

USER flask

EXPOSE 5000/tcp

WORKDIR "${PROJECT_FLASK}"

CMD [ "python3", "app.py" ]
