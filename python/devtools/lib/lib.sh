#!/bin/

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "You need to execute devstart with '.' or source."
    echo "Example: . lib.sh"
    exit 0
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
        exit 1
}

#
# Purpose: Check command dependency
#
checkDependency()
{
    local cmd="$1"
    local cmdName="$2"
    
    if [ -x "$(command -v $cmd)" ]; then
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
    log "Starting $containerName container..." information
    if [ ! "$(sudo docker ps -q -f name=${containerName})" ]; 
    then
        sudo docker container start "${containerName}"
    else
        log "Docker container '${containerName}' already started..." success
    fi
}

#
# Purpose: Stop Docker Container
#
stopContainer()
{
    containerName="$1"
    log "Stopping ${containerName} container..." information
    if [ ! "$(sudo docker ps -q -f name=${containerName})" ]; 
    then
        log "Docker container '${containerName}' already stopped..." success
    else
        log "Stopping docker container '${containerName}'..." success
        sudo docker container stop "${containerName}"
    fi
}