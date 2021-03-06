#!/bin/bash

set -Eeuox pipefail

### Configuration ###

# Resultant Appsody container image #
DOCKER_IMAGE="${DOCKER_IMAGE:-image-registry.openshift-image-registry.svc:5000/kabanero}"

# Appsody project GitHub repository #
APP_REPO="${APP_REPO:-https://github.com/kabanero-io/sample-java-microprofile}"

### Tekton Example ###
namespace=kabanero

# Cleanup
oc -n ${namespace} delete pipelinerun java-microprofile-manual-pipeline-run || true
oc -n ${namespace} delete pipelineresource docker-image git-source || true

# Pipeline Resources: Source repo and destination container image
cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: v1
items:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: docker-image
  spec:
    params:
    - name: url
      value: ${DOCKER_IMAGE}
    type: image
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: git-source
  spec:
    params:
    - name: revision
      value: master
    - name: url
      value: ${APP_REPO}
    type: git
kind: List
EOF


# Manual Pipeline Run
cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  name: java-microprofile-manual-pipeline-run
  namespace: kabanero
spec:
  params:
  - name: event-type
    value: push
  - name: event-ref
    value: refs/heads/master
  - name: docker-imagename
    value: java-microprofile-image
  - name: docker-imagetag
    value: latest
  pipelineRef:
    name: java-microprofile-build-deploy-pl
  resources:
  - name: git-source
    resourceRef:
      name: git-source
  - name: docker-image
    resourceRef:
      name: docker-image
  serviceAccountName: kabanero-pipeline
  timeout: 60m
EOF
