#!/bin/bash

function is_root() {
    if [ "$(echo $USER)" != "root" ]; then
        echo "> You need to be root to run this script!"
        exit 1
    fi
}

function allow_ufw_port() {
    ufw allow ${PORT}/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
}

function delete_allow_ufw_port() {
    ufw delete allow ${PORT}/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
}

function http() {
    allow_ufw_port
    while true; do
        echo "$(curl -s ipv4.icanhazip.com)":"${PORT}"
        echo -e "HTTP/1.1 200 OK\r\n\r\n$(cat ${FILENAME})" | nc -4 -l -p ${PORT} -q 1
    done
}

function help() {
    echo '
USAGE
  bash http.sh [OPTION] [<ARG>]

OPTION
  -h        Show help manual
  -f <path> Input filename path
  -d        Delete allow ufw specify port
              - When you interrupt the http service, you must execute it once!
'
}

function main() {
    is_root

    local PORT="1234"

    local ARG="$1"
    if [ -z "${ARG}" ] || [ "${ARG}" == "-h" ]; then
        help
        exit 0
    fi

    if [ "${ARG}" == "-d" ]; then
        delete_allow_ufw_port
        exit 0
    fi

    if [ "$(echo ${ARG} | cut -c 1)" != "-" ]; then
        echo "http.sh: illegal option -- '${ARG}'"
        help
        exit 0
    fi

    while getopts f: ARG; do
        case "${ARG}" in
        f)
            FILENAME=${OPTARG}
            ;;
        *)
            help
            exit 0
            ;;
        esac
    done

    http
}

main "$@"