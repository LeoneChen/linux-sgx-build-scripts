#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source ${SCRIPT_DIR}/../env.sh

if [ -z "${LINUX_SGX_SRC_DIR}" ]; then
    echo -e "${RED}LINUX_SGX_SRC_DIR is empty${NC}"
    exit 1
fi

cd ${LINUX_SGX_SRC_DIR}
make clean -s
