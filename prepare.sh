#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source ${SCRIPT_DIR}/env.sh

if [ -z "${LINUX_SGX_SRC_DIR}" ]; then
    echo -e "${RED}LINUX_SGX_SRC_DIR is empty${NC}"
    exit 1
fi

echo -e "${CYAN}Install dependencies${NC}"
${SUDO} apt-get install build-essential ocaml ocamlbuild automake autoconf libtool wget python-is-python3 libssl-dev git cmake perl -y
${SUDO} apt-get install libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev debhelper cmake reprepro unzip pkgconf libboost-dev libboost-system-dev libboost-thread-dev lsb-release libsystemd0 -y

echo -e "${CYAN}Prepare in ${LINUX_SGX_SRC_DIR}${NC}"
cd ${LINUX_SGX_SRC_DIR}
make preparation
if [ -d "external/toolset/${UBUNTU_DIST}" ]
then
    echo -e "${CYAN}Install toolset for ${UBUNTU_DIST}${NC}"
    ${SUDO} cp external/toolset/${UBUNTU_DIST}/* /usr/local/bin
else
    echo -e "${YELLOW}No toolset for ${UBUNTU_DIST}${NC}"
fi

cd ${PROJECT_DIR}
echo -e "${CYAN}Set APT source${NC}"
SKIP_ENV=1 source ./utils/set_apt_source.sh

if [ ${UBUNTU_NAME} = "noble" ]; then
    echo -e "${CYAN}Patch installer${NC}"
    if ! grep -qF "Codename: noble" ${LINUX_SGX_SRC_DIR}/linux/installer/deb/local_repo_tool/conf/distributions
    then
        patch -p1 -d ${LINUX_SGX_SRC_DIR} < ${PROJECT_DIR}/patch/noble_dist.patch
        echo -e "${CYAN}Patch successfully${NC}"
    else
        echo -e "${YELLOW}Already patched${NC}"
    fi
else
    echo -e "${YELLOW}Needn't patch ${LINUX_SGX_SRC_DIR} for ${UBUNTU_NAME}${NC}"
fi