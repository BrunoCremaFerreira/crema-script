#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "You need to execute devstart with '.' or source."
    echo "Example: . lib.sh"
    exit 0
fi

if command -v docker &>/dev/null; then
    CONTAINER_CMD="docker"
elif command -v podman &>/dev/null; then
    CONTAINER_CMD="podman"
else
    CONTAINER_CMD=""
fi

#Text Decorations
RED='\033[1;31m'
YLL='\033[1;33m'
GRE='\033[1;32m'
NC='\033[0m'

# Script
printLogo()
{
    echo -e "${YLL}"
    cat << "EOF"
                                 (                            
   (                             )\ )                       ) 
   )\   (      (     )       )  (()/(     (   (          ( /( 
 (((_)  )(    ))\   (     ( /(   /(_)) (  )(  )\  `  )   )\())
 )\___ (()\  /((_)  )\  ' )(_)) (_))   )\(()\((_) /(/(  (_))/ 
((/ __| ((_)(_))  _((_)) ((_)_  / __| ((_)((_)(_)((_)_\ | |_  
 | (__ | '_|/ -_)| '  \()/ _` | \__ \/ _|| '_|| || '_ \)|  _| 
  \___||_|  \___||_|_|_| \__,_| |___/\__||_|  |_|| .__/  \__| 
                                                 |_|          

    Copyright (c) 2024 Bruno Crema Ferreira
    OpenSource - MIT License                                                 
    
EOF
echo -e "${NC}"
}


#
# Purpose: Display Message Log
#
log()
{
    local mode=$2
    local message="$1"
    case $mode in
        intro)
            
            printLogo
            echo -e "${YLL}    Script: ${NC}${GRE}$message${NC}"
            echo -e "${YLL}    Version: ${NC}${GRE}$3${NC}"
            echo -e "${YLL}+------------------------------------------------------------------------------+${NC}"
            ;;
        title)
            echo -e "${YLL}+----------------|$message|----------------+${NC}"
            ;;
        success)
            echo -e "${GRE}$message${NC}"
            ;;
        information)
            echo -e "${YLL}$message${NC}"
            ;;
        warning)
            echo -e "${YLL}$message${NC}"
            ;;
        error)
            echo -e "${RED}$message${NC}"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
}

#
# Purpose: Display message and die with given exit code
# 
die(){
        local message="$1"
        local exitCode="$2"
        
        echo ""
        log "$message" error
        log "Script aborted." warning
        echo ""
        exit "${exitCode}"
}

#
# Purpose: Check command dependency
#
checkDependency()
{
    local cmd="$1"
    local cmdName="$2"
    
    if command -v "$cmd" > /dev/null 2>&1; then
        log "[X] $cmdName is installed..." success
        return 0
    else
        log "[ ] $cmdName is not installed..." error
        return 1
    fi
}

#
# Purpose: Check if logged user is root
#
checkIfIsRoot()
{
    #Root Login
    if [ $(id -u) -eq 0 ]
    then 
        log "[X] Running as Root..." success
        return 0
    else
        log "[ ] Not running as Root..." error
        return 1
    fi
}

#
# Purpose: Start Docker Container
#
startContainer()
{
    local containerName="$1"
    if [[ -z "$CONTAINER_CMD" ]]; then
        log "Error: Neither Docker nor Podman is installed." error
        return 1
    fi
    local container_exec
    if [[ "$CONTAINER_CMD" == "docker" ]]; then
        container_exec=(sudo docker)
    else
        container_exec=("$CONTAINER_CMD")
    fi
    log "Starting $containerName container..." information
    if [ ! "$("${container_exec[@]}" ps -q -f name=${containerName})" ];
    then
        "${container_exec[@]}" container start "${containerName}"
    else
        log "Container '${containerName}' already started..." success
    fi
}

#
# Purpose: Stop Docker Container
#
stopContainer()
{
    local containerName="$1"
    if [[ -z "$CONTAINER_CMD" ]]; then
        log "Error: Neither Docker nor Podman is installed." error
        return 1
    fi
    local container_exec
    if [[ "$CONTAINER_CMD" == "docker" ]]; then
        container_exec=(sudo docker)
    else
        container_exec=("$CONTAINER_CMD")
    fi
    log "Stopping ${containerName} container..." information
    if [ ! "$("${container_exec[@]}" ps -q -f name=${containerName})" ];
    then
        log "Container '${containerName}' already stopped..." success
    else
        log "Stopping container '${containerName}'..." success
        "${container_exec[@]}" container stop "${containerName}"
    fi
}