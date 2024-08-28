#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
if [ ${SKIP_ENV} -eq 1 ]; then
    echo -e "${YELLOW}Skip source env.sh${NC}"
else
    source ${SCRIPT_DIR}/../env.sh
fi

${SUDO} mkdir -p /etc/apt/sources.list.d
INTEL_SGX_LIST=/etc/apt/sources.list.d/intel-sgx.list

if [ -f ${INTEL_SGX_LIST} ]
then
    echo -e "${CYAN}${INTEL_SGX_LIST} already exist${NC}"
else
    ${SUDO} touch ${INTEL_SGX_LIST}
    ${SUDO} sh -c "echo \"deb [trusted=yes arch=amd64] file:${LINUX_SGX_SRC_DIR}/linux/installer/deb/sgx_debian_local_repo ${UBUNTU_NAME} main\" >> ${INTEL_SGX_LIST}"
    echo -e "${CYAN}Successfully add ${INTEL_SGX_LIST}${NC}"
    cat ${INTEL_SGX_LIST}
fi
