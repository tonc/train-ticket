FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    curl \
    bash \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

WORKDIR /usr/local/bin/

COPY deploy.sh /usr/local/bin/
COPY deployment /usr/local/bin/deployment

RUN chmod +x /usr/local/bin/deploy.sh

ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/deploy.sh ${NAMESPACE}"]