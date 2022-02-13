#!/bin/bash -eu
#
# Description
#   Parse md file and create a html file.
#
# Usage:
#   bash main.sh <MARKDOWN_FILE_NAME>

TEMPLATE_HTML_PATH="template.html"

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

# ===== Feature =====
# $1 is title
function init_output_html() {
    cp "$TEMPLATE_HTML_PATH" "$h1.html"
}
# $1 is title
function end_output_html() {
    echo "</body>" >> "$h1.html"
    echo "</html>" >> "$h1.html"
}
# usage: create_tag_one_block tag_name content
function create_tag_one_block() {
    echo "<$1>$2</$1>" >> "$h1.html"
}

# Check for proper usage
if [ ! -f "$1" ]; then
    print_error_and_usage_and_exit "File $1 doesn't exists"
fi

found_title=false
is_in_code_block=false

line_count=0
while read line
do
    line_count=$(($line_count + 1))

    # ========== code block ==========
    ## === Check if the line is related to a code block ===
    is_quotes_line=false
    if [[ "$line" =~ ^\`\`\`.* ]]; then
        is_quotes_line=true
        # ...  FIXME ...
        # toggle boolean:
        if "$is_in_code_block"; then
            is_in_code_block=false
        else
            is_in_code_block=true
        fi
    fi
    ## === Output ===
    if "$is_quotes_line"; then
        if "$is_in_code_block"; then
            # start code block
            echo -n '<pre class="code-block"><code>' >> "$h1.html"
        else
            # end code block
            echo "</pre></code>" >> "$h1.html"
        fi
    elif "${is_in_code_block}"; then
        echo $line >> "$h1.html"
    fi
    if "$is_quotes_line" || "$is_in_code_block"; then
        continue
    fi

    # ========== h-tag ==========
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
            init_output_html
            create_tag_one_block "h1" "$h1"
            ;;
        2)
            h2=`echo $line | sed "s/^#* //g"`
            create_tag_one_block "h2" "$h2"
            ;;
        3)
            h3=`echo $line | sed "s/^#* //g"`
            create_tag_one_block "h3" "$h3"
            ;;
        *)
            h4_or_more=`echo $line | sed "s/^#* //g"`
            echo "<p style='font-weight:bold'>$h4_or_more</p>" >> "$h1.html"
            ;;
    esac
    if "$is_h_line"; then
        continue
    fi


done < $1

if [ -n "$h1" ]; then
    end_output_html
fi
