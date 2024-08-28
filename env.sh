#!/bin/bash

PROJECT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source ${PROJECT_DIR}/utils/color.sh

_HELP=0
LINUX_SGX_SRC_DIR=""
SUDO="sudo"
DEBUG_BUILD=0
_ROOT_BUILD=0

show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h|--help   Show this help message"
    echo "  -g          Debug build"
    echo "  -i|--src    Source code directory of linux-sgx"
    exit 0
}

_OPTS="$(getopt -o ghi:r -l help,src: -n 'parse-options' -- $@)"
if [ $? != 0 ]; then
    echo "Failed to parse options... exiting." >&2
    exit 1
fi

eval set -- "$_OPTS"
while true; do
case "$1" in
    -h|--help   ) _HELP=1;                              shift 1 ;;
    -g          ) DEBUG_BUILD=1;                        shift 1 ;;
    -i|--src    ) LINUX_SGX_SRC_DIR=$(realpath "$2");   shift 2 ;;
    -r          ) SUDO="";                              shift 1 ;;
    --          )                                       shift; break ;;
    *           )                                       break ;;
esac
done

if [ ${_HELP} -eq 1 ]; then
    show_help
fi

UBUNTU_DIST="ubuntu$(lsb_release -rs)"
UBUNTU_NAME=$(lsb_release -cs)
SGX_INSTALL_DIR="/opt/intel"
WORKER_NUM=$(nproc)

echo -e "${YELLOW}UBUNTU_DIST: ${UBUNTU_DIST}${NC}"
echo -e "${YELLOW}UBUNTU_NAME: ${UBUNTU_NAME}${NC}"
echo -e "${YELLOW}PROJECT_DIR: ${PROJECT_DIR}${NC}"
echo -e "${YELLOW}SGX_INSTALL_DIR: ${SGX_INSTALL_DIR}${NC}"
echo -e "${YELLOW}LINUX_SGX_SRC_DIR: ${LINUX_SGX_SRC_DIR}${NC}"
echo -e "${YELLOW}WORKER_NUM: ${WORKER_NUM}${NC}"
echo -e "${YELLOW}DEBUG_BUILD: ${DEBUG_BUILD}${NC}"
echo -e "${YELLOW}SUDO: ${SUDO}${NC}"
