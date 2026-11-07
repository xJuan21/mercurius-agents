ARG IMAGE=iris-community:2027.1.0AI.109.0
# Builds the Angular app. Only its output goes into the IRIS image.
FROM node:24-slim AS web
WORKDIR /web
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
RUN npx ng build

FROM $IMAGE 

WORKDIR /home/irisowner/dev

ARG NAMESPACE="IRISAPP"

## Embedded Python environment
ENV IRISUSERNAME "_SYSTEM"
ENV IRISPASSWORD "SYS"
ENV IRISNAMESPACE $NAMESPACE
ENV PYTHON_PATH=/usr/irissys/bin/:/usr/irissys/mgr/python
ENV PATH "/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"



COPY --from=web --chown=51773:51773 /web/dist/mercurius/browser /usr/irissys/csp/mercurius
COPY requirements.txt /home/irisowner/dev/requirements.txt
COPY merge.cpf /home/irisowner/dev/merge.cpf
ENV PYTHONPATH="/usr/irissys/lib/python"
ENV PATH "/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"
WORKDIR /home/irisowner/dev

RUN  python3 -m venv "/home/irisowner/.venvs/mcp-tools" && \
   "/home/irisowner/.venvs/mcp-tools/bin/python" -m pip install -r /home/irisowner/dev/requirements.txt --break-system-packages --target /usr/irissys/mgr/python && \
   "/home/irisowner/.venvs/mcp-tools/bin/python" -m pip install typing-extensions --upgrade --break-system-packages --target /usr/irissys/mgr/python

RUN --mount=type=bind,src=.,dst=. \
    iris start IRIS && \
    iris merge IRIS /home/irisowner/dev/merge.cpf && \
	iris session IRIS < iris.script && \
    iris stop IRIS quietly