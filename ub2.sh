#!/bin/bash

error() { echo -e "\e[1;31mERROR:\e[0;31m $@\e[0m\n"; exit 1; }
warn() { echo -e "\e[1;33mWARNING:\e[0;33m $@\e[0m"; }
success() { echo -e "\e[1;32mSUCCESS:\e[0;32m $@\e[0m"; }
info() { echo -e "\e[1;34mINFO:\e[0;34m $@\e[0m"; }

declare -A arg_aliases=(
  [b]=build
  [x]=execute
  [B]=build_exec
  [l]=live
  [H]=headers
  [f]=flags
  [X]=bin_path
  [L]=lib_path
  [T]=tests_path
  [a]=args
  [t]=timeout
  [p]=cat_pipe
  [k]=sigkill
  [m]=makefile
  [s]=coding_style
  [g]=gcovr
  [v]=valgrind
  [c]=clean
  [C]=clean_before
)

main() {
  parse_args
  verify_args
  set_default_args
  print_status
}

parse_args() {
  unset options
  echo

  while [ "$#" -gt 0 ]; do
    if [ "${1:0:2}" = '--' ]; then
      unset flag
      for arg in "${arg_aliases[@]}"; do
        [ "${1:2}" = "$arg" ] && options+=("${1:2}") && flag=true
      done
      [ -z "$flag" ] && error "Invalid synthax: '$1'"
    elif [ "${1:0:1}" = '-' ]; then
      if [ "${#1}" -gt 2 ]; then
        for ((i=1; i < "${#1}"; i++)); do
          options+=("${arg_aliases[${1:$i:1}]}")
        done
      elif [ "${#1}" = 2 ]; then
        options+=("${arg_aliases[${1:1}]}")
      else
        error "Invalid synthax: '$1'"
      fi
      [ -z "${options[-1]}" ] && error "Unknown argument alias: '$1'"
    else
      [ -n "${1//[A-Za-z0-9]}" ] && error "Invalid synthax: '$1'"
      options+=("'${1}'")
    fi
    shift
  done
}

verify_args() {
  for option in "${options[@]}"; do
    echo "$option"
  done
}

set_default_args() {
  [ -z "$options" ] && options=(build_exec main tests)
}

print_status() {
  echo "${options[@]}"; echo
}

main "$@"
