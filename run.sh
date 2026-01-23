#!/bin/bash
set -e

PROJ_DIR=$(realpath $(dirname $0))
TARGET_DIR=""
INSTALL_DIR="/opt/intel"
OUTPUT_PATH="${PROJ_DIR}/operation.log"
APT_SOURCE=/etc/apt/sources.list.d/intel-sgx.list

DEBUG=0
CMD=""
WORKER=1
UBUNTU_DIST="ubuntu$(lsb_release -rs)"
UBUNTU_NAME=$(lsb_release -cs)

show_help() {
    echo "Usage: $0 -t|--target <target_directory> -c|--cmd <command> [-g] [-h|--help]"
    echo ""
    echo "Options:"
    echo "  -t, --target   Specify the target directory containing the SGX source code."
    echo "  -c, --cmd      Command to execute. Options are: prepare | build | uninstall | unprepare | apt | install"
    echo "  -g             Enable debug mode (optional)."
    echo "  -h, --help     Show this help message."
}

OPTS="$(getopt -o ght:c: -l help,target:,cmd: -n 'parse-options' -- $@)"
eval set -- "$OPTS"
while true; do
    case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -g)
        DEBUG=1
        shift
        ;;
    -t|--target)
        TARGET_DIR=$(realpath "$2")
        shift 2
        ;;
    -c|--cmd)
        CMD=$2
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        show_help
        exit 1
        ;;
    esac
done

if [ -z "${TARGET_DIR}" ]; then
    show_help
    exit 1
fi

echo "==========" >> ${OUTPUT_PATH}
echo "- ${UBUNTU_DIST} ${UBUNTU_NAME}" >> ${OUTPUT_PATH}
echo "- PROJ_DIR: ${PROJ_DIR}" >> ${OUTPUT_PATH}
echo "- INSTALL_DIR: ${INSTALL_DIR}" >> ${OUTPUT_PATH}
echo "- TARGET_DIR: ${TARGET_DIR}" >> ${OUTPUT_PATH}
echo "- WORKER: ${WORKER}" >> ${OUTPUT_PATH}
echo "- DEBUG: ${DEBUG}" >> ${OUTPUT_PATH}

case "${CMD}" in
    "prepare")
        sudo apt-get install -y build-essential ocaml ocamlbuild automake autoconf libtool wget python-is-python3 git perl protobuf-compiler debhelper reprepro unzip pkgconf lsb-release libssl-dev libcurl4-openssl-dev libprotobuf-dev libboost-dev libboost-system-dev libboost-thread-dev libsystemd0 fakeroot cmake
        sudo mkdir -p /etc/init

        pushd ${TARGET_DIR}
            echo "[+] Prepare in ${TARGET_DIR}" >> ${OUTPUT_PATH}
            make preparation
            if [ -d "external/toolset/${UBUNTU_DIST}" ]; then
                echo "[+] Install toolset for ${UBUNTU_DIST}" >> ${OUTPUT_PATH}
                sudo cp external/toolset/${UBUNTU_DIST}/* /usr/local/bin
            else
                echo "[!] No toolset for ${UBUNTU_DIST}" >> ${OUTPUT_PATH}
            fi
        popd
        ;;
    "build")
        sudo pwd
        if [ $DEBUG -eq 1 ]; then
            export DEB_BUILD_OPTIONS=nostrip
            COMMON_FLAGS="DEBUG=1"
        fi
        echo "- COMMON_FLAGS: ${COMMON_FLAGS}" >> ${OUTPUT_PATH}
        pushd ${TARGET_DIR}
            if ls linux/installer/bin/sgx_linux_x64_sdk_*.bin; then
                echo "[!] SGX SDK installer already exists" >> ${OUTPUT_PATH}
            else
                echo "[+] Build SGX SDK" >> ${OUTPUT_PATH}
                make sdk_install_pkg_no_mitigation USE_OPT_LIBS=3 ${COMMON_FLAGS} -j${WORKER}
            fi

            if [ -d "${INSTALL_DIR}/sgxsdk" ]; then
                echo "[!] Already installed SGX SDK at ${INSTALL_DIR}" >> ${OUTPUT_PATH}
            else
                echo "[+] Install SGX SDK at ${INSTALL_DIR}" >> ${OUTPUT_PATH}
                sudo linux/installer/bin/sgx_linux_x64_sdk_*.bin --prefix ${INSTALL_DIR}
            fi
            source ${INSTALL_DIR}/sgxsdk/environment

            echo "[+] Build SGX PSW" >> ${OUTPUT_PATH}
            make psw ${COMMON_FLAGS} -j${WORKER}
            echo "[+] -> deb_psw_pkg" >> ${OUTPUT_PATH}
            make deb_psw_pkg ${COMMON_FLAGS}
            sudo dpkg -i linux/installer/deb/libsgx-urts/libsgx-urts_*_amd64.deb linux/installer/deb/libsgx-enclave-common/libsgx-enclave-common_*_amd64.deb
            echo "[+] -> deb_local_repo" >> ${OUTPUT_PATH}
            make deb_local_repo ${COMMON_FLAGS}

            echo "[+] Install SGX PSW" >> ${OUTPUT_PATH}
            sudo cp -r linux/installer/deb/sgx_debian_local_repo /opt/sgx_debian_local_repo
            sudo apt-get update
            sudo apt-get install -y libsgx-.* sgx-.*
        popd
        ;;
    "uninstall")
        echo "[!] Remove SGX SDK at ${INSTALL_DIR}/sgxsdk" >> ${OUTPUT_PATH}
        if [ -f "${INSTALL_DIR}/sgxsdk/uninstall.sh" ]
        then
            sudo ${INSTALL_DIR}/sgxsdk/uninstall.sh
        else
            sudo rm -rf ${INSTALL_DIR}/sgxsdk
        fi

        echo "[!] Remove SGX PSW" >> ${OUTPUT_PATH}
        sudo apt-get purge libsgx-.* sgx-.* -y
        sudo rm -rf /opt/sgx_debian_local_repo
        ;;
    "unprepare")
        echo "[!] Remove toolset and apt sources" >> ${OUTPUT_PATH}
        sudo rm -f /usr/local/bin/{ar,as,ld,ld.gold,objcopy,objdump,ranlib} /etc/apt/sources.list.d/intel-sgx.list

        pushd ${TARGET_DIR}
            echo "[!] Restore ${TARGET_DIR}" >> ${OUTPUT_PATH}
            make distclean -s
            git restore .
            git clean -ffdx
        popd
        ;;
    "apt")
        sudo mkdir -p $(dirname ${APT_SOURCE})
        if [ -f ${APT_SOURCE} ]; then
            echo "[!] ${APT_SOURCE} already exist" >> ${OUTPUT_PATH}
        else
            echo "deb [trusted=yes arch=amd64] file:/opt/sgx_debian_local_repo ${UBUNTU_NAME} main" | sudo tee ${APT_SOURCE}
            echo "[+] Successfully add ${APT_SOURCE}" >> ${OUTPUT_PATH}
        fi
        ;;
    "install")
        sudo ${TARGET_DIR}/linux/installer/bin/sgx_linux_x64_sdk_*.bin --prefix ${INSTALL_DIR}
        sudo apt-get update
        sudo apt-get install -y libsgx-.* sgx-.*
        ;;
    *)
        echo "Unknown command: ${CMD}"
        exit 1
        ;;
esac
