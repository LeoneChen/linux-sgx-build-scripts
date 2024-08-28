#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source ${SCRIPT_DIR}/../env.sh

# install sgxsdk
${SUDO} ${LINUX_SGX_SRC_DIR}/linux/installer/bin/sgx_linux_x64_sdk_*.bin <<EOF
no
/opt/intel/
EOF

# install sgxpsw
${SUDO} apt-get update
${SUDO} apt-get install libsgx-launch.* libsgx-urts.* libsgx-epid.* libsgx-quote-ex.* libsgx-enclave-common.* libsgx-uae-service.* libsgx-ae-qe3.* libsgx-ae-qve.* libsgx-dcap-ql.* libsgx-dcap-default-qpl.* libsgx-dcap-quote-verify.* libsgx-ra-network.* libsgx-ra-uefi.* libsgx-qe3-logic.* -y