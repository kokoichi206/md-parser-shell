#!/bin/bash -eu
#
# Description
#   Parse md file and create a html file.
#
# Usage:
#   bash main.sh <MARKDOWN_FILE_NAME>

PROGRAM=`basename $0`

# ===== print usage =====
function print_usage() {
    echo "Usage: $PROGRAM [OPTION] FILE"
    echo "  -h, --help, -help"
    echo "      print manual"
    echo "  -s, --slide"
    echo "      make slide file"
}
usage_and_exit()
{
    print_usage
    exit $1
}

is_slide=false
# ======================
# parse arguments (options)
# ======================
for i in "$@"; do
    case $i in
    -h | --help | -help)
        usage_and_exit 0
        ;;
    -s | --slide)
        is_slide=true
        shift 1
        ;;
    -*)
        echo "Unknown option $1"
        usage_and_exit 1
        ;;
    *)
        if [[ ! -z "$1" ]] && [[ -f "$1" ]]; then
            FILE="$1"
            shift 1
        fi
        ;;
    esac
done

TEMPLATE_HTML_PATH="templates/template.html"
if "$is_slide"; then
    TEMPLATE_HTML_PATH="templates/template_slide.html"
fi
# this is re-set when find h1-tag is found.
OUTPUT_PATH="output.html"

# ===== print error =====
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
function init_output_html() {
    cp "$TEMPLATE_HTML_PATH" "$OUTPUT_PATH"
}
# usage: create_tag_one_block tag_name content
function create_tag_one_block() {
    if [[ "$2" =~ (.*)\[(.*)\]\((.*)\) ]]; then
        echo "<$1>`create_a_tag ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}`</$1>" >> "$OUTPUT_PATH"
    else
        echo "<$1>$2</$1>" >> "$OUTPUT_PATH"
    fi
}
# Create a-tag $1: title, $2: link
function create_a_tag() {
    echo "<a href=\"$2\">$1</a>"
}
function init_slide_one_page() {
    start_container $1
    # left arrow
    if [[ "$1" != 1 ]]; then
        create_left_arrow $1
    fi
    create_right_arrow $1
    start_content
}
function start_container() {
    if [[ "$1" == 1 ]]; then
        echo "<div class='container' id=$1>" >> "$OUTPUT_PATH"
    else
        echo "<div class='container hidden' id=$1>" >> "$OUTPUT_PATH"
    fi
}
function create_left_arrow() {
    echo "<div class='left-arrow' onclick='previous_page($1)'>" >> "$OUTPUT_PATH"
    echo '<div class="hovicon effect-4 sub-b">' >> "$OUTPUT_PATH"
    echo '&lt;' >> "$OUTPUT_PATH"
    echo '</div>' >> "$OUTPUT_PATH"
    echo '</div>' >> "$OUTPUT_PATH"
}
function create_right_arrow() {
    echo "<div class='right-arrow' onclick='next_page($1)'>" >> "$OUTPUT_PATH"
    echo '<div class="hovicon effect-4 sub-b">' >> "$OUTPUT_PATH"
    echo '&gt;' >> "$OUTPUT_PATH"
    echo '</div>' >> "$OUTPUT_PATH"
    echo '</div>' >> "$OUTPUT_PATH"
}
function start_content() {
    echo '<div class="content">' >> "$OUTPUT_PATH"
}

function close_slide_one_page() {
    echo '</div>' >> "$OUTPUT_PATH"
    echo '</div>' >> "$OUTPUT_PATH"
}
function create_closing_slide() {
    start_container $(($slide_num + 1))
    # only left arrow
    create_left_arrow $(($slide_num + 1))
    start_content
    create_tag_one_block "h1" "Thank you!"
    close_slide_one_page
}
function end_output_html() {
    if "$is_slide"; then
        close_slide_one_page
        create_closing_slide
        echo "</div>" >> "$OUTPUT_PATH"
    fi
    echo "</body>" >> "$OUTPUT_PATH"
    echo "</html>" >> "$OUTPUT_PATH"
}

# ======================
# Check for proper usage
# ======================
if [ ! -f "$FILE" ]; then
    print_error_and_usage_and_exit "File $FILE doesn't exists"
fi

found_title=false
is_in_code_block=false
is_in_bullets=false
bullets_type="ul"
slide_num=0

# ======================
# parse markdown file
# ======================
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
            echo -n '<pre class="code-block"><code>' >> "$OUTPUT_PATH"
        else
            # end code block
            echo "</pre></code>" >> "$OUTPUT_PATH"
        fi
    elif "${is_in_code_block}"; then
        echo $line >> "$OUTPUT_PATH"
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
            if "$is_slide"; then
                OUTPUT_PATH="${h1}_slide.html"
            else
                OUTPUT_PATH="$h1.html"
            fi
            # Create output html file.
            init_output_html
            slide_num=$(($slide_num + 1))
            if "$is_slide"; then
                init_slide_one_page "$slide_num"
            fi
            create_tag_one_block "h1" "$h1"
            ;;
        2)
            h2=`echo $line | sed "s/^#* //g"`
            slide_num=$(($slide_num + 1))
            if "$is_slide"; then
                close_slide_one_page
                init_slide_one_page $slide_num 
            fi
            create_tag_one_block "h2" "$h2"
            ;;
        3)
            h3=`echo $line | sed "s/^#* //g"`
            create_tag_one_block "h3" "$h3"
            ;;
        *)
            h4_or_more=`echo $line | sed "s/^#* //g"`
            echo "<p style='font-weight:bold'>$h4_or_more</p>" >> "$OUTPUT_PATH"
            ;;
    esac
    if "$is_h_line"; then
        continue
    fi

    # ========== bullet points ==========
    if [[ "$line" =~ ^"- [ ] ".* ]]; then
        # CheckBox
        if "$is_slide"; then
            echo '<div class="checkbox">' >> "$OUTPUT_PATH"
        fi    
        echo '<input type="checkbox" id="test" />' >> "$OUTPUT_PATH"
        item=`echo $line | sed "s/^- \[ \] //g"`
        echo "<label for='test'>${item}</label><br />" >> "$OUTPUT_PATH"
        if "$is_slide"; then
            echo "</div>" >> "$OUTPUT_PATH"
        fi
        continue
    elif [[ "$line" =~ ^"- ".* ]]; then
        if "$is_in_bullets"; then
            # already bullets are started
            create_tag_one_block "li" `echo $line | sed "s/^- //g"`
            continue
        else
            # start new bullets
            bullets_type=ul
            echo "<$bullets_type>" >> "$OUTPUT_PATH"
            create_tag_one_block "li" `echo $line | sed "s/^- //g"`
            is_in_bullets=true
            continue
        fi
    elif [[ "$line" =~ ^[0-9]+." ".* ]]; then
        if "$is_in_bullets"; then
            # already bullets are started
            create_tag_one_block "li" `echo $line | sed -E "s/^[0-9]+. //g"`
            continue
        else
            # start new bullets
            bullets_type=ol
            echo "<$bullets_type>" >> "$OUTPUT_PATH"
            create_tag_one_block "li" `echo $line | sed -E "s/^[0-9]+. //g"`
            is_in_bullets=true
            continue
        fi
    fi

    # normal input?
    create_tag_one_block "p" "$line"

    # when the line is empty
    if [ -z "$line" ]; then
        if "$is_in_bullets"; then
            # close bullets
            echo "</$bullets_type>" >> "$OUTPUT_PATH"
            is_in_bullets=false
        fi
    fi
done < $FILE

# ======================
# post-processing
# ======================
if [ -n "$h1" ]; then
    if "$is_in_bullets"; then
        # close bullets
        echo "</$bullets_type>" >> "$OUTPUT_PATH"
    fi
    end_output_html
fi
