#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Project: https://github.com/landonb/sh-logger#🎮🐸
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** <beg boilerplate `source_deps`: ------------------------------|
#                                                                   |

source_deps () {
  local thispth="$1"
  local prefix="."
  local depsnok=false

  _source_it () {
    local prfx="${1:-.}"
    local depd="${2:-.}"
    local file="${3:-.}"
    local path="${prfx}/${depd}/${file}"
    if command -v "${file}" > /dev/null; then
      # Use version found on PATH.
      . "${file}"
    elif [ -f "${path}" ]; then
      # Fallback on local deps/ copy.
      # NOTE: `dash` complains if missing './'.
      . "${path}"
    else
      local depstxt=''
      [ "${prfx}" != "." ] && depstxt="in ‘${prfx}/${depd}’ or "
      >&2 echo "MISSING: ‘${file}’ not found ${depstxt}on PATH."
      depsnok=true
    fi
  }

  # Allow user to symlink executables and not libraries.
  # E.g., `ln -s /path/to/bin/logger.sh /tmp/logger.sh ; /tmp/logger.sh`
  # knows that it can look relative to /path/to/bin/ for sourceable files.
  [ -n "${thispth}" ] && prefix="$(dirname -- "$(realpath -- "${thispth}")")"

  #                                                                 |
  # *** stop boilerplate> ------------------------------------------|

  # https://github.com/landonb/sh-colors
  _source_it "${prefix}" "../deps/sh-colors/bin" "colors.sh"

  # *** <more boilerplate: -----------------------------------------|
  #                                                                 |

  ! ${depsnok}
}

#                                                                   |
# *** end boilerplate `source_deps`> -------------------------------|

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ***

export_log_levels () {
  # The Python logging library defines the following levels,
  # along with some levels I've slid in.
  export LOG_LEVEL_FATAL=50
  # export LOG_LEVEL_FATAL=186 # *sounds more like it
  export LOG_LEVEL_CRITICAL=50
  export LOG_LEVEL_ERROR=40
  # There's a warning() and a warn(), but only one level var.
  export LOG_LEVEL_WARNING=30
  export LOG_LEVEL_NOTICE=25
  export LOG_LEVEL_INFO=20
  export LOG_LEVEL_DEBUG=15
  # (lb): I added LOG_LEVEL_TRACE and LOG_LEVEL_VERBOSE.
  export LOG_LEVEL_TRACE=10
  export LOG_LEVEL_VERBOSE=5
  export LOG_LEVEL_NOTSET=0

  # BWARE/2022-10-13: Note that the first time a caller sources this
  # library, none of the LOG_LEVEL_* values are defined in their
  # environment, so it's not like the caller will have specified
  # LOG_LEVEL yet. Meaning: when sourced for the first time, this
  # library will always default to LOG_LEVEL_ERROR. It's only on
  # a second or subsequent source that this if-block will be
  # skipped (unless the caller unsets the LOG_LEVEL before source).
  # The basic use case is: caller sources this library, then sets
  # LOG_LEVEL, and then any commands they call after that also
  # source this library won't cause the LOG_LEVEL to change.
  if [ -z ${LOG_LEVEL+x} ]; then
    export LOG_LEVEL=${LOG_LEVEL_ERROR}
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_sh_logger_log_msg () {
  local FCN_LEVEL="$1"
  local FCN_COLOR="$2"
  local FCN_LABEL="$3"

  shift 3

  # Verify LOG_LEVEL is an integer. Note the -eq spews when it fails, e.g.:
  #   bash: [: <foo>: integer expression expected
  ! [ "${LOG_LEVEL}" -eq "${LOG_LEVEL}" ] \
    && >&2 echo "WARNING: Resetting LOG_LEVEL, not an integer" \
    && export LOG_LEVEL=

  if [ ${FCN_LEVEL} -ge ${LOG_LEVEL:-${LOG_LEVEL_ERROR}} ]; then
    local RIGHT_NOW
    RIGHT_NOW=$(date "+%Y-%m-%d @ %T")
    local bold_maybe=''
    [ ${FCN_LEVEL} -ge ${LOG_LEVEL_WARNING} ] && bold_maybe=$(attr_bold)
    local invert_maybe=''
    [ ${FCN_LEVEL} -ge ${LOG_LEVEL_WARNING} ] && invert_maybe=$(bg_maroon)
    [ ${FCN_LEVEL} -ge ${LOG_LEVEL_ERROR} ] && invert_maybe=$(bg_hotpink)
    local prefix
    prefix="${FCN_COLOR}$(attr_underline)[${FCN_LABEL}]$(attr_reset) ${RIGHT_NOW} ${bold_maybe}${invert_maybe}"
    (
      local IFS=" "
      printf "${prefix}%b$(attr_reset)\n" "$*"
    )
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

fatal () {
  _sh_logger_log_msg "${LOG_LEVEL_FATAL}" "$(bg_white)$(fg_lightred)$(attr_bold)" FATL "$@"
  # So that errexit can be used to stop execution.
  return 1
}

critical () {
  _sh_logger_log_msg "${LOG_LEVEL_CRITICAL}" "$(bg_pink)$(fg_black)$(attr_bold)" CRIT "$@"
}

error () {
  critical "$@"
}

warning () {
  _sh_logger_log_msg "${LOG_LEVEL_WARNING}" "$(fg_hotpink)$(attr_bold)" WARN "$@"
}

warn () {
  warning "$@"
}

notice () {
  _sh_logger_log_msg "${LOG_LEVEL_NOTICE}" "$(fg_lime)" NOTC "$@"
}

# MAYBE: This 'info' functions shadows /usr/bin/info
# - We could name it `infom`, or something.
# - The author almost never uses `info`.
# - Users can run just `command info ...`.
# - I don't care too much about this either way...
info () {
  _sh_logger_log_msg "${LOG_LEVEL_INFO}" "$(fg_mintgreen)" INFO "$@"
}

debug () {
  _sh_logger_log_msg "${LOG_LEVEL_DEBUG}" "$(fg_jade)" DBUG "$@"
}

trace () {
  _sh_logger_log_msg "${LOG_LEVEL_TRACE}" "$(fg_mediumgrey)" TRCE "$@"
}

verbose () {
  _sh_logger_log_msg "${LOG_LEVEL_VERBOSE}" "$(fg_mediumgrey)" VERB "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

test_sh_logger () {
  fatal "FATAL: I'm gonna die!"
  critical "CRITICAL: Take me to a hospital!"
  error "ERROR: Oops! I did it again!!"
  warn "WARN: This is your last warning."
  warning "WARNING: You will die someday."
  notice "NOTICE: Hear ye, hear ye!!"
  info "INFO: Extra! Extra! Read all about it!!"
  debug "DEBUG: If anyone asks, you're my debugger."
  trace "TRACE: Not a trace."
  verbose "VERBOSE: I'M YELLING AT YOU"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

export_log_funcs () {
  # (lb): This function isn't necessary, but it's a nice list of
  # available functions.
  export -f fatal
  export -f critical
  export -f error
  export -f warning
  export -f warn
  export -f notice
  # NOTE: This 'info' shadows the builtin,
  #       now accessible at `command info`.
  export -f info
  export -f debug
  export -f trace
  export -f verbose
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

this_file_name="logger.sh"
shell_sourced () { [ "$(basename -- "$0")" != "${this_file_name}" ]; }
# Note that bash_sourced only meaningful if shell_sourced is true.
bash_sourced () { declare -p FUNCNAME > /dev/null 2>&1; }

if ! shell_sourced; then
  source_deps "$0"
  LOG_LEVEL=0 test_sh_logger
else
  if bash_sourced; then
    source_deps "${BASH_SOURCE[0]}"
    export_log_funcs
  else
    # Sourced, but not in Bash, so $0 is, e.g., '-dash', and BASH_SOURCE
    # not set. Not our problem; user needs to configure PATH in the case.
    source_deps
  fi
  unset -v this_file_name
  unset -f shell_sourced
  unset -f bash_sourced

  export_log_levels
  unset -f export_log_levels
  unset -f export_log_funcs
fi

