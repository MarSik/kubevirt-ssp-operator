#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
RES_DIR=${SCRIPTPATH}/$(basename -s .sh $0)
source ${SCRIPTPATH}/testlib.sh

RET=0
TEST_NS="${KV_NAMESPACE}"

# Test if existing affinities/nodeSelectors/tolerations are propagated to the deployment
echo "[test_id:4860]: Check if Template Validator deployment is created"
oc create -n ${TEST_NS} -f "${RES_DIR}/10-template-validator-affinity-nodeSelector-tolerations.yaml" || exit 2

# Wait for the operator to create the deployment, we don't care if pods are actually ready, as
# we only check for the pod scheduling fields
DEPLOYMENT_FOUND=false
for i in {1..20}; do
  oc get -n ${TEST_NS} deploy virt-template-validator
  EXIT_CODE=$?
  if (( $EXIT_CODE == 0 )); then
    DEPLOYMENT_FOUND=true
    break
  else
    sleep 10
  fi
done

if [ "$DEPLOYMENT_FOUND" == "false" ]; then
  echo "virt-template-validator deployment was not found"
  exit 1
fi

echo "[test_id:4861]: Check if Node selector value is set as expected"
oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec'

NODE_SELECTOR=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.nodeSelector.testKey' | tr -d '"')
if [ "$NODE_SELECTOR" != "testValue" ]; then
  echo $NODE_SELECTOR
  echo "template validator deployment is missing proper nodeSelector"
  RET=1
fi

echo "[test_id:4862]: Check if Tolerations is set as expectedd"
TOLERATION=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.tolerations[0].key' | tr -d '"')
if [ "$TOLERATION" != "testKey" ]; then
  echo $TOLERATION
  echo "template validator deployment is missing proper tolerations"
  RET=1
fi

echo "[test_id:4863]: Check if Affinity is set as expected"
AFFINITY=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key' | tr -d '"')
if [ "$AFFINITY" != "testKey" ]; then
  echo $AFFINITY
  echo "template validator deployment is missing proper affinity"
  RET=1
fi

timeout=300
sample=10
current_time=0

echo "[test_id:4976]: Check if patch is applied without error"
oc patch -n ${TEST_NS} KubevirtTemplateValidator kubevirt-template-validator --type='json' -p='[{"op": "remove", "path": "/spec/affinity"}, {"op": "remove", "path": "/spec/nodeSelector"}, {"op": "remove", "path": "/spec/tolerations"}]'
#wait until operator applies newest configuration

while [ $(oc get -n ${TEST_NS} pods | grep ^virt-template-validator.*Running | wc -l) -lt 2 ] ; do 
  oc get pods
  if [ $current_time -gt $timeout ]; then
    RET=1
    echo "template validator is not in running state"
    break
  fi
  current_time=$((current_time + sample))
  sleep $sample;
done

echo "[test_id:4977]: Check if nodeSelector is set as expected"
NODE_SELECTOR=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.nodeSelector' | tr -d '"')
if [ "$NODE_SELECTOR" != "null" ] && [ "$NODE_SELECTOR" != "{}" ]; then
  echo $NODE_SELECTOR
  echo "template validator deployment is missing proper nodeSelector after update"
  RET=1
fi

echo "[test_id:4978]: Check if tolerations is set as expected"
TOLERATION=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.tolerations' | tr -d '"')
if [ "$TOLERATION" != "null" ] && [ "$TOLERATIONS" != "[]" ]; then
  echo $TOLERATION
  echo "template validator deployment is missing proper tolerations after update"
  RET=1
fi

echo "[test_id:4979]: Check if affinity is set as expected"
AFFINITY=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.affinity' | tr -d '"')
if [ "$AFFINITY" != "null" ] && [ "$AFFINITY" != "{}" ] ; then
  echo $AFFINITY
  echo "template validator deployment is missing proper affinity after update"
  RET=1
fi

oc delete -n ${TEST_NS} -f "${RES_DIR}/10-template-validator-affinity-nodeSelector-tolerations.yaml" || exit 2

# Wait for the deployment from the previous test to be deleted
DEPLOYMENT_DELETED=false
for i in {1..20}; do
  oc get -n ${TEST_NS} deploy virt-template-validator
  EXIT_CODE=$?
  if (( $EXIT_CODE == 1 )); then
    DEPLOYMENT_DELETED=true
    break
  else
    sleep 10
  fi
done

if [ "$DEPLOYMENT_DELETED" == "false" ]; then
  echo "virt-template-validator deployment was not deleted after the previous test"
  exit 1
fi

# Test if empty affinity/nodeSelector/tolerations values are propagated to the deployment
echo "[test_id:4902]: Check if Template Validator Deployment is created"
oc create -n ${TEST_NS} -f "${RES_DIR}/10-template-validator-empty-affinity-nodeSelector-tolerations.yaml" || exit 2

DEPLOYMENT_FOUND=false
for i in {1..20}; do
  oc get -n ${TEST_NS} deploy virt-template-validator
  EXIT_CODE=$?
  if (( $EXIT_CODE == 0 )); then
    DEPLOYMENT_FOUND=true
    break
  else
    sleep 10
  fi
done

if [ "$DEPLOYMENT_FOUND" == "false" ]; then
  echo "virt-template-validator deployment was not found"
  exit 1
fi

echo "[test_id:4903]: Check if Node selector value is set as expected"
oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec'

NODE_SELECTOR=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.nodeSelector' | tr -d '"')
if [ "$NODE_SELECTOR" != "null" ] && [ "$NODE_SELECTOR" != "{}" ]; then
  echo $NODE_SELECTOR
  echo "template validator deployment is missing proper nodeSelector"
  RET=1
fi

echo "[test_id:4904]: Check if Tolerations is set as expectedd"
TOLERATION=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.tolerations' | tr -d '"')
if [ "$TOLERATION" != "null" ] && [ "$TOLERATIONS" != "[]" ]; then
  echo $TOLERATION
  echo "template validator deployment is missing proper tolerations"
  RET=1
fi

echo "[test_id:4905]: Check if Affinity is set as expected"
AFFINITY=$(oc get -n ${TEST_NS} deploy virt-template-validator -ojson | jq '.spec.template.spec.affinity' | tr -d '"')
if [ "$AFFINITY" != "null" ] && [ "$AFFINITY" != "{}" ] ; then
  echo $AFFINITY
  echo "template validator deployment is missing proper affinity"
  RET=1
fi

oc delete -n ${TEST_NS} -f "${RES_DIR}/10-template-validator-empty-affinity-nodeSelector-tolerations.yaml" || exit 2

exit $RET
