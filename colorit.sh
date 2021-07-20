#!/usr/bin/env bash
shopt -s extglob

#SEDOPT=-u

printf -v ESC "\e"

# some of these colors are always bold:
green="${ESC}[00;32m"
red="${ESC}[01;31m"
yellow="${ESC}[00;33m"
cyan="${ESC}[00;36m"
magenta="${ESC}[00;35m"
blue="${ESC}[01;34m"
black="${ESC}[01;30m"
white="${ESC}[00;37m"

italic="${ESC}[03m"
underline="${ESC}[04m"
blink="${ESC}[05m"
hide="${ESC}[08m"
strikethrough="${ESC}[09m"
inverse="${ESC}[07m"
bold="${ESC}[01m"
doubleunderline="${ESC}[21m"
dim="${ESC}[02m"
printf -v bell "\007"
frame="${ESC}[53;04m"

Normal="${ESC}[0m"
reset_italic="${ESC}[23m"
reset_underline="${ESC}[24m"
reset_blink="${ESC}[25m"
reset_hide="${ESC}[28m"
reset_strikethrough="${ESC}[29m"
reset_bold="${ESC}[22m"
reset_dim=${reset_bold}
reset_frame=${reset_underline}"${ESC}[55m"
reset_bell=${bell}

# ugh, 'watch -c' doesn't appear to obey 39m, use full reset
#reset_foreground="${ESC}[39m"
reset_foreground=${Normal}
reset_green=${reset_foreground}
reset_red=${reset_foreground}${reset_bold}
reset_yellow=${reset_foreground}
reset_cyan=${reset_foreground}
reset_magenta=${reset_foreground}
reset_blue=${reset_foreground}${reset_bold}
reset_black=${reset_foreground}${reset_bold}
reset_white=${reset_foreground}

error=${red}${blink}${frame}
reset_error=${reset_red}${reset_error}${reset_blink}${reset_frame}

warning=${red}
reset_warning=${reset_red}

a_lookaheads=()
a_matchstrings=()
a_lookbehinds=()
a_colornames=()
a_colorendnames=()
a_lookbehindcaptures=()

#escmatch=${ESC}'\[[0-9;]+m'
escmatch=.'\[[0-9;]+m'
#zeroesc=$(printf "\(${escmatch}\)\{0\}")

function colorit {
    # do range of default things if no params
    if [[ "$#" -eq 0 ]]; then
        #echo DOING THE DEFAULT THING
        
        # note: [[::space::]]{0,} isn't the same as [[::space::]]* - nongreedy vs greedy?
        #colorit '^((\[[[:space:]0-9.]+\][[:space:]]*)|([[:alnum:]_-.]+:)){1,2}' cyan
        #colorit '^((\[[[:space:]0-9.]+\][[:space:]]*)|( *[[:alnum:]_-.]+(\[[[:digit:]]+\])?:)){1,2}' cyan
        #colorit '^((\[[[:space:]0-9.]+\][[:space:]]*)|( *[[:alnum:]\_\-\.]+(\[[[:digit:]]+\])?:)){1,2}' cyan
        colorit '^((\[[[:space:]0-9.]+\][[:space:]]*)|(( ?[-[:alnum:]_\.])+(\[[[:digit:]]+\])?:)){1,3}' cyan
        # ^ 'fieldname[1]: foo' or '[num.num]... (for dmesg timestamps etc)
        colorit '^|[[:space:](@]' '((Mon|Tue|Wed|Thu|Fri|Sat|Sun)[[:space:]]{1,2}[1,2,3]?[[:digit:]]?[[:space:]]?)?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[[:space:]]{0,2}[123]?[[:digit:]]?[[:space:]]{1,2}([012]?[[:digit:]](:[0-5][[:digit:]]){1,2}[[:space:]]?|[12][90][[:digit:]]{2}[[:space:]]?){1,2}|20[[:digit:]]{2}-[01][0-9]-[0123][0-9]|19[[:digit:]]{2}-[01][0-9]-[0123][0-9]|20[[:digit:]]{2}\/[01]?[0-9]\/[0123]?[0-9]|19[[:digit:]]{2}\/[01]?[0-9]\/[0123]?[0-9]|[01]?[0-9]\/[0123]?[0-9]\/20[[:digit:]]{2}|[01]?[0-9]\/[0123]?[0-9]\/19[[:digit:]]{2}' '\)|[[:space:]]?|$' green
        # ^ long-form date/time.  not really in love with how this still gets processed by the below stand-alone numbers line
        colorit '^|[[:space:](]' '[0-9]+(\.[0-9]+){0,1}' '( ){0,1}([gtmkpx](b|ib)?|[%])(ps|\/s(ec)?)?([,[:space:])]|$)' cyan
        # ^ sizes w/units
        ###colorit '^|[[:space:]]|[^[:alnum:][:cntrl:].:;_]' '0x[a-f0-9]+|#?0|([a-f0-9]{2} ?){4,}|#?[1-9][0-9]*(\.[0-9]+){0,1}' '[^[:alnum:][:cntrl:].;:_]|[[:space:]]|$' dim
        ###colorit '^|[[:space:]]|[^[:alnum:][:cntrl:].:;_]' '0x[a-f0-9]+|#?0|([a-f0-9 ]){2,3}+|xxx#?[1-9][0-9]*(\.[0-9]+){0,1}xxx' '$|[^[:alnum:][:cntrl:][:space:].;:_]' red
        #colorit '^|[[:space:]]|[^[:alnum:][:cntrl:].:;_,]' '[0-9]{1,3}(,[0-9]{3}){1,}|0x[a-f0-9]+|#?0|([a-f0-9]{2} ?){4,}|#?[1-9][0-9]*(\.[0-9]+){0,1}' '[^[:alnum:][:cntrl:].;:_,]|[[:space:]]|$' dim # frustratingly doesn't highlight final hex pair if spaced
        #colorit '^|[[:space:],]|[^[:alnum:][:cntrl:].:;_]' '[0-9]{1,3}(,[0-9]{3})+|0x[a-f0-9]+|#?0|([a-f0-9]{2}){4,}|#?[1-9][0-9]*(\.[0-9]+){0,1}' '[^[:alnum:][:cntrl:].;:_]|[[:space:]]|$' dim # frustratingly doesn't highlight final hex pair if spaced
        #colorit '^|[[:space:],]|[^[:alnum:][:cntrl:].:;_-]' '(-?[1-9][0-9]{0,2}(,[0-9]{3})+|0|-?[0-9]|-|[#-]?[1-9][0-9]*)(\.[0-9]+)?|(0x[a-f0-9]+,?-?)+|[a-f0-9]{2}( ?[a-f0-9]{2}){3,}' ${escmatch}'|[/[:space:],)]|$' dim # without escmatch frustratingly may not highlight final hex pair if spaced?
        colorit '^|[[:space:],]|[^[:alnum:][:cntrl:].:;_-]' '(-?[1-9][0-9]{0,2}(,[0-9]{3})+|0|-?[0-9]|-|[#-]?[1-9][0-9]*)(\.[0-9]+)?|(0x[a-f0-9]+,?-?)+|[a-f0-9]{2}( ?[a-f0-9]{2}){3,}' ${escmatch}'|[]/[:space:],)]|$' dim # without escmatch frustratingly may not highlight final hex pair if spaced?
        # ^ general stand-alone numbers
        #colorit '^|[^[:alnum:][:cntrl:][:space:].:;_]|[[:space:]]' '[a-f0-9]{2}( ?[a-f0-9]{2}){2,}[a-f0-9]{2}' '[^[:alnum:][:cntrl:][:space:].;:_]|[[:space:]]|$' red
        ###colorit '^|[[:space:]]' '[0-9]+(\.[0-9]+){0,1}' '[[:space:]]|$' dim
        #colorit '^|[[:space:]]|[^[:alnum:][:cntrl:].:;_]' '0x[a-f0-9]+|#?0|[a-f0-9]{2}{4,}|#?[1-9][0-9]*(\.[0-9]+){0,1}' '[^[:alnum:][:cntrl:].;:_]|[[:space:]]|$' dim
        # ^ general stand-alone numbers
        colorit '^|[[:space:]]|'${escmatch} '(\.\.|\.[^[:space:]./][^[:space:]/]*)' '[[:space:]]|$' dim
        # ^ .. or .foo
        #colorit '^|[^[:cntrl:]]' '\/\/.*|(\[.{1,}\])|(<.{1,}>)|(\(.{1,}\))|(\{.{1,}\})' '' italic
        colorit '[^'${ESC}']' '\[[^][]+\]|<[^<>]+>|\([^\(\)]+\)|\{[^{}]+\}' '' italic
        # ^ things in various brackets
        colorit '^[[:space:]]*' '#.*|\/\/.*' '' dim
        # ^ single-line comments
        #colorit '^|[[:space:]=>''"]' "\.{0,2}(\/[^[:space:]/'\"]+)+\/?" '[[:space:]''"]|$' yellow
        colorit "^|[[:space:]=>'\"]" "\.{0,2}([/\\][^[:space:]*?/'\"]+)+[/\\]?" "[[:space:]:'\"]|$" yellow
        # ^ paths in optional '' (hmm, something wrong with escaping '? had to switch quotes and escape " instead)
        colorit '^[[:space:]]{0,}' '(%?[[:alpha:]][_/:]?[[:alpha:]]{1,}(%|[0-9])?[[:space:]]{2,200}%?[[:alpha:]]{0,}){2,}' '[[:space:]]{0,}$' underline
        # ^ table headings
        colorit '.\b' '(online$|ok$|up|running|yes$|done$|enabled$)' '\b' green
        #colorit '^|[^[:alnum:][:space:]_][[:space:]]*' '(critical|error|faulted)\b' '' error
        colorit '.\b' '(critical|error|faulted)' '\b' error
        colorit '.\b' '(bug|fault|segfault|crash|degraded$|disabled$)' '\b' warning
        colorit '.\b' '(removed|unavail|down|denied|blocked|ignored|no$)' '\b' magenta
        colorit '^|[^[:alnum:][:space:]_][[:space:]]*'  '(offline)\b' '' blue
        colorit '[[:space:]]|^' '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' '[[:space:]]|$' yellow
        # ^ ipv4
        colorit '[[:space:]]|^' '([0-9a-f]{2,4}:+){4,7}[0-9a-f]{1,4}' '[[:space:]]|$' yellow
        # ^ ipv6
        colorit '[(=,[:space:]]|^' '(`[^`]*`)|('\''[^'\'']*'\'')|(L?)"(\\"|[^"])*"' '[]),[:space:]]|$' yellow
        # ^ L"string" or "string" or "str\"ing" or `string`
        return
    fi
    
    if [[ "$#" -eq 3 || "$#" -eq 4 ]]; then
        # TODO: support $1 and $3 as lookahead/behind
        a_lookaheads+=("${1}")
        matchstring="${2}"
        a_lookbehinds+=("${3}")
        # default color
        colorname=${4:-cyan}
    else
        a_lookaheads+=("")
        matchstring="${1}"
        a_lookbehinds+=("")
        # default match: numbers with optional suffix (%, G, KB, etc)
        [[ -z "${matchstring}" ]] && matchstring='[[:space:]][0-9]+(\.[0-9]+){0,1}([bgtmkp%x]b?)?([[:space:]]|$)'
        # default color
        colorname=${2:-cyan}
    fi
    
    # count non-literal parentheses in matchstring so we know which regex capture numbers to use :(
    
    brackets=${matchstring//[!(]}
    bracketcount=${#brackets}
    #bracketcount=$(printf '%s' "${matchstring}" | grep -F -o "(" | wc -l)
    
    litbrackets="${matchstring//!(*\\\(*)/X}" # note: generates one too many 'X's
    litbracketcount=${#litbrackets}
    (( lookbehindcapture = ${bracketcount} - ${litbracketcount} + 5 ))
    [[ ${lookbehindcapture} -gt 9 ]] && echo 'regex has too many nested captures :( - '"${matchstring}" && exit 1

    #litbracketcount=$(printf '%s' "${matchstring}" | grep -F -o '\(' | wc -l)
    #(( lookbehindcapture = ${bracketcount} - ${litbracketcount} + 4 ))

    #echo $bracketcount $litbracketcount ${lookbehindcapture} "${matchstring}"

    a_matchstrings+=("${matchstring}")
    a_lookbehindcaptures+=("${lookbehindcapture}")
    
    # see if there's a special case for reversing effects of this color so they nest well
    colorendname=reset_${colorname}
    [[ -z "${!colorendname}" ]] && colorendname=Normal

    a_colornames+=(${colorname})
    a_colorendnames+=(${colorendname})
}

colorit "$@"

cmd=(sed ${SEDOPT} -E)
cmd+=( -e s/\\r$//) # dos2unix
for ix in ${!a_matchstrings[*]}
do
    thiscmd=-e\ "s/((${a_lookaheads[$ix]})(${a_matchstrings[$ix]})(${a_lookbehinds[$ix]}))/\2${!a_colornames[$ix]}\3${!a_colorendnames[$ix]}\\${a_lookbehindcaptures[$ix]}/gI"
    cmd+=("${thiscmd}")
    if [[ "" != "${a_lookbehinds[$ix]}" ]]; then
        # second pass for highlights using lookbehind so we can pick up patterns whose lookahead/match expects the lookbehind to have not been consumed
        cmd+=("${thiscmd}")
    fi
    #printf "%d: %s : %s : %s : %s : %s : %s\n" $ix "${a_lookaheads[$ix]}" "${a_matchstrings[$ix]}" "${a_lookbehinds[$ix]}" "${a_colornames[$ix]}" "${a_colorendnames[$ix]}" "${a_lookbehindcaptures[$ix]}"
done

#printf "%s" "${cmd[*]}"
exec "${cmd[@]}" </dev/stdin
