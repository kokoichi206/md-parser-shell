#!/bin/bash -eu
#
# Usage:
#   bash main.sh <MARKDOWN_FILE_NAME>

function print_usage() {
    echo "======== Usage ========"
    echo "bash main.sh <MARKDOWN_FILE_NAME>"
    echo ""
}

function print_error() {
    ERROR='\033[1;31m'
    NORMAL='\033[0m'
    echo -e "${ERROR}ERROR${NORMAL}: $1"    
}

function print_error_and_usage_and_exit() {
    print_error "$1"
    echo ""
    print_usage
    exit 1
}

# Check for proper usage
if [ ! -f "$1" ]; then
    print_error_and_usage_and_exit "File $1 doesn't exists"
fi

while read line
do
    echo "$line"
done < $1
