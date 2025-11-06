#!/bin/bash

function distribution() {
    local DISTRIBUTION=""

    if [ -f "/etc/debian_version" ]; then
        source /etc/os-release
        DISTRIBUTION="${ID}"
    else
        echo "ERROR: Distribution must be ubuntu!"
        exit 1
    fi
}

function root() {
    if [ "$(echo ${USER})" != "root" ]; then
        echo "WARNING: You must be root to run the script!"
        exit 1
    fi
}

function http() {
    while true; do
        echo "${SERVER_PUBLIC_IPV4}":"${PORT}"
        echo -e "HTTP/1.1 200 OK\r\n\r\n$(cat ${FILE_NAME})" | nc -4 -l -p ${PORT} -q 1
    done
}

function pre_down() {
    ufw delete allow proto tcp from 0.0.0.0/0 to 0.0.0.0/0 port ${PORT}
}

function help() {
    cat <<EOF
USAGE
  bash http.sh [OPTION] [<ARG>]

OPTION
  -h, --help        Show help manual
  -f, --file <path> Input a plain text file name path
EOF
    exit 0
}

function main() {
    distribution
    root

    local SERVER_PUBLIC_IPV4="$(curl -s -4 https://cloudflare.com/cdn-cgi/trace | grep ip | awk -F '=' '{ print $2 }')"
    local PORT="80"
    local FILE_NAME=""

    if [ "$#" -eq 0 ]; then
        help
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                help
                ;;
            -f|--file)
                if [ "$#" -lt 2 ]; then
                    echo "WARNING: Option \"$1\" requires an argument!"
                    exit 1
                fi
                FILE_NAME="$2"
                shift 2
                ;;
            *)
                echo "ERROR: Invalid option \"$1\"!"
                exit 1
                ;;
        esac
    done

    trap pre_down EXIT
    trap pre_down SIGINT
    trap pre_down SIGTERM

    ufw allow proto tcp from 0.0.0.0/0 to 0.0.0.0/0 port ${PORT}
    http
}

main "$@"
