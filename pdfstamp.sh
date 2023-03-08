#! /bin/bash
#
# =============================================================== #
#
# Overlays a pdf with text and date
# By Ginner
#
# Last modified: 2023.03.08-11:55 +0100
#
# =============================================================== #

# Help
read -r -d '' helptext <<- 'EOH'
Overlays the pages of a given pdf with the specified text in big red letters.
If a date is specified, along with another option, the date is put below the
text, if a date is specified alone, it is overlayed as the main text.
Per default, a date (today if none is given) is prepended the filename.

Usage: pdfstamp [OPTIONS] target.pdf

Options:
    -h, --help            Print help and exit.
    -p, --paid            Overlay "PAID" on the specified pdf
    -a, --draft           Overlay "DRAFT"
    -b, --betalt          Overlay "BETALT"
    -f, --foreløbig       Overlay "FORELØBIG"
    -g, --bogført         Overlay "BOGFØRT"
    -d, --today           Add today's date to the overlay, or overlay it as main,
                          if specified alone.
    -C, --custom <TEXT>   Overlay the specified <TEXT>
    -D, --date <DATE>     Add <DATE> to the overlay, or overlay it as main, if
                          specified alone.
    --overwrite           DANGER! Overwrites the <target.pdf>
    -o, --output          Supply an output filename.
    -F, --front           Place the text over the content, default is to put it
                          below.
    -s, --silent          Suppress output.

Example command: pdfstamp -p -d invoice.pdf
    Puts a watermark on 'YYYY-MM-DD_invoice.pdf' saying 'Paid' with today's
    date under
Example 2: pdfstamp -c "Test" -D "2022-04-21" --overwrite invoice.pdf
    Puts the specified, custom stamps on invoice.pdf, overwriting the existing
    file.
EOH

number_of_flags=0
number_of_dates=0

positional=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            echo "$helptext"
            exit 0
            ;;
        -p|--paid)
            text="PAID"
            ((number_of_flags++))
            shift
            ;;
        -a|--draft)
            text="DRAFT"
            ((number_of_flags++))
            shift
            ;;
        -b|--betalt)
            text="BETALT"
            ((number_of_flags++))
            shift
            ;;
        -f|--foreløbig)
            text="FORELOEBIG"
            ((number_of_flags++))
            shift
            ;;
        -g|--bogført)
            text="BOGFOERT"
            ((number_of_flags++))
            shift
            ;;
        -d|--today)
            date="$(/usr/bin/date '+%Y-%m-%d')"
            ((number_of_dates++))
            shift
            ;;
        -C|--custom)
            text="$2"
            ((number_of_flags++))
            shift
            shift
            ;;
        -D|--date)
            date="$2"
            ((number_of_dates++))
            shift
            shift
            ;;
        --overwrite)
            overwrite="1"
            shift
            ;;
        -o|--output)
            output="$2"
            shift
            shift
            ;;
        -F|--front)
            front="1"
            shift
            ;;
        *)
            positional+=("$1")
            shift
            ;;
    esac
done
set -- "${positional[@]}"

if [[ -z "$date" ]]; then
    date="$(/usr/bin/date '+%Y-%m-%d')"
fi

if [[ -z "$text" ]]; then
    text="$date"
    date=""
fi

if [[ -z "$front" ]]; then
    layer="--underlay"
else
    layer="--overlay"
fi

tmp_pdf="/tmp/pdfstamp_$(/usr/bin/tr -dc A-Z0-9 </dev/urandom | head -c 8; echo '').pdf"

# Wow! The following seems to be a pile of dung that I've somehow got stitched
# together and working
read -r -d '' psoverlay <<- !
%!PS
/draft-Bigfont /Helvetica-Bold findfont 108 scalefont def %% Set font sizes
/draft-Midfont /Helvetica-Bold findfont 48 scalefont def
/centreshow {
    /($text) exch def
    ($text) stringwidth pop -2.0 div 0 rmoveto
    ($text) show
    ($text) stringwidth pop -2.0 div -60 rmoveto
    draft-Midfont setfont
    /($date) exch def
    ($date) stringwidth pop -2.0 div 0 rmoveto
    ($date) show
} def
/draft-copy {
    gsave initgraphics
    0 .pushpdf14devicefilter
    .5 .setstrokeconstantalpha
    .5 .setfillconstantalpha
    1.0 0.83 0.83 setrgbcolor
    327 421 moveto
    45 rotate
    draft-Bigfont setfont
    centreshow grestore
} def
595 842 scale
draft-copy showpage
!

# Well, this is kinda stupid, it works however
if [[ -z "$date" ]]; then
    date="$(/usr/bin/date '+%Y.%m.%d')"
fi

echo "$psoverlay" | /usr/bin/gs -dQUIET -dBATCH -dNOPAUSE -dALLOWPSTRANSPARENCY -sDEVICE=pdfwrite -sOutputFile="$tmp_pdf" -

if [[ "$overwrite" == "1" ]]; then
    /usr/bin/qpdf "$1" --replace-input "$layer" "$tmp_pdf" --repeat=1 --
elif [[ -n "$output" ]]; then
    /usr/bin/qpdf "$1" "$layer" "$tmp_pdf" --repeat=1 -- "$output"
else
    /usr/bin/qpdf "$1" "$layer" "$tmp_pdf" --repeat=1 -- "${date}_${1}"
fi

rm "$tmp_pdf"

