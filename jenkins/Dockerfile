FROM jenkins/jenkins:lts

RUN jenkins-plugin-cli --plugins \
    git \
    workflow-job \ 
    workflow-aggregator \
    credentials-binding \
    docker-workflow

USER root
RUN apt-get update && \
    apt-get install -y docker.io && \
    apt-get install -y curl && \
    apt-get clean