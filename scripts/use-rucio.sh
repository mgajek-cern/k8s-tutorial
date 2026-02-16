#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

kubectl config set-context --current --namespace=rucio-tutorial

# Detect which storage pods are deployed
echo "┌──────────────────────────────┐"
echo "⟾ Detecting deployed storage │"
echo "└──────────────────────────────┘"
HAS_XRD=false
HAS_S3=false
HAS_DCACHE=false

kubectl get pod xrd1 &>/dev/null && HAS_XRD=true
kubectl get pod s3-1 &>/dev/null && HAS_S3=true
kubectl get pod dcache-1 &>/dev/null && HAS_DCACHE=true

echo "Detected storage: XRootD=${HAS_XRD}, S3=${HAS_S3}, dCache=${HAS_DCACHE}"

echo "┌─────────────────────────────────────────────────────────────────┐"
echo "⟾ kubectl: Rucio - Start client container pod for interactive use │"
echo "└─────────────────────────────────────────────────────────────────┘"
kubectl apply -f ../manifests/client.yaml
kubectl wait --timeout=120s --for=condition=Ready pod/client

echo "┌─────────────────────────────────┐"
echo "⟾ kubectl: Check client container │"
echo "└─────────────────────────────────┘"
kubectl exec client -it -- /etc/profile.d/rucio_init.sh
kubectl exec client -it -- rucio whoami

echo "┌────────────────┐"
echo "⟾ Run Rucio init │"
echo "└────────────────┘"
kubectl exec client -it -- /etc/profile.d/rucio_init.sh

echo "┌─────────────────┐"
echo "⟾ Create the RSEs │"
echo "└─────────────────┘"

# XRootD RSEs (always present if HAS_XRD)
if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio rse add XRD1
  kubectl exec client -it -- rucio rse add XRD2
  kubectl exec client -it -- rucio rse add XRD3
fi

# S3 RSEs (if deployed)
if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio rse add S3_1
  kubectl exec client -it -- rucio rse add S3_2
fi

# dCache RSEs (if deployed)
if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio rse add DCACHE_1
  kubectl exec client -it -- rucio rse add DCACHE_2
fi

echo "┌──────────────────────────────────────────────────────┐"
echo "⟾ Add the protocol definitions for the storage servers │"
echo "└──────────────────────────────────────────────────────┘"

# XRootD protocols
if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio rse protocol add --host xrd1 XRD1 --scheme root --prefix //rucio --port 1094 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
  kubectl exec client -it -- rucio rse protocol add --host xrd2 XRD2 --scheme root --prefix //rucio --port 1094 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
  kubectl exec client -it -- rucio rse protocol add --host xrd3 XRD3 --scheme root --prefix //rucio --port 1094 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
fi

# S3 protocols
if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio rse protocol add --host s3-1 S3_1 --scheme https --prefix /rucio --port 9000 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
  kubectl exec client -it -- rucio rse protocol add --host s3-2 S3_2 --scheme https --prefix /rucio --port 9000 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
fi

# dCache protocols
if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio rse protocol add --host dcache-1 DCACHE_1 --scheme https --prefix /pnfs/rucio --port 2880 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
  kubectl exec client -it -- rucio rse protocol add --host dcache-2 DCACHE_2 --scheme https --prefix /pnfs/rucio --port 2880 --impl rucio.rse.protocols.gfal.Default --domain-json '{"wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}, "lan": {"read": 1, "write": 1, "delete": 1}}'
fi

echo "┌────────────┐"
echo "⟾ Enable FTS │"
echo "└────────────┘"

if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio rse attribute add XRD1 --key fts --value https://fts:8446
  kubectl exec client -it -- rucio rse attribute add XRD2 --key fts --value https://fts:8446
  kubectl exec client -it -- rucio rse attribute add XRD3 --key fts --value https://fts:8446
fi

if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio rse attribute add S3_1 --key fts --value https://fts:8446
  kubectl exec client -it -- rucio rse attribute add S3_2 --key fts --value https://fts:8446
fi

if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio rse attribute add DCACHE_1 --key fts --value https://fts:8446
  kubectl exec client -it -- rucio rse attribute add DCACHE_2 --key fts --value https://fts:8446
fi

echo "┌──────────────────────────┐"
echo "⟾ Configure RSE distances │"
echo "└──────────────────────────┘"

# XRootD mesh
if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio rse distance add XRD1 XRD2 --distance 1
  kubectl exec client -it -- rucio rse distance add XRD1 XRD3 --distance 1
  kubectl exec client -it -- rucio rse distance add XRD2 XRD1 --distance 1
  kubectl exec client -it -- rucio rse distance add XRD2 XRD3 --distance 1
  kubectl exec client -it -- rucio rse distance add XRD3 XRD1 --distance 1
  kubectl exec client -it -- rucio rse distance add XRD3 XRD2 --distance 1
fi

# S3 mesh
if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio rse distance add S3_1 S3_2 --distance 1
  kubectl exec client -it -- rucio rse distance add S3_2 S3_1 --distance 1
fi

# dCache mesh
if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio rse distance add DCACHE_1 DCACHE_2 --distance 1
  kubectl exec client -it -- rucio rse distance add DCACHE_2 DCACHE_1 --distance 1
fi

echo "┌───────────────────────────────────┐"
echo "⟾ Set storage quotas for root      │"
echo "└───────────────────────────────────┘"

if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio account limit add root --rse XRD1 --bytes infinity
  kubectl exec client -it -- rucio account limit add root --rse XRD2 --bytes infinity
  kubectl exec client -it -- rucio account limit add root --rse XRD3 --bytes infinity
fi

if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio account limit add root --rse S3_1 --bytes infinity
  kubectl exec client -it -- rucio account limit add root --rse S3_2 --bytes infinity
fi

if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio account limit add root --rse DCACHE_1 --bytes infinity
  kubectl exec client -it -- rucio account limit add root --rse DCACHE_2 --bytes infinity
fi

echo "┌────────────────────────────────────┐"
echo "⟾ Create a default scope for testing │"
echo "└────────────────────────────────────┘"
kubectl exec client -it -- rucio scope add --account root test

echo "┌──────────────────────────────────────┐"
echo "⟾ Create initial transfer testing data │"
echo "└──────────────────────────────────────┘"
kubectl exec client -it -- dd if=/dev/urandom of=file1 bs=10M count=1
kubectl exec client -it -- dd if=/dev/urandom of=file2 bs=10M count=1
kubectl exec client -it -- dd if=/dev/urandom of=file3 bs=10M count=1
kubectl exec client -it -- dd if=/dev/urandom of=file4 bs=10M count=1

echo "┌──────────────────┐"
echo "⟾ Upload the files │"
echo "└──────────────────┘"

if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio upload --rse XRD1 --scope test file1 file2
  kubectl exec client -it -- rucio upload --rse XRD2 --scope test file3 file4
fi

if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- dd if=/dev/urandom of=s3_file1 bs=10M count=1
  kubectl exec client -it -- rucio upload --rse S3_1 --scope test s3_file1
fi

if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- dd if=/dev/urandom of=dcache_file1 bs=10M count=1
  kubectl exec client -it -- rucio upload --rse DCACHE_1 --scope test dcache_file1
fi

echo "┌──────────────────────────────────────┐"
echo "⟾ Create a few datasets and containers │"
echo "└──────────────────────────────────────┘"

if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio did add --type dataset test:dataset1
  kubectl exec client -it -- rucio did content add -to test:dataset1 test:file1 test:file2
  kubectl exec client -it -- rucio did add --type dataset test:dataset2
  kubectl exec client -it -- rucio did content add -to test:dataset2 test:file3 test:file4
  kubectl exec client -it -- rucio did add --type container test:container
  kubectl exec client -it -- rucio did content add -to test:container test:dataset1 test:dataset2
  kubectl exec client -it -- rucio did add --type dataset test:dataset3
  kubectl exec client -it -- rucio did content add -to test:dataset3 test:file4
fi

if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio did add --type dataset test:s3_dataset
  kubectl exec client -it -- rucio did content add -to test:s3_dataset test:s3_file1
fi

if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio did add --type dataset test:dcache_dataset
  kubectl exec client -it -- rucio did content add -to test:dcache_dataset test:dcache_file1
fi

echo "┌─────────────────────────────────────────────┐"
echo "⟾ Create replication rules                   │"
echo "└─────────────────────────────────────────────┘"

if [[ "${HAS_XRD}" == "true" ]]; then
  kubectl exec client -it -- rucio rule add test:container --rses XRD3 --copies 1
fi

if [[ "${HAS_S3}" == "true" ]]; then
  kubectl exec client -it -- rucio rule add test:s3_dataset --rses S3_2 --copies 1
fi

if [[ "${HAS_DCACHE}" == "true" ]]; then
  kubectl exec client -it -- rucio rule add test:dcache_dataset --rses DCACHE_2 --copies 1
fi

echo "┌────────────────────────────────────────────────────┐"
echo "⟾ Query the status of the rule until it is completed │"
echo "└────────────────────────────────────────────────────┘"
echo "⤑ Waiting 90 seconds for transfers to complete..."
sleep 90

if [[ "${HAS_XRD}" == "true" ]]; then
  RULE_ID=$(kubectl exec client -it -- rucio rule list --did test:container | tail -n 1 | awk '{print $1}')
  echo "XRootD RULE_ID: ${RULE_ID}"
  kubectl exec client -it -- rucio rule show "${RULE_ID}"
fi

if [[ "${HAS_S3}" == "true" ]]; then
  S3_RULE_ID=$(kubectl exec client -it -- rucio rule list --did test:s3_dataset | tail -n 1 | awk '{print $1}')
  echo "S3 RULE_ID: ${S3_RULE_ID}"
  kubectl exec client -it -- rucio rule show "${S3_RULE_ID}"
fi

echo""
echo""
echo""
echo "*** Rucio usage showcase complete. ***"
echo "Storage tested: XRootD=${HAS_XRD}, S3=${HAS_S3}, dCache=${HAS_DCACHE}"