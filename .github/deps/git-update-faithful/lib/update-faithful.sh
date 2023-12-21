#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/thegittinsgood/git-update-faithful#⛲
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# This intermediate file is used to track the canon SHA across runs,
# before the final commit action.
UPDEPS_CACHE_BASE="${UPDEPS_CACHE_BASE:-${UPDEPS_CACHE_DIR:-.git}/ohmyrepos-update-faithful-cache-}"
# The cache contains PID of process or parent, depending.
UPDEPS_CACHE_FILE="${UPDEPS_CACHE_FILE:-${UPDEPS_CACHE_BASE}$$}"

# Call either set these directly or pass to update-faithful-begin.
UPDEPS_CANON_BASE_ABSOLUTE="${UPDEPS_CANON_BASE_ABSOLUTE}"
UPDEPS_TMPL_SRC_DATA="${UPDEPS_TMPL_SRC_DATA}"
UPDEPS_TMPL_SRC_FORMAT="${UPDEPS_TMPL_SRC_FORMAT}"

# The Git commit title. The body is not customizable.
UPDEPS_GENERIC_COMMIT_SUBJECT="${UPDEPS_GENERIC_COMMIT_SUBJECT:-Deps: Update faithfuls}"

# ***

# Trace message switch.
DTRACE=false
# DEV/YOU: Uncomment to spit trace to stderr.
#  DTRACE=true

# *** Overrideable but probably never will be

UPDEPS_VENV_PREFIX="update-faithful-venv-"

UPDEPS_VENV_FORCE=${UPDEPS_VENV_FORCE:-false}

UPDEPS_TEMP_PREFIX="update-faithful-sh-"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  # Ensure coreutils installed (from Linux pkg mgr, or from macOS Homebrew).
  _upful_insist_cmd 'realpath'

  # Load the logger library, from github.com/landonb/sh-logger.
  # - Includes print commands: info, warn, error, debug.
  source_dep "deps/sh-logger/bin/logger.sh"
  set_logger_log_level

  source_dep_git_put_wise
}

set_logger_log_level () {
  # Note that LOG_LEVEL unset at first, then logger.sh defaults to
  # LOG_LEVEL_ERROR (40), but we want our `info` messages to shine.
  # - Here we let user override our new default (Debug and higher).
  # - This verifies UF_LOG_LEVEL is an integer. Note the -eq spews
  #   when it fails, e.g.:
  #     bash: [: <foo>: integer expression expected
  [ -n "${UF_LOG_LEVEL}" ] \
    && ! [ ${UF_LOG_LEVEL} -eq ${UF_LOG_LEVEL} ] \
    && >&2 echo "WARNING: Resetting UF_LOG_LEVEL, not an integer" \
    && export UF_LOG_LEVEL= \
      || true
  # Default log level: Debug and higher.
  LOG_LEVEL=${UF_LOG_LEVEL:-${LOG_LEVEL_DEBUG}}
}

# Optional: git-put-wise, for 'identify_scope_ends_at'.
#   https://github.com/DepoXy/git-put-wise#🥨
source_dep_git_put_wise () {
  command -v git-put-wise > /dev/null \
    || return 0

  local put_wise_bin="$(dirname "$(realpath "$(command -v git-put-wise)")")"

  # CXREF: https://github.com/landonb/sh-git-nubs#🌰
  #   ~/.kit/sh/sh-git-nubs/bin/git-nubs.sh
  . "${put_wise_bin}/../deps/sh-git-nubs/bin/git-nubs.sh"

  . "${put_wise_bin}/../lib/common_put_wise.sh"
  . "${put_wise_bin}/../lib/dep_apply_confirm_patch_base.sh"
}

# ***

_upful_insist_cmd () {
  local cmd_name="$1"

  command -v "${cmd_name}" > /dev/null && return 0

  >&2 echo "ERROR: Missing system command ‘${cmd_name}’."

  exit 1
}

source_dep () {
  local dep_path="$1"

  # The executables are at bin/*, so project root is one level up.
  local project_root
  project_root="$(dirname "$(realpath "$0")")/.."

  local try_prj_root="${project_root}"
  local try_dep_path="${try_prj_root}/${dep_path}"

  # Walkie talkie die hard.
  while [ ! -f "${try_dep_path}" ]; do
    test "$(dirname "${try_prj_root}")" = "${try_prj_root}" \
      && break

    try_prj_root="$(dirname "${try_prj_root}")"
    try_dep_path="${try_prj_root}/${dep_path}"
  done

  if [ ! -f "${try_dep_path}" ]; then
    # Or maybe user is trying to source from their terminal.
    if $(printf %s "$0" | grep -q -E '(^-?|\/)(ba|da|fi|z)?sh$' -); then
      if [ -n "${BASH_SOURCE[0]}" ]; then
        # The lib is at lib/update-faithful.sh so project root is one level up.
        project_root="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
        try_dep_path="${project_root}/${dep_path}"
      fi
    fi
  fi

  if [ ! -f "${try_dep_path}" ]; then
    >&2 echo "ERROR: Could not identify update-faithful dependency path."
    >&2 echo "- Hint: Did you *copy* bin/update-faithful.sh somewhere on PATH?"
    >&2 echo "  - Please use a symlink instead."
    >&2 echo "- Our incorrect dependency path guess: “${project_root}/${dep_path}”"

    exit 1
  fi

  . "${try_dep_path}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

update-faithful-file () {
  update_faithful_file "$@"
}

update_faithful_file () {
  local local_file="$1"
  # Canon paths are optional.
  # - Default canon file relative path same as local_file (a relative path).
  local canon_file_relative="$2"
  # - Default canon project path what caller set via update-faithful-begin,
  #   or if they set UPDEPS_CANON_BASE_ABSOLUTE directly. Otherwise caller
  #   could override using function arg, but that'd probably be a strange
  #   use case.
  local canon_base_absolute="${3:-${UPDEPS_CANON_BASE_ABSOLUTE}}"

  if [ -z "${canon_file_relative}" ]; then
    canon_file_relative="${local_file}"
  fi

  local canon_file_absolute="${canon_base_absolute}/${canon_file_relative}"

  # ***

  local success=true

  if ${success} && ! must_pass_checks_and_ensure_cache \
    "${canon_base_absolute}" "${canon_file_absolute}" "${local_file}" \
  ; then
    # Soft-fail. Note that must_pass_checks_and_ensure_cache only returns
    # nonzero if canon file has changes (if anything else wrong, it exits).
    success=false
  fi

  # ***

  ! report_done_if_symlink "${local_file}" \
    || return 0

  ! report_done_if_same_file "${local_file}" "${canon_file_absolute}" \
    || return 0

  # ***

  local canon_head
  canon_head="$(print_scoped_head "${canon_file_absolute}")"

  if ${success} && ! examine_and_update_local_from_canon \
    "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${canon_head}" \
  ; then
    success=false
  fi

  if ! ${success}; then
    handle_failed_state "${canon_head}" "${canon_file_absolute}"

    # No callers check return value; they'll happily continue,
    # and should, so they can print one final `rm` command that
    # user can copy-paste to resolve all the issues.
    #
    #  return 1
  fi
}

# ***

must_pass_checks_and_ensure_cache () {
  local canon_base_absolute="$1"
  local canon_file_absolute="$2"
  local local_file="$3"

  local is_update_begin=false
  [ -n "${local_file}" ] || is_update_begin=true
  must_git_nothing_or_only_deletes_staged_or_faithful_update_underway ${is_update_begin}

  cache_file_ensure_exists

  if [ -z "${canon_base_absolute}" ] && [ -z "${canon_file_absolute}" ]; then
    # Path via remove-faithful-file (don't care about rest).
    return 0
  fi

  # Exit if canon path not a directory.
  must_canon_base_is_dir "${canon_base_absolute}"

  if [ -n "${canon_file_absolute}" ]; then
    # Exit if not file and exists.
    must_be_file "${canon_file_absolute}" "reference"

    if [ -n "$(
      cd "${canon_base_absolute}"

      git status --porcelain=v1 -- "${canon_file_absolute}"
    )" ]; then
      # If we don't exit here, user sees "Cannot update changed and divergent follower file"
      # message (warn_diverged_and_uncommitted) which is misleading when it's the canon file's
      # fault, not follower's.
      >&2 error "ERROR: The canon reference file has uncommitted changes: “${canon_file_absolute}”"

      # Rather than exit, let caller cleanup (e.g., unstage changes).
      return 1
    fi
  fi

  if [ -n "${local_file}" ]; then
    # Exit if exists but not file.
    must_be_file_or_absent "${local_file}" "local"

    # For template render or canon copy, ensure directory path exists.
    local local_base
    local_base="$(dirname "${local_file}")"

    command mkdir -p "${local_base}"
  fi
}

# ***

must_git_nothing_or_only_deletes_staged_or_faithful_update_underway () {
  local is_update_begin="$1"

  ( git_nothing_staged \
    || cache_file_nonempty \
  ) && return 0

  # Something is staged, and cache file not started, so this is
  # first update-faithful. If only deletes staged, we assume user
  # git-rm'd divergent files and wants to commit with updates (as
  # opposed to committing git-rm files, running update-faithful,
  # then squashing the two commits).
  if ! git_nothing_staged && git_only_delete_files_staged; then
    # So that we only print the alert once, skip on update-faithful-begin.
    if ! ${is_update_begin}; then
      warn "ALERT: Starting update-faithful on a repo with deletes staged."
      info "- These files will be incorporated into the update-faithful commit:"

      git_print_staged_files
    fi

    return 0
  fi

  warn "ERROR: Cannot start update-faithful on a repo with staged changes."
  warn "- See for yourself:"
  warn "  "
  warn "    cd \"$(pwd)\" && git status"

  exit 1
}

git_nothing_staged () {
  git diff --cached --quiet
}

git_only_delete_files_staged () {
  [ -z "$(git diff --cached --name-status | sed '/^D\t/d')" ]
}

git_print_staged_files () {
  git --no-pager diff --cached --name-only
}

# ***

must_canon_base_is_dir () {
  local canon_base_absolute="$1"

  if [ ! -d "${canon_base_absolute}" ]; then
    >&2 error "ERROR: Canon path not a dir: “${canon_base_absolute}”"
    >&2 error "- HINT: Specify the canon base path before updating:"
    >&2 error "        - Set UPDEPS_CANON_BASE_ABSOLUTE environ"
    >&2 error "        - Or call \`update-faithful-begin\` first"

    exit 1
  fi
}

must_be_file () {
  local file="$1"
  local what="$2"
  local absent_ok="${3:-false}"

  if [ -z "${file}" ]; then
    >&2 error "ERROR: Please specify the update-faithful ${what} file path"

    exit 1
  elif [ ! -f "${file}" ] && ( ! ${absent_ok} || [ -e "${file}" ] ); then
    >&2 error "ERROR: The update-faithful ${what} file path is not a file: “${file}”"

    exit 1
  fi
}

must_be_file_or_absent () {
  local file="$1"
  local what="$2"

  local absent_ok=true

  must_be_file "$1" "$2" ${absent_ok}
}

# ***

# If update-faithful called on a canon project file itself, skip it.
report_done_if_same_file () {
  local local_file="$1"
  local canon_file_absolute="$2"

  # If update-faithful called on a canon project file itself, skip it.
  local local_file_realpath="$(realpath "${local_file}")"
  local canon_file_realpath="$(realpath "${canon_file_absolute}")"

  if [ "${local_file_realpath}" = "${canon_file_realpath}" ]; then
    local what_happn="is canon"

    print_update_faithful_progress_info "${local_file}" "${what_happn}"

    return 0
  fi

  return 1
}

# We don't clobber symlinks (assume user knows what they're doing).
report_done_if_symlink () {
  local local_file="$1"

  if [ -h "${local_file}" ]; then
    local what_happn="isa link"

    print_update_faithful_progress_info "${local_file}" "${what_happn}"

    return 0
  fi

  return 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

examine_and_update_local_from_canon () {
  local local_file="$1"
  local canon_file_absolute="$2"
  local canon_file_relative="$3"
  local canon_head="$4"

  local local_changed=false
  local local_strayed=false
  local local_matches_HEAD=false

  insist_canon_head_consistent "${canon_head}" "${canon_file_absolute}"

  # If ${file} absent, git-status prints nothing and exits zero.
  has_no_changes "${local_file}" \
    || local_changed=true

  # If ${file} absent, diff exits nonzero.
  has_no_diff "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${canon_head}" \
    || local_strayed=true

  # See if local file matches canon's HEAD version.
  local canon_head_private
  canon_head_private="$(print_head_sha "${canon_file_absolute}")"

  if [ "${canon_head}" != "${canon_head_private}" ]; then
    has_no_diff "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${canon_head_private}" \
      && local_matches_HEAD=true || local_matches_HEAD=false
  fi

  # ***

  update_local_from_canon \
    "${local_file}" \
    "${canon_file_absolute}" \
    "${canon_file_relative}" \
    "${canon_head}" \
    "${canon_head_private}" \
    "${local_changed}" \
    "${local_strayed}" \
    "${local_matches_HEAD}"
}

# ***

print_head_sha () {
  local any_repo_file_path="$1"
  local use_scoping="${2:-false}"

  (
    cd "$(dirname "${any_repo_file_path}")"

    local canon_head="HEAD"

    # Optional: git-put-wise scope logic.
    if ${use_scoping} && command -v identify_scope_ends_at > /dev/null; then
      # Exclude latest commits whose messages start with "PRIVATE: " or
      # "PROTECTED: ". Use case: So you can keep some stuff private to
      # your local repo without needing to maintain a separate feature
      # branch.
      canon_head="$( \
        identify_scope_ends_at "^${SCOPING_PREFIX}" "^${PRIVATE_PREFIX}" \
      )"
    fi

    # identify-scope postfixes '^' parent shortcut, but we'll
    # deference for the commit message.

    printf "%s" "$(git rev-parse "${canon_head}")"
  )
}

print_scoped_head () {
  local any_repo_file_path="${1:-.}"

  local use_scoping=true

  print_head_sha "${any_repo_file_path}" "${use_scoping}"
}

# ***

insist_canon_head_consistent () {
  local canon_head="$1"
  local canon_file_absolute="$2"

  cache_file_nonempty \
    || return 0

  local cached_head="$(cache_file_read_cached_head)"

  test "${canon_head}" != "${cached_head}" \
    || return 0

  # We'll leave the repo in its current, failure state,
  # as opposed to cleaning up (`git reset HEAD`, perhaps,
  # and removing the cache file).
  # - This seems like a DEV error, so shouldn't happen
  #   regularly, or really at all, seems like a rarity.

  local projpath="${1:-$(pwd)}"

  >&2 error "ERROR: Latest update-faithful canon HEAD changed?!"
  >&2 error "- Reference file: ${canon_file_absolute}"
  >&2 error "- Cached git ref: ${cached_head}"
  >&2 error "- Latest git ref: ${canon_head}"
  >&2 error "  "
  >&2 error "- You'll need to resolve the issue yourself, and to cleanup:"
  >&2 error "  "
  >&2 error "   cd \"${projpath}\""
  >&2 error "   git reset HEAD"
  >&2 error "   command rm \"${UPDEPS_CACHE_FILE}\""

  exit 1
}

# ***

# Ensure cache exists, so the `awk` are happy.
cache_file_ensure_exists () {
  if ! test -e "${UPDEPS_CACHE_FILE}"; then
    info
    info "┌── Starting update-faithful operation ─── Hold onto your butts!"
    info

    UPDEPS_MELD_CMP_LIST=""
    UPDEPS_CMD_RM_F_LIST=""
    UPDEPS_GIT_RM_F_LIST=""

    # Cleanup old cache files (from failed runs).
    cache_file_cleanup
  fi

  local cache_dir="$(dirname "${UPDEPS_CACHE_FILE}")"

  if [ ! -d "${cache_dir}" ]; then
    >&2 error "ERROR: Cache file directory is absent."
    >&2 error "- UPDEPS_CACHE_FILE: “${UPDEPS_CACHE_FILE}”"

    exit 1
  fi

  touch "${UPDEPS_CACHE_FILE}"
}

cache_file_nonempty () {
  test -s "${UPDEPS_CACHE_FILE}"
}

cache_file_cleanup () {
  # Verify is a partial path name.
  if [ -d "$(dirname "${UPDEPS_CACHE_BASE}")" ] \
    && [ ! -e "${UPDEPS_CACHE_BASE}" ] \
  ; then
    command rm -f "${UPDEPS_CACHE_BASE}"*
  fi
}

cache_file_write () {
  local canon_head="$1"
  local canon_file_absolute="$2"

  local canon_base_absolute="$(print_canon_base_absolute "${canon_file_absolute}")"

  echo -e "${canon_head}\n${canon_base_absolute}" > "${UPDEPS_CACHE_FILE}"
}

cache_file_mark_failed () {
  local canon_head="$1"
  local canon_file_absolute="$2"

  local canon_base_absolute
  canon_base_absolute="$(print_canon_base_absolute "${canon_file_absolute}")"

  if [ -z "${canon_head}" ]; then
    canon_head="$(cache_file_read_cached_head)"
  fi

  if [ -z "${canon_base_absolute}" ]; then
    canon_base_absolute="$(cache_file_read_canon_base_absolute)"
  fi

  echo -e "${canon_head}\n${canon_base_absolute}\nfalse" > "${UPDEPS_CACHE_FILE}"
}

# Note there's a simple awk command to print a specific line number, e.g.,
#   awk 'NR==1' "${UPDEPS_CACHE_FILE}"
# But we'll use printf to avoid exhibiting the newline.
cache_file_read_cached_head () {
  awk 'NR==1 { printf $0 }' "${UPDEPS_CACHE_FILE}"
}

cache_file_read_canon_base_absolute () {
  awk 'NR==2 { printf $0 }' "${UPDEPS_CACHE_FILE}"
}

# Note cache file might be 2 or 3 lines. If 2 lines, infer status ok.
cache_file_read_update_status () {
  if [ ! -f "${UPDEPS_CACHE_FILE}" ]; then
    printf "true"

    return
  fi

  awk 'NR==3 { print $0; found_it = 1; } END { if (!found_it) { print "true"; } }' \
    "${UPDEPS_CACHE_FILE}"
}

# ***

has_no_changes () {
  local file="$1"

  test -z "$(git status --porcelain=v1 -- "${file}")"
}

has_no_diff () {
  local local_file="$1"
  local canon_file_absolute="$2"
  local canon_file_relative="$3"
  local canon_head="$4"

  if ! test -e "${local_file}"; then
    return 0
  fi

  local local_fullpath
  local_fullpath="$(realpath "${local_file}")"

  local tmp_canon_copy
  tmp_canon_copy="$(mktemp -t ${UPDEPS_TEMP_PREFIX}XXXX)"

  canon_path_show_at_canon_head \
    "${canon_file_absolute}" \
    "${canon_file_relative}" \
    "${canon_head}" \
    "${tmp_canon_copy}"

  diff -q "${local_fullpath}" "${tmp_canon_copy}" > /dev/null
}

canon_path_show_at_canon_head () {
  local canon_file_absolute="$1"
  local canon_file_relative="$2"
  local canon_head="$3"
  local dest_file="$4"

  cd "$(dirname "${canon_file_absolute}")"

  # Note that git-show uses the root-relative path, regardless of curr. dir.
  git show ${canon_head}:"${canon_file_relative}" > "${dest_file}"

  if [ $? -ne 0 ]; then
    >&2 error "ERROR: git-show failed:"
    >&2 error
    >&2 error "  git show ${canon_head}:\"${canon_file_relative}\""
    >&2 error
    >&2 error "- HINT: Perhaps you need to commit the file?"
    # TRACK/2023-11-14: git-show failed on me, but worked on next run.
    # - But there was not enough error output to diagnose.
    #   - So we'll run git-show again and dump output to stderr.
    #   - But note, based on what happened today, the git-show
    #     here might actually *work*.
    #     - If you need to diagnose further, you might need to rework the
    #       callers that call this fcn. via `<(process substitution)`.
    #       Instead, you'll want to use a temp file: Then all fcn callers
    #       would call it like `canon_path_show_at_canon_head > tmp_file`
    #       and then we could dump tmp_file if git-show fails (because
    #       we would have saved the error > to the file). (We'd also
    #       have to move the `exit 1` here to each of the callers.)
    >&2 warn
    >&2 warn "- Following is the git-show stdout:"
    >&2 warn
    >&2 cat "${dest_file}"
    >&2 warn

    exit 1
  fi

  cd - >/dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

update_local_from_canon () {
  local local_file="$1"
  local canon_file_absolute="$2"
  local canon_file_relative="$3"
  local canon_head="$4"
  local canon_head_private=$5
  local local_changed=$6
  local local_strayed=$7
  local local_matches_HEAD=$8

  local short_head="$(git_sha_shorten "${canon_head}")"

  # ***

  warn_info_failing () {
    warn_usage_hint_add_meld_compare_cpyst
    warn_usage_hint_delete_local_profit

    warn " │"
    info " └→ Could not update file — Please fix errors and try the update-faithful operation again!"
    info
  }

  print_help_indented_scoped_meld () {
    # This is not a simple "meld \"${local_file}\" \"${canon_file_absolute}\" &"
    # because we need the scoped version of the canon file.
    printf "%s"                      "( cd \"$(dirname "${canon_file_absolute}")\" \\
                                        && meld \\
                                            <(git show ${short_head}:\"${canon_file_relative}\") \\
                                            \"$(pwd)/${local_file}\") &"
  }

  warn_usage_hint_add_meld_compare_cpyst () {
    UPDEPS_MELD_CMP_LIST+="
                                      $(print_help_indented_scoped_meld)"
  }

  warn_usage_hint_delete_local_profit () {
    warn " │   "
    warn " │ - USAGE: Delete the local file if you want the latest source (easy!):"

    if git status --porcelain=v1 -- "${local_file}" | grep -q -e "^??"; then
      warn " │   
                                      cd \"$(pwd -L)\"
                                      command rm \"${local_file}\"
                                      # Try again!
                                      $0"

      UPDEPS_CMD_RM_F_LIST+="${local_file} "
    else
      warn " │   
                                      cd \"$(pwd -L)\"
                                      command rm \"${local_file}\"
                                      # Try again!
                                      $0"

      UPDEPS_GIT_RM_F_LIST+="${local_file} "
    fi
  }

  # ***

  warn_diverged_and_uncommitted () {
    warn
    warn "Cannot update changed and divergent follower file: ${local_file}"
    warn " │ - The follower file has local changes or is not yet committed"
    warn " │   but doesn't match canon."
    warn " │ - Take a look for yourself:"
    warn " │   
                                    cd \"$(pwd -L)\"
                                    $(print_help_indented_scoped_meld)"

    warn_info_failing
  }

  warn_divergent_and_unbaptised () {
    warn
    warn "Cannot update divergent follower file: ${local_file}"
    warn " │ - The local file differs from the latest source file,"
    warn " │   and there's no local reference commit."
    warn " │ - Have you edited this file personally?"
    warn " │ - Take a look for yourself:"
    warn " │   
                                    cd \"$(pwd -L)\"
                                    # The latest commit has no reference SHA:
                                    git --no-pager log --format=%B -n 1 -- \"${local_file}\"
                                    # The local file is tidy but differs from source:
                                    $(print_help_indented_scoped_meld)"

    warn_info_failing
  }

  warn_divergent_now_and_previously () {
    warn
    warn "Cannot update divergent follower file: ${local_file}"
    warn " │ - The follower file does not match latest canon source,"
    warn " │   nor does it match canon from previous update-faithful."
    warn " │ - Have you edited this file personally?"
    warn " │ - Take a look for yourself:"
    warn " │   
                                    cd \"$(pwd -L)\"
                                    # The local file is tidy but differs from source:
                                    $(print_help_indented_scoped_meld)"

    warn_info_failing
  }

  warn_divergent_from_scoped_head_but_matches_HEAD () {
    warn
    warn "Cannot update divergent follower file: ${local_file}"
    warn " │ - The follower file matches latest canon HEAD, but not the"
    warn " │   latest scoped head @ ${canon_head}"
    warn " │ - You likely copied this file from the other project manually,"
    warn " │   or perhaps you're using a hard link."
    warn " │ - Either way, you probably want to delete it, if not also"
    warn " │   scrub it from the commit history!"

    warn_info_failing
  }

  # ***

  _stage_follower () {
    local what_happn="$1"

    stage_follower "${local_file}" "${canon_head}" "${canon_file_absolute}" "${what_happn}"
  }

  # ***

  local success=false

  if [ ! -e "${local_file}" ]; then
    # Note you can `git rm "${local_file}"` and not git-commit,
    # then run update-faithful operation, and it'll commit changes
    # to canon file.
    copy_canon_version "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${canon_head}"

    _stage_follower "baptised"

    success=true
  elif ${local_changed}; then
    if ${local_strayed}; then
      if ${local_matches_HEAD}; then
        # Might have local changes or not be committed yet,
        # but local file matches canon HEAD, so we can overwrite
        # with canon source.
        copy_canon_version "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${canon_head}"

        _stage_follower "overwrit"

        success=true
      else
        # Unpossible to know what to do.
        # - Might have local changes, or might be outside repo still.
        warn_diverged_and_uncommitted

        success=false
      fi
    else
      # Uncommitted changes match canon.
      # - Could be a hard link (how author sometimes manages inter-project
      #   dependencies), whereby the local file *is* the canon file (same
      #   inode), and we just need to commit the changes.
      #   - We *could* `ls -i` and check inodes, but unnecessary.
      _stage_follower "recorded"

      success=true
    fi
  else
    # No local changes.
    if ! ${local_strayed}; then
      # Nothing to do: No changes since last update. Holding steadfast.
      # - Meh. We could add bool arg to tell stage_follower to skip the
      #   git-add, but git-add doesn't care, on file without changes,
      #   prints nothing and returns zero.
      _stage_follower "here yet"

      success=true
    else
      # No local changes, but local strayed, or rather, canon
      # probably strayed. Determine the canon HEAD when the
      # local file was last updated, and see if the local
      # file still matches.
      local prev_canon_head="$(latest_commit_read_canon_head "${local_file}")"

      if [ -z "${prev_canon_head}" ]; then
        warn_divergent_and_unbaptised

        success=false
      else
        local local_diverged=false

        has_no_diff "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${prev_canon_head}" \
          || local_diverged=true

        if ${local_diverged}; then
          # Local file doesn't match canon head version, or previous
          # update-faithful version.
          if ${local_matches_HEAD}; then
            # Local file matches canon HEAD but not scoped head, which likely
            # means user copied private commit from canon repo (or maybe was/
            # is using hard links).
            warn_divergent_from_scoped_head_but_matches_HEAD
          else
            # Local file doesn't match canon HEAD, scoped head, or prev update head.
            warn_divergent_now_and_previously
          fi

          success=false
        else
          # Local file unchanged since last update-faithful,
          # so okay to update to latest canon.
          copy_canon_version "${local_file}" "${canon_file_absolute}" "${canon_file_relative}" "${canon_head}"

          _stage_follower "conveyed"

          success=true
        fi
      fi
    fi
  fi

  ${success} && return 0
}

# ***

copy_canon_version () {
  local local_file="$1"
  local canon_file_absolute="$2"
  local canon_file_relative="$3"
  local canon_head="$4"

  # Delete previous file, in case it's a hard link to canon,
  # so that we don't overwrite canon with an earlier version.
  # - It's up to the caller to remake hard-links.
  command rm -f "${local_file}"

  local tmp_canon_copy
  tmp_canon_copy="$(mktemp -t ${UPDEPS_TEMP_PREFIX}XXXX)"

  # Copy scoped version.
  canon_path_show_at_canon_head \
    "${canon_file_absolute}" \
    "${canon_file_relative}" \
    "${canon_head}" \
    "${tmp_canon_copy}"

  command mv -f "${tmp_canon_copy}" "${local_file}"

  apply_canon_permissions_to_follower "${local_file}" "${canon_file_absolute}"
}

# Note this fcn. not called if only permissions changed, but file contents
# did not. Remove the local file and run again, should fix it.
apply_canon_permissions_to_follower () {
  local local_file="$1"
  local canon_file_absolute="$2"

  # Copy file modes.
  command chmod --reference="${canon_file_absolute}" "${local_file}"
}

stage_follower () {
  local local_file="$1"
  local canon_head="$2"
  local canon_file_absolute="$3"
  local what_happn="$4"

  local update_status="$(cache_file_read_update_status)"

  if ${update_status}; then
    # Note when what_happn="here yet", local_file unchanged, but Git don't care.
    if [ -e "${local_file}" ]; then
      git add "${local_file}"
    fi
    # else, remove-faithful-file ran git-rm.

    if [ $? -ne 0 ]; then
      # E.g., "fatal: pathspec 'foo/bar' is beyond a symbolic link".
      >&2 error "ERROR: See message above: git-add failed"
      >&2 error "  git add \"${local_file}\""

      exit 1
    fi

    # Cache the canon HEAD (it might already be cached, in which
    # case this recreates the cache file, with a new mod. date).
    cache_file_write "${canon_head}" "${canon_file_absolute}"
  fi

  print_update_faithful_progress_info "${local_file}" "${what_happn}" "${update_status}"
}

print_update_faithful_progress_info () {
  local local_file="$1"
  local what_happn="$2"
  local update_status="$3"
  local action_preamble="$4"

  if [ -z "${update_status}" ]; then
    update_status="$(cache_file_read_update_status)"
  fi

  if [ -z "${action_preamble}" ]; then
    if ${update_status}; then
      action_preamble="Follower file"
    else
      action_preamble="Would've been"
    fi
  fi

  info " ${action_preamble} $(font_emphasize "${what_happn}")" \
    "$(font_highlight "$(realpath -s "${local_file}")")"
}

# ***

print_canon_base_absolute () {
  local canon_file_absolute="$1"

  (
    cd "$(dirname "${canon_file_absolute}")"

    git_project_root_absolute
  )
}

git_project_root_absolute () {
  # Same output as git-extras's `git root`.
  git rev-parse --show-toplevel
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

remove-faithful-file () {
  remove_faithful_file "$@"
}

remove_faithful_file () {
  local local_file="$1"
  local canon_base_absolute="${2:-${UPDEPS_CANON_BASE_ABSOLUTE}}"

  if ! must_pass_checks_and_ensure_cache "" "" "${local_file}"; then
    # Soft-fail only happens in canon file has changes, but there was
    # no such file indicated in the args, so this is unexpected path.
    # - If any other check didn't pass, function exited.
    >&2 echo "ERROR: Unxpected path: This must-pass cmd soft-failed:"
    >&2 echo "  must_pass_checks_and_ensure_cache \"\" \"\" \"${local_file}\""

    return 1
  fi

  # What's an eight-letter word for something to be removed that's already
  # removed? Like, it wasn't there in the first place. Considering amongst
  # absentee, departed, ethereal, deceased, vanished, decedent, not many
  # obvious options. Forgo, refrain from, go without. Foregone, went w/out.
  local what_happn="foregone"

  local git_status="$(git status --porcelain=v1 -- "${local_file}")"

  if [ -f "${local_file}" ] || [ "${git_status}" = " D ${local_file}" ]; then
    # This 8-letter word is easier. The file perished. Becuz we perished it.
    what_happn="perished"

    git rm -q "${local_file}"
  fi

  # The calls below (print_scoped_head and stage_follower) will only
  # use the absolute file path to determine the absolute canon directory. I
  # know.
  local canon_fake_absolute="${canon_base_absolute}/ignored"

  local canon_head
  canon_head="$(print_scoped_head "${canon_fake_absolute}")"

  stage_follower "${local_file}" "${canon_head}" "${canon_fake_absolute}" "${what_happn}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

render-faithful-file () {
  render_document_from_template "$@"
}

render_document_from_template () {
  local local_file="$1"
  # Akin to update-faithful-file's canon_file_relative, the relative
  # path to the template file from the canon project directory. If
  # this is just the name of the destination file with a .tmpl ext,
  # it's optional.
  local canon_tmpl_relative="${2:-${local_file%.*}.tmpl}"
  # Usually caller sets UPDEPS_CANON_BASE_ABSOLUTE before first update
  # operation, or sends path to update-faithful-begin, which sets it.
  local canon_base_absolute="${3:-${UPDEPS_CANON_BASE_ABSOLUTE}}"

  local canon_tmpl_absolute="${canon_base_absolute}/${canon_tmpl_relative}"

  local canon_head
  canon_head="$(print_scoped_head "${canon_tmpl_absolute}")"

  insist_canon_head_consistent "${canon_head}" "${canon_tmpl_absolute}"

  if ! must_pass_checks_and_ensure_cache \
    "${canon_base_absolute}" "${canon_tmpl_absolute}" "${local_file}" \
  ; then
    # Only fails if canon file has changes (if anything else wrong, exited).
    handle_failed_state "${canon_head}" "${canon_tmpl_absolute}"

    return 1
  fi

  ! report_done_if_symlink "${local_file}" \
    || return 0

  # For UX purposes, so these few seconds happen at start of updates,
  # callers generally use update-faithful-begin to activate the venv,
  # and this call is a fallback in case they didn't.
  venv_activate_and_prepare

  # Localize template sources.

  local tmp_source_dir
  tmp_source_dir="$(mktemp -d -t ${UPDEPS_VENV_PREFIX}--render_document--XXXX)"

  local tmp_tmpl_absolute="${tmp_source_dir}/${canon_tmpl_relative}"

  render_template_localize_sources \
    "${tmp_source_dir}" "${tmp_tmpl_absolute}" \
    "${canon_tmpl_absolute}" "${canon_tmpl_relative}" \
    "${canon_head}" "${canon_base_absolute}" 

  # Caller is responsible for generating and providing source data.

  local src_data_and_format=""
  if [ -n "${UPDEPS_TMPL_SRC_DATA}" ]; then
    # Meh: Not spaces-in-the-file-path strong.
    src_data_and_format="${UPDEPS_TMPL_SRC_DATA} --format=${UPDEPS_TMPL_SRC_FORMAT:-json}"
  else
    warn "BWARE: No source data supplied. jinja2 will likely fail..."
    warn "- Check that you passed a file path and format to update-faithful-begin"
    warn "  or that you set UPDEPS_TMPL_SRC_DATA and maybe UPDEPS_TMPL_SRC_FORMAT"
  fi

  # Render the template.

  # E.g.,
  #   jinja2 helloworld.tmpl data.json --format=json
  #
  #  echo "jinja2 \"${canon_tmpl_relative}\" ${src_data_and_format} > \"${local_file}\""

  jinja2 \
    "${tmp_tmpl_absolute}" \
    ${src_data_and_format} \
      > "${local_file}"

  command rm -rf "${tmp_source_dir}"

  # ***

  apply_canon_permissions_to_follower "${local_file}" "${canon_tmpl_absolute}"

  # ***

  local what_happn="rendered"

  # Stage the generated file. If template and source data was unchanged,
  # nothing is staged.

  stage_follower "${local_file}" "${canon_head}" "${canon_tmpl_absolute}" "${what_happn}"
}

# ***

# Note that jinja1 won't do process substitution (Bash's <(some-cmd) syntax),
# because `os.path.isfile(filename)` returns False on named pipes, e.g., on
# '/dev/fd/62' (Ref: `get_source` in jinja2/loaders.py). So use a temp file
# for the two inputs — template file, and source data — when generated at
# runtime.
# - To support {% extends <relative-path> %} tags, we'll use a temp directory
#   and recreate the original file names and path (using scoped file versions
#   per git-wise).

render_template_localize_sources () {
  local tmp_source_dir="$1"
  local tmp_tmpl_absolute="$2"
  local canon_tmpl_absolute="$3"
  local canon_tmpl_relative="$4"
  local canon_head="$5"
  local canon_base_absolute="$6"

  local follower_head
  follower_head="$(print_scoped_head)"

  # Prefer local template, otherwise use canon's.
  local chosen_tmpl_path="${canon_tmpl_absolute}"
  local chosen_canon_head="${canon_head}"

  if [ -f "${canon_tmpl_relative}" ]; then
    chosen_tmpl_path="${canon_tmpl_relative}"
    chosen_canon_head="${follower_head}"
  fi

  command mkdir -p "$(dirname "${tmp_tmpl_absolute}")"

  canon_path_show_at_canon_head \
    "${chosen_tmpl_path}" \
    "${canon_tmpl_relative}" \
    "${chosen_canon_head}" \
    "${tmp_tmpl_absolute}"

  print_progress_info_prepared_template "${canon_tmpl_relative}"

  # Look for {% extends %} tags and make templates available locally.
  # - Note that using an absolute path doesn't work, e.g.,
  #   jinja2.exceptions.TemplateNotFound: /absolute/path/to/foo.tmpl
  # - REFER: "The extends tag should be the first tag in the template."
  #   https://jinja.palletsprojects.com/en/3.1.x/templates/#child-template

  local prev_tmpl_absolute="${tmp_tmpl_absolute}"

  local ascending=true

  while ${ascending}; do
    local child_tmpl_relative=""

    local tmp_tmpl_header="$(head -1 "${prev_tmpl_absolute}")"
    local extends_tag_maybe="$(
      echo "${tmp_tmpl_header}" | sed "s/^{% *extends *['\"]\(.*\)['\"] %}\$/\1/"
    )"

    if [ "${tmp_tmpl_header}" != "${extends_tag_maybe}" ]; then
      child_tmpl_relative="${extends_tag_maybe}"
    fi

    if [ -z "${child_tmpl_relative}" ]; then
      ascending=false
    else
      local canon_child_absolute="${canon_base_absolute}/${child_tmpl_relative}"

      local tmp_child_absolute="${tmp_source_dir}/${child_tmpl_relative}"

      prev_tmpl_absolute="${tmp_child_absolute}"

      # Prefer local template, otherwise use canon's.
      local chosen_tmpl_path="${canon_child_absolute}"
      local chosen_canon_head="${canon_head}"

      if [ -f "${child_tmpl_relative}" ]; then
        chosen_tmpl_path="${child_tmpl_relative}"
        chosen_canon_head="${follower_head}"
      fi

      command mkdir -p "$(dirname "${tmp_child_absolute}")"

      canon_path_show_at_canon_head \
        "${chosen_tmpl_path}" \
        "${child_tmpl_relative}" \
        "${chosen_canon_head}" \
        "${tmp_child_absolute}"

      print_progress_info_prepared_template "${child_tmpl_relative}"
    fi
  done
}

print_progress_info_prepared_template () {
  local tmpl_relative="$1"
  
  local action_preamble="Template file"
  local what_happn="prepared"

  print_update_faithful_progress_info "${tmpl_relative}" "${what_happn}" \
    "" "${action_preamble}"
}

# ***

venv_activate_and_prepare () {
  local is_beginning=${1:-false}

  local cmd_name="jinja2"

  # If Python environment looks like one we created, we're good.
  if python -c "import sys; sys.stdout.write(sys.prefix)" \
    | grep -q -e "${UPDEPS_VENV_PREFIX}" \
  ; then
    if ${is_beginning}; then
      info "Our Python venv verified"
    fi

    if ! (_upful_insist_cmd "${cmd_name}" 2> /dev/null); then
      >&2 echo "ERROR: Unexpected path: Our venv, but no ‘${cmd_name}’?"

      exit 1
    fi

    return 0
  fi

  if ! ${UPDEPS_VENV_FORCE}; then
    if (_upful_insist_cmd "${cmd_name}" 2> /dev/null); then
      if ${is_beginning}; then
        info "Using local $(font_emphasize "${cmd_name}") 💨"
      fi

      return 0
    fi
  fi

  printf "%s" "Creating Python venv..."

  venv_activate

  venv_install_jinja2_cli

  printf "\r"
  info "Activated Python venv"
  debug "  └→ HINT: Avoid this wait with your own venv, and:"
  debug "           pip install jinja2-cli"
}

# REFER: https://gist.github.com/cupdike/6a9caaf18f30250364c8fcf6d64ff22e
# - BEGET: https://gist.github.com/csinchok/9714005
venv_activate () {
  local throwaway_dir
  throwaway_dir=$(mktemp -d -t ${UPDEPS_VENV_PREFIX}--venv_activate--XXXX)

  cd "${throwaway_dir}"

  venv_deactivate

  python3 -m venv .venv

  . ./.venv/bin/activate

  pip install --upgrade -q pip
  # ALTLY:
  #   python -m pip install --upgrade --quiet pip

  trap "command rm -rf \"${throwaway_dir}\"" EXIT

  cd - >/dev/null
}

venv_deactivate () {
  # Aka 'off'.
  type deactivate >/dev/null 2>&1 && deactivate || true
}

# TRACK/2023-10-17 19:36: Using single -q so only warnings or worse printed:
# - Without --quiet, prints multiple lines, e.g.,
#     $ pip install jinja2-cli
#     Collecting...
#     ...
#     Successfully installed...
# - With single -q, prints warning, but I think this is a pip regression:
#     $ pip install -q jinja2-cli
#     WARNING: There was an error checking the latest version of pip.
# - With double -qq, inhibits said warning message.
#   - But lets not inhibit that message, because ealier pip doesn't spew
#     it, e.g.,
#       # Exhibits warning:
#       $ pip -V
#       pip 23.3 from ...
#       # Does not exhibit warning:
#       $ pip install -U pip==23.2.1
venv_install_jinja2_cli () {
  # Because I want to "\r" cleanup the (temporary) progress message,
  # and because the "latest version of pip" warning seems erroneous,
  # we'll filter it.
  #
  #   pip install -q jinja2-cli

  local ignore_warning="WARNING: There was an error checking the latest version of pip."

  pip install -q jinja2-cli 2>&1 \
    | grep -v "${ignore_warning}" \
    || true

  # ALTLY:
  #   python -m pip install jinja2-cli
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# It's not necessary to call this function, unless you
# want the venv setup to happen early in the operation.
# Otherwise the first update-faithful-file call ensures
# that the cache exists, and first render-faithful-file
# call sets up the venv.
update-faithful-begin () {
  local canon_base_absolute="${1:-UPDEPS_CANON_BASE_ABSOLUTE}"
  local skip_venv_manage="${2:-false}"
  local tmpl_src_data="${3:-${UPDEPS_TMPL_SRC_DATA}}"
  local tmpl_src_format="${4:-${UPDEPS_TMPL_SRC_FORMAT}}"

  if [ -n "${canon_base_absolute}" ]; then
    UPDEPS_CANON_BASE_ABSOLUTE="${canon_base_absolute:-/}"
  fi

  must_pass_checks_and_ensure_cache "${UPDEPS_CANON_BASE_ABSOLUTE}" "" ""

  if ! ${skip_venv_manage}; then
    local is_beginning=true

    venv_activate_and_prepare ${is_beginning}
  fi

  UPDEPS_TMPL_SRC_DATA="${tmpl_src_data}"
  UPDEPS_TMPL_SRC_FORMAT="${tmpl_src_format}"
}

# ***

update-faithful-finish () {
  update_faithful_finish "$@"
}

update_faithful_finish () {
  local sourcerer="$1"
  local skip_venv_manage="${2:-false}"
  local commit_subject="$3"

  if ! cache_file_nonempty; then
    cache_file_cleanup

    return 0
  fi

  local update_status="$(cache_file_read_update_status)"

  if ${update_status}; then
    if ! git_nothing_staged; then
      local cached_head="$(cache_file_read_cached_head)"

      local canon_base_absolute="$(cache_file_read_canon_base_absolute)"

      update_faithfuls_commit_changes \
        "${cached_head}" \
        "${canon_base_absolute}" \
        "${sourcerer}" \
        "${commit_subject}"

      info
      info "└── Finished update-faithful operation ─── Changes committed!"
      # info
    else
      info
      info "└── Finished update-faithful operation ─── Nothing changed!"
      # info
    fi
  else
    info
    info "└── Finishing update-faithful operation ─── Failed! Please see messages above and try again"
    if test -n "${UPDEPS_CMD_RM_F_LIST}" \
      || test -n "${UPDEPS_GIT_RM_F_LIST}" \
    ; then
      local cleanup_cmd_cpyst""
      local cleanup_git_cpyst""
      if test -n "${UPDEPS_CMD_RM_F_LIST}"; then
        cleanup_cmd_cpyst="
                                      command rm ${UPDEPS_CMD_RM_F_LIST}"
      fi
      if test -n "${UPDEPS_GIT_RM_F_LIST}"; then
        cleanup_git_cpyst="
                                      command rm ${UPDEPS_GIT_RM_F_LIST}"
      fi
      info
      info "    - If you wanna just replace all the conflicts, eh:
                                      cd \"$(pwd -L)\"${UPDEPS_MELD_CMP_LIST}${cleanup_git_cpyst}${cleanup_cmd_cpyst}
                                      # Try again!
                                      $0"
      info
    fi
  fi

  if ! ${skip_venv_manage}; then
    venv_deactivate
  fi

  cache_file_cleanup
}

# ***

update_faithfuls_commit_changes () {
  local cached_head="$1"
  local canon_base_absolute="$2"
  local sourcerer="$3"
  local commit_subject="$4"

  local canon_project="$(basename "${canon_base_absolute}")"

  if [ -z "${commit_subject}" ]; then
    commit_subject="${UPDEPS_GENERIC_COMMIT_SUBJECT} <${canon_project}>"
  fi

  local versiony=""
  if command -v git-bump-version-tag > /dev/null; then
    versiony=" [$(cd "${canon_base_absolute}" && git-bump-version-tag -c)]"
  fi

  local sourcery=""
  if [ -n "${sourcerer}" ]; then
    sourcery="

  under the guidance of:

    ${sourcerer}"
  fi

  # USYNC: The "- Source" commit line here, and the 2 sed commands below.
  echo "\
${commit_subject}

- Source: ${canon_project} @ $(git_sha_shorten "${cached_head}")${versiony}

- Commit generated by:

    https://github.com/thegittinsgood/git-update-faithful#⛲${sourcery}" \
    | git commit -q -F -
}

# The latest update-faithful commit looks something like this:
#
#   Deps: Update faithfuls
#
#   - Source: easy-as-pypi @ 0477f4de66eb [1.2.3]
latest_commit_read_canon_head () {
  local local_file="$1"

  # USYNC: The "- Source" commit line above, and the 2 sed commands.
  git --no-pager log --format=%B -n 1 -- "${local_file}" \
    | head -3 \
    | tail -1 \
    | sed '/^- Source: .* @ /!d' \
    | sed 's/^- Source: .* @ \([[:alnum:]]\+\).*$/\1/'
}

# ***

handle_failed_state () {
  local canon_head="$1"
  local canon_file_absolute="$2"

  # Skip `cache_file_cleanup`, but mark failed, so caller can continue
  # calling update-faithful-file and eventually update-faithful-finish.
  # Then all the successes and failures are printed in one go, and the
  # user can fix everything and will find success on their second run.
  cache_file_mark_failed "${canon_head}" "${canon_file_absolute}"

  git reset HEAD > /dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

font_emphasize () {
  echo "$(attr_emphasis)${1}$(attr_reset)"
}

font_highlight () {
  echo "$(fg_lightorange)${1}$(attr_reset)"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"
unset -f main
unset -f source_deps

