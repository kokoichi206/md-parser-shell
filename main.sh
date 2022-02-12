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

found_title=false
line_count=0
while read line
do
    line_count=$(($line_count + 1))

    # ===== h-tag =====
    is_h_line=true
    h_tag_num=$((`echo "$line" | sed -r "s/^(#*) .*/\1/g" | sed "s/^[^#].*//g" | wc -c` - 1))
    case "$h_tag_num" in
        0)
            is_h_line=false
            ;;
        1)
            if [ -n "$h1" ]; then
                echo "Detected another h1-tag at line:$line_count"
                echo "Please use only one h1-tag"
                exit 1
            fi
            # need check file existance??
            h1=`echo $line | sed "s/^#* //g"`
            # Create output html file.
            touch "${h1}.html"
            ;;
        2)
            h2=`echo $line | sed "s/^#* //g"`
            ;;
        3)
            h3=`echo $line | sed "s/^#* //g"`
            ;;
        *)
            h4_or_more=`echo $line | sed "s/^#* //g"`
            ;;
    esac
done < $1
