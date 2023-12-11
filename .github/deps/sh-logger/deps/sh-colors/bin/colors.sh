#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Project: https://github.com/landonb/sh-colors#💥
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Source this file. Call its functions, e.g., in `echo -e` calls,
# such as:
#
#   echo -e "$(fg_pink)Hello!$(attr_reset) $(attr_underlined)Goodbye!$(attr_reset)"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Ref:
# - "Bash tips: Colors and formatting (ANSI/VT100 Control sequences)"
#   https://misc.flogisoft.com/bash/tip_colors_and_formatting

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Color On/Off controls.

# YOU: To deliberately control whether to color or not, set
#         SHCOLORS_OFF=false|true
#      otherwise, [ -t 1 ] is used when this script is sourced
#      to determine if color should be used. (More specifically,
#      it determines whether to inject ANSI control codes into the
#      output or not, based on whether stdout (1) is attached to a
#      terminal.)

# Set color flag globally, because _hofr_no_color is called in a pipeline
# from within this script, e.g., `_hofr_no_color && return`. And [ -t 1 ]
# won't work therein (will always be falsey).
if [ -z ${SHCOLORS_OFF+x} ]; then
  [ -t 0 ] && [ -t 1 ] &&
    SHCOLORS_OFF=false ||
    SHCOLORS_OFF=true
fi

_hofr_no_color () {
  if [ -z ${SHCOLORS_OFF+x} ]; then
    # Note that in a pipeline, e.g., `_hofr_no_color && return`, [ -t 1 ]
    # will always be false, so generally SHCOLORS_OFF will be set,
    # and this check won't be called. But it's here just in case.
    ! [ -t 1 ]
  else
    ${SHCOLORS_OFF}
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# (lb): In Bash, the escape sequences \e, \033 and \x1b can be used
#       interchangeably, but \033 is the more portable of the 3.
# [QUESTION/2020-09-18: If they're interchangeable, how is one more portable?
#  I think years ago I had issues using \e but I apparently didn't say so here.]
# - The `\e` is a character escape sequence; the other two are Oct.
#   and Hex. reps., respect. (See also ^[, i.e., you can hit Ctrl-[
#   to send ESCAPE sequence. And also 27, the decimal equivalent.)
# - Because the `\e` representation feels more Bashy (and probably is
#   less universal), we'll use either the octal or hexadecimal format.
#   - Let's use the octal format.
#     - A search on "\033" returns 255,000 hits,
#     - A search on "\x1b" returns 74,100 results.
#     - (And on "\e", 4,970,000 results, but that includes
#       "\E NO. 316 - City of Drain" in the top 100 results
#       (AN ORDINANCE FIXING ELECTRICAL RATES).)
#     - Not that we should not always be sheep and follow the
#       masses, but we gotta decide somehow.
# tl,dr: Prefer `\033` below, not `\e` or `\x1b`.
# - And let's not talk about double- versus single-quotes. Single
#   is technically more responsible to signal that you want nothing
#   interpolated, but double looks nicer, IMHO. Though single is
#   easier to type. Such difficult decisions!

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE: tmux does not show all ANSI 256 color codes,
#       but maps some to other colors
#       (like pink and orange to red).
#
#       - For example, when TERM=*-256color, using the
#         256-color lightorange code:
#           printf "\033[38;5;215m"
#         works.
#
#       - But in tmux, when TERM=tmux, that lightorange
#         code maps to red.
#
#       - So we use RGB color formats below, e.g.,
#         for lightorange:
#           printf "\033[38;2;255;175;95m"
#
# - R,G,B Formats:
#
#     \033[38;2;<r>;<g>;<b>m  # RGB foreground color.
#     \033[48;2;<r>;<g>;<b>m  # RGB background color.
#
# - (lb): I used Gimp to extract RGB from
#
#     https://i.stack.imgur.com/KTSQa.png
#     # from 
#     https://en.wikipedia.org/wiki/ANSI_escape_code

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

fg_pink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;211m"
  printf "\033[38;2;255;135;175m"
}

fg_orange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;203m"
  printf "\033[38;2;255;95;95m"
}

fg_skyblue () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;111m"
  printf "\033[38;2;135;175;255m"
}

fg_mediumgrey () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;246m"
  printf "\033[38;2;148;148;148m"
}

fg_lavender () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;183m"
  printf "\033[38;2;215;175;255m"
}

fg_tan () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;179m"
  printf "\033[38;2;215;175;95m"
}

fg_forest () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;22m"
  printf "\033[38;2;0;95;0m"
}

fg_maroon () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;52m"
  printf "\033[38;2;95;0;0m"
}

fg_hotpink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;198m"
  printf "\033[38;2;255;0;135m"
}

fg_mintgreen () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;121m"
  printf "\033[38;2;135;255;175m"
}

fg_lightorange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;215m"
  printf "\033[38;2;255;175;95m"
}

fg_lightred () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;203m"
  printf "\033[38;2;255;95;95m"
}

fg_jade () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;35m"
  printf "\033[38;2;0;175;95m"
}

fg_lime () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;154m"
  printf "\033[38;2;175;255;0m"
}

### background colors

bg_pink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;211m"
  printf "\033[48;2;255;135;175m"
}

bg_orange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;203m"
  printf "\033[48;2;255;95;95m"
}

bg_skyblue () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;111m"
  printf "\033[48;2;135;175;255m"
}

bg_mediumgrey () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;246m"
  printf "\033[48;2;148;148;148m"
}

bg_lavender () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;183m"
  printf "\033[48;2;215;175;255m"
}

bg_tan () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;179m"
  printf "\033[48;2;215;175;95m"
}

bg_forest () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;22m"
  printf "\033[48;2;0;95;0m"
}

bg_maroon () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;52m"
  printf "\033[48;2;95;0;0m"
}

bg_hotpink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;198m"
  printf "\033[48;2;255;0;135m"
}

bg_mintgreen () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;121m"
  printf "\033[48;2;135;255;175m"
}

bg_lightorange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;215m"
  printf "\033[48;2;255;175;95m"
}

bg_lightred () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;203m"
  printf "\033[48;2;255;95;95m"
}

bg_jade () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;35m"
  printf "\033[48;2;0;175;95m"
}

bg_lime () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;154m"
  printf "\033[48;2;175;255;0m"
}

# ***

fg_black () {
  _hofr_no_color && return
  printf "\033[30m"
}

fg_red () {
  _hofr_no_color && return
  printf "\033[31m"
}

fg_green () {
  _hofr_no_color && return
  printf "\033[32m"
}

fg_yellow () {
  _hofr_no_color && return
  printf "\033[33m"
}

fg_blue () {
  _hofr_no_color && return
  printf "\033[34m"
}

fg_magenta () {
  _hofr_no_color && return
  printf "\033[35m"
}

fg_cyan () {
  _hofr_no_color && return
  printf "\033[36m"
}

fg_lightgray () {
  _hofr_no_color && return
  printf "\033[37m"
}

fg_darkgray () {
  _hofr_no_color && return
  printf "\033[90m"
}

fg_lightred () {
  _hofr_no_color && return
  printf "\033[91m"
}

fg_lightgreen () {
  _hofr_no_color && return
  printf "\033[92m"
}

fg_lightyellow () {
  _hofr_no_color && return
  printf "\033[93m"
}

fg_lightblue () {
  _hofr_no_color && return
  printf "\033[94m"
}

fg_lightmagenta () {
  _hofr_no_color && return
  printf "\033[95m"
}

fg_lightcyan () {
  _hofr_no_color && return
  printf "\033[96m"
}

fg_white () {
  _hofr_no_color && return
  printf "\033[97m"
}

bg_black () {
  _hofr_no_color && return
  printf "\033[40m"
}

bg_red () {
  _hofr_no_color && return
  printf "\033[41m"
}

bg_green () {
  _hofr_no_color && return
  printf "\033[42m"
}

bg_yellow () {
  _hofr_no_color && return
  printf "\033[43m"
}

bg_blue () {
  _hofr_no_color && return
  printf "\033[44m"
}

bg_magenta () {
  _hofr_no_color && return
  printf "\033[45m"
}

bg_cyan () {
  _hofr_no_color && return
  printf "\033[46m"
}

bg_lightgray () {
  _hofr_no_color && return
  printf "\033[47m"
}

bg_darkgray () {
  _hofr_no_color && return
  printf "\033[100m"
}

bg_lightred () {
  _hofr_no_color && return
  printf "\033[101m"
}

bg_lightgreen () {
  _hofr_no_color && return
  printf "\033[102m"
}

bg_lightyellow () {
  _hofr_no_color && return
  printf "\033[103m"
}

bg_lightblue () {
  _hofr_no_color && return
  printf "\033[104m"
}

bg_lightmagenta () {
  _hofr_no_color && return
  printf "\033[105m"
}

bg_lightcyan () {
  _hofr_no_color && return
  printf "\033[106m"
}

bg_white () {
  _hofr_no_color && return
  printf "\033[107m"
}

### Colors inspired by Vim dubs_after_dark

# DiffAdd
# -------
#
# https://www.htmlcsscolor.com/hex/00CC00
fg_free_speech_green () {
  _hofr_no_color && return
  printf "\033[38;2;0;204;0m"
}
#
# https://www.htmlcsscolor.com/hex/002200
bg_myrtle () {
  _hofr_no_color && return
  printf "\033[48;2;0;34;0m"
}

# DiffChange
# ----------
#
# https://www.htmlcsscolor.com/hex/FF9955
fg_sunshade () {
  _hofr_no_color && return
  printf "\033[38;2;255;153;85m"
}
#
# https://www.htmlcsscolor.com/hex/220000
bg_seal_brown () {
  _hofr_no_color && return
  printf "\033[48;2;34;0;0m"
}

# DiffDelete
# ----------
#
# [See: fg_red]
#
# [See: bg_seal_brown]

# ***

# Note that you can also use tput to clear formatting, e.g.,
#   $ echo -e "$(fg_green)$(attr_underline)Hello$(tput sgr0), Whirl"
#   Hello, Whirl
#   -----
# (where the "Hello" is formatted).
# However, tput does not appear to inject into the output stream:
#   $ echo "$(fg_green)$(attr_underline)Hello$(tput sgr0), Whirl"
#   \033[32m\033[4mHello, Whirl
# so just to be safe -- so that this function can be used to build
# a string -- use the escape code.
attr_reset () {
  _hofr_no_color && return
  printf "\033[0m"
}

# ***

attr_bold () {
  _hofr_no_color && return
  # See also:
  #   printf "$(tput bold)"
  # - but like noted above, prefer this escape code.
  printf "\033[1m"
}

attr_dim () {
  _hofr_no_color && return
  printf "\033[2m"
}

attr_emphasis () {
  _hofr_no_color && return
  printf "\033[3m"
}

attr_italic () {
  attr_emphasis
}

attr_underline () {
  _hofr_no_color && return
  printf "\033[4m"
}

attr_underlined () {
  attr_underline
}

# Gnome/Mate do not support blink, <sigh>.
attr_blink () {
  _hofr_no_color && return
  printf "\033[5m"
}


attr_invert () {
  # Aka negative image.
  _hofr_no_color && return
  printf "\033[7m"
}

attr_hidden () {
  # Aka invisible image.
  _hofr_no_color && return
  printf "\033[8m"
}

attr_strikethrough () {
  _hofr_no_color && return
  printf "\033[9m"
}

# ***

res_all () { attr_reset; }

res_bold () {
  _hofr_no_color && return
  printf "\033[22m"
}

# (lb): I do not recall what 'dim' means.
res_dim () { res_bold; }

res_emphasis () {
  _hofr_no_color && return
  printf "\033[23m"
}

res_italic () {
  res_emphasis
}

res_underline () {
  _hofr_no_color && return
  printf "\033[24m"
}

res_underlined () {
  res_underline
}

res_blink () {
  _hofr_no_color && return
  printf "\033[25m"
}

res_reverse () {
  # Aka negative image.
  _hofr_no_color && return
  printf "\033[27m"
}

res_hidden () {
  # Aka invisible image.
  _hofr_no_color && return
  printf "\033[28m"
}

# *** Convenience aliases.
if ${SHCOLORS_INCL_RESET_VARIETY:-false}; then
  reset_all () { attr_reset; }
  reset_bold () { res_bold; }
  reset_dim () { res_bold; }
  reset_emphasis () { res_emphasis; }
  reset_italic () { res_italic; }
  reset_underline () { res_underline; }
  reset_underlined () { res_underline; }
  reset_blink () { res_blink; }
  reset_reverse () { res_reverse; }
  reset_hidden () { res_hidden; }
fi

