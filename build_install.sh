#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source ${SCRIPT_DIR}/env.sh

if [ -z "${LINUX_SGX_SRC_DIR}" ]; then
    echo -e "${RED}LINUX_SGX_SRC_DIR is empty${NC}"
    exit 1
fi

${SUDO} pwd

COMMON_FLAGS=""
if [ "$DEBUG_BUILD" -eq 1 ]; then
    COMMON_FLAGS+=" DEBUG=1"
fi
echo -e "${YELLOW}COMMON_FLAGS: ${COMMON_FLAGS}${NC}"

#################### enter linux-sgx ####################
echo -e "${CYAN}Enter ${LINUX_SGX_SRC_DIR}${NC}"
cd ${LINUX_SGX_SRC_DIR}

#################### build sgxsdk ####################
# rule "sdk_install_pkg" depends on rule "sdk"
if ls ${LINUX_SGX_SRC_DIR}/linux/installer/bin/sgx_linux_x64_sdk_*.bin
then
    echo -e "${YELLOW}SGX SDK installer already exists${NC}"
else
    echo -e "${CYAN}Build sdk_install_pkg${NC}"
    make sdk_install_pkg ${COMMON_FLAGS} -j${WORKER_NUM} -s
fi

${SUDO} apt-get install build-essential python-is-python3 -y

#################### install sgxsdk ####################
if [ ! -d "${SGX_INSTALL_DIR}/sgxsdk" ]; then
    echo -e "${CYAN}Install SGX SDK at ${SGX_INSTALL_DIR}${NC}"
    ${SUDO} ${LINUX_SGX_SRC_DIR}/linux/installer/bin/sgx_linux_x64_sdk_*.bin <<EOF
no
${SGX_INSTALL_DIR}
EOF
else
    echo -e "${YELLOW}Already installed SGX SDK at ${SGX_INSTALL_DIR}${NC}"
fi
source ${SGX_INSTALL_DIR}/sgxsdk/environment

#################### build sgxpsw (relies on sgxsdk) ####################
# rule "deb_local_repo" depends on rule "deb_psw_pkg" which indirectly depends on rule "psw"
echo -e "${CYAN}Build psw${NC}"
make psw ${COMMON_FLAGS} -j${WORKER_NUM} -s
echo -e "${CYAN}Build deb_psw_pkg${NC}"
make deb_psw_pkg ${COMMON_FLAGS} -j${WORKER_NUM} -s

${SUDO} dpkg -i ${LINUX_SGX_SRC_DIR}/linux/installer/deb/libsgx-urts/libsgx-urts_*_amd64.deb ${LINUX_SGX_SRC_DIR}/linux/installer/deb/libsgx-enclave-common/libsgx-enclave-common_*_amd64.deb

# there is an error when make -j. (https://github.com/intel/linux-sgx/issues/755)
echo -e "${CYAN}Build deb_local_repo${NC}"
make deb_local_repo ${COMMON_FLAGS} -j${WORKER_NUM} -s || make deb_local_repo ${COMMON_FLAGS} -s

#################### install sgxpsw ####################
echo -e "${CYAN}Install SGX PSW${NC}"
${SUDO} apt-get update
${SUDO} apt-get install libssl-dev libcurl4-openssl-dev libprotobuf-dev -y
${SUDO} apt-get install libsgx-launch.* libsgx-urts.* libsgx-epid.* libsgx-quote-ex.* libsgx-enclave-common.* libsgx-uae-service.* libsgx-ae-qe3.* libsgx-ae-qve.* libsgx-dcap-ql.* libsgx-dcap-default-qpl.* libsgx-dcap-quote-verify.* libsgx-ra-network.* libsgx-ra-uefi.* libsgx-qe3-logic.* -y
