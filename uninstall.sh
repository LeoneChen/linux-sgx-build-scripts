#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source ${SCRIPT_DIR}/env.sh

SGXSDK_DIR=${SGX_INSTALL_DIR}/sgxsdk

echo -e "${CYAN}Remove SGX SDK at ${SGXSDK_DIR}${NC}"
if [ -f "${SGXSDK_DIR}/uninstall.sh" ]
then
    ${SUDO} ${SGXSDK_DIR}/uninstall.sh
else
    ${SUDO} rm -rf ${SGXSDK_DIR}
fi

echo -e "${CYAN}Remove SGX PSW${NC}"
${SUDO} apt-get purge libsgx-.* sgx-.* -y
