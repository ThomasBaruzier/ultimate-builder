#!/bin/bash

#
# UB: Ultimate Builder
# By Thomas Baruzier
#

##########
# CONFIG #
##########

default_config() {
  # Build options
  build=(none)
  execute=(none)
  build_exec=(none)
  live=(none)
  headers=(none)
  flags=(debug werror)

  # Output paths
  bin_path=main
  lib_path=lib/libmy.a
  tests_path=tests/unit_tests

  # Execution options
  args=()
  timeout=(none)
  cat_pipe=false
  sigkill=false
  makefile=false

  # Code review
  coding_style=(none)
  gcovr=(none)
  valgrind=(none)

  # Cleaning
  clean=(none)
  clean_before=(none)
}

empty_args_config() {
  # Build options
  [ -n "$build_arg" ] && build=(all)
  [ -n "$execute_arg" ] && execute=(all)
  [ -n "$build_exec_arg" ] && build_exec=(all)
  [ -n "$live_arg" ] && live=(all)
  [ -n "$headers_arg" ] && headers=(all)
  [ -n "$flags_arg" ] && flags=(debug werror)

  # Output paths
  [ -n "$bin_path_arg" ] && bin_path=main
  [ -n "$lib_path_arg" ] && lib_path=lib/libmy.a
  [ -n "$tests_path_arg" ] && tests_path=tests/unit_tests

  # Execution options
  [ -n "$args_arg" ] && args=('>These<' '>are the defaults<' '>execution args<' '>provided by U.B.<')
  [ -n "$timeout_arg" ] && timeout=(tests 10)
  [ -n "$cat_pipe_arg" ] && cat_pipe=true
  [ -n "$sigkill_arg" ] && sigkill=true
  [ -n "$makefile_arg" ] && makefile=true

  # Code review
  [ -n "$coding_style_arg" ] && coding_style=(ananas)
  [ -n "$gcovr_arg" ] && gcovr=(all)
  [ -n "$valgrind_arg" ] && valgrind=(all)

  # Cleaning
  [ -n "$clean_arg" ] && clean=(objects lib)
  [ -n "$clean_before_arg" ] && clean_before=(objects lib)
}

#########
# UTILS #
#########

error() { echo -e "\e[1;31mERROR:\e[31m $@\e[0m\n"; exit 1; }
warn() { echo -e "\e[1;33mWARNING:\e[33m $@\e[0m"; }
success() { echo -e "\e[1;32mSUCCESS:\e[32m $@\e[0m"; }
info() { echo -e "\e[1;34mINFO:\e[34m $@\e[0m"; }

main() {
  echo
  default_config
  format_linked_args "$@"
  parse_args "${formatted[@]}"
  empty_args_config
  verify_args
#  print_config
  get_targets
  get_files
  verify_targets
  print_status
  build
#  execute
}

###########
# PARSING #
###########

parse_args() {
  while [ "$#" != 0 ]; do
    case "$1" in
    	-b|--build)
    	  get_next_args "$@" && build=("${values[@]}")
        [ -z "$values" ] && build_arg=true
    	  ;;
    	-x|--execute)
    	  get_next_args "$@" && execute=("${values[@]}")
        [ -z "$values" ] && execute_arg=true
    	  ;;
    	-B|--build-exec)
    	  get_next_args "$@" && build_exec=("${values[@]}")
        [ -z "$values" ] && build_exec_arg=true
    	  ;;
    	-l|--live)
    	  get_next_args "$@" && live=("${values[@]}")
        [ -z "$values" ] && live_arg=true
    	  ;;
    	-H|--headers)
    	  get_next_args "$@" && headers=("${values[@]}")
        [ -z "$values" ] && headers_arg=true
    	  ;;
    	-f|--flags)
    	  get_next_args "$@" && flags=("${values[@]}")
        [ -z "$values" ] && flags_arg=true
    	  ;;
      -X|--bin-path)
        get_next_args "$@" && bin_path=("${values[@]}")
        [ -z "$values" ] && bin_path_arg=true
        ;;
      -L|--lib-path)
        get_next_args "$@" && lib_path=("${values[@]}")
        [ -z "$values" ] && lib_path_arg=true
        ;;
      -T|--tests-path)
        get_next_args "$@" && tests_path=("${values[@]}")
        [ -z "$values" ] && tests_path_arg=true
        ;;
    	-a|--args)
    	  get_next_args "$@" && args=("${values[@]}")
        [ -z "$values" ] && args_arg=true
    	  ;;
    	-t|--timeout)
    	  get_next_args "$@" && timeout=("${values[@]}")
        [ -z "$values" ] && timeout_arg=true
    	  ;;
    	-p|--cat-pipe)
    	  get_next_args "$@" && cat_pipe=("${values[@]}")
        [ -z "$values" ] && cat_pipe_arg=true
    	  ;;
    	-k|--sigkill)
    	  get_next_args "$@" && sigkill=("${values[@]}")
        [ -z "$values" ] && sigkill_arg=true
    	  ;;
    	-m|--makefile)
    	  get_next_args "$@" && makefile=("${values[@]}")
        [ -z "$values" ] && makefile_arg=true
    	  ;;
    	-s|--coding-style)
    	  get_next_args "$@" && coding_style=("${values[@]}")
        [ -z "$values" ] && coding_style_arg=true
    	  ;;
    	-g|--gcovr)
    	  get_next_args "$@" && gcovr=("${values[@]}")
        [ -z "$values" ] && gcovr_arg=true
    	  ;;
    	-v|--valgrind)
    	  get_next_args "$@" && valgrind=("${values[@]}")
        [ -z "$values" ] && valgrind_arg=true
    	  ;;
    	-c|--clean)
    	  get_next_args "$@" && clean=("${values[@]}")
        [ -z "$values" ] && clean_arg=true
    	  ;;
    	-C|--clean-before)
    	  get_next_args "$@" && clean_before=("${values[@]}")
        [ -z "$values" ] && clean_before_arg=true
    	  ;;
    	-h|--help) help;;
      *) error "Unknown option: $1";;
    esac
    shift "$to_skip"
  done
}

#################
# PARSING LOGIC #
#################

get_next_args() {
  unset values
  while [ -n "$2" ] && [ "${2:0:1}" != '-' ]; do
    values+=("$2"); shift
  done
  to_skip=$(("${#values[@]}" + 1))
  [ -z "$values" ] && return 1 || return 0
}

format_linked_args() {
  unset formatted
  while [ "$#" != 0 ]; do
    [ "${1:0:2}" = '--' ] || [ "${1:0:1}" != '-' ] \
    && formatted+=("$1") && shift && continue
    [ "${1//[a-zA-Z]/}" != '-' ] && error "Invalid argument: $1"
    for ((i=1; "$i" < "${#1}"; i++)); do
      formatted+=("-${1:$i:1}")
    done
    shift
  done
}

replace_aliases() {
  for ((i=0; i < "${#to_verify[@]}"; i++)); do
    [ "${#to_verify[i]}" = 1 ] && \
    for ((j=0; j < "${#to_compare[@]}"; j++)); do
      to_compare_tmp="${to_compare[j]#+}"
      [ "${to_verify[i]}" = "${to_compare_tmp:0:1}" ] \
      && to_verify["$i"]="${to_compare[j]#+}" && break
    done
  done
}

verify_arg() {
  to_compare=("$@")
  replace_aliases
  for i in "${to_verify[@]}"; do
    unset match
    for j in "${to_compare[@]}"; do
      if [ "+$i" = "$j" ]; then
        [ "${#to_verify[@]}" = 1 ] || error "Parameter '$i' is not used alone"
        match=true
      fi
      [ "$i" = "${j#+}" ] && match="$i" && break
    done
    [ -z "$match" ] && error "Unknown parameter: $i"
  done
}

verify_array() {
  unset match
  to_compare=("$@")
  for i in "${to_verify[@]}"; do
    for j in "${to_compare[@]}"; do
      [ "$i" = "$j" ] && match="$i" && break 2
    done
  done
  [ -z "$match" ] && return 1 || return 0
}

######################
# PARSING PROCESSING #
######################

verify_args() {
  to_verify=("${build[@]}")
  verify_arg +none +all main tests lib; build=("${to_verify[@]}")
  to_verify=("${execute[@]}")
  verify_arg +none +all main tests; execute=("${to_verify[@]}")
  to_verify=("${build_exec[@]}")
  verify_arg +none +all main tests lib; build_exec=("${to_verify[@]}")
  to_verify=("${live[@]}")
  verify_arg +none +all main tests lib; live=("${to_verify[@]}")
  to_verify=("${headers[@]}")
  verify_arg +none +all main lib; headers=("${to_verify[@]}")
  to_verify=("${flags[@]}")
  verify_arg +none opti debug werror slow csfml; flags=("${to_verify[@]}")
#  to_verify=("${bin_path[@]}")
#  verify_arg '[string]'; args=("${to_verify[@]}")
#  to_verify=("${lib_path[@]}")
#  verify_arg '[string]'; args=("${to_verify[@]}")
#  to_verify=("${tests_path[@]}")
#  verify_arg '[string]'; args=("${to_verify[@]}")
#  to_verify=("${args[@]}")
#  verify_arg '[string]'; args=("${to_verify[@]}")
#  to_verify=("${timeout[@]}")
#  verify_arg +none +all main tests '[number]'; timeout=("${to_verify[@]}")
  to_verify=("${cat_pipe[@]}")
  verify_arg +none +true +false; cat_pipe=("${to_verify[@]}")
  to_verify=("${sigkill[@]}")
  verify_arg +none +true +false; sigkill=("${to_verify[@]}")
  to_verify=("${makefile[@]}")
  verify_arg +none +true +false; makefile=("${to_verify[@]}")
  to_verify=("${coding_style[@]}")
  verify_arg +none +ananas +banana +mango; coding_style=("${to_verify[@]}")
  to_verify=("${gcovr[@]}")
  verify_arg +none +all lines branches; gcovr=("${to_verify[@]}")
  to_verify=("${valgrind[@]}")
  verify_arg +none +all main tests; valgrind=("${to_verify[@]}")
  to_verify=("${clean[@]}")
  verify_arg +none +all objects lib bin headers; clean=("${to_verify[@]}")
  to_verify=("${clean_before[@]}")
  verify_arg +none +all objects lib bin headers; clean_before=("${to_verify[@]}")
}

get_targets() {
  unset build_main build_test build_lib
  unset exec_main exec_test
  unset live_main live_test live_lib
  unset headers_main headers_lib

  to_verify=("${build[@]}")
  [ -z "$build_main" ] && verify_array all main && build_main=true
  [ -z "$build_tests" ] && verify_array all tests && build_tests=true
  [ -z "$build_lib" ] && verify_array all lib && build_lib=true

  to_verify=("${build_exec[@]}")
  [ -z "$build_main" ] && verify_array all main && build_main=true
  [ -z "$build_tests" ] && verify_array all tests && build_tests=true
  [ -z "$build_lib" ] && verify_array all lib && build_lib=true
  [ -z "$exec_main" ] && verify_array all main && exec_main=true
  [ -z "$exec_tests" ] && verify_array all tests && exec_tests=true

  to_verify=("${execute[@]}")
  [ -z "$exec_main" ] && verify_array all main && exec_main=true
  [ -z "$exec_tests" ] && verify_array all tests && exec_tests=true

  to_verify=("${live[@]}")
  [ -z "$live_main" ] && verify_array all main \
  && live_main=true && build_main=true && exec_main=true
  [ -z "$live_tests" ] && verify_array all tests \
  && live_tests=true && build_tests=true && exec_tests=true
  [ -z "$live_lib" ] && verify_array all lib \
  && live_lib=true && build_lib=true

  to_verify=("${headers[@]}")
  [ -z "$headers_main" ] && verify_array all main && headers_main=true
  [ -z "$headers_lib" ] && verify_array all lib && headers_lib=true

  # TODO
  # Check flags if no compilations
  # Check execution options if no execution
  # Check gcovr gnco files or test execution
  # Check valgring if binary or building main
}

get_files() {
  shopt -s globstar
  unset main_files tests_files lib_files
  if [ -n "$build_main" ]; then
    for file in *.c; do
      [ -f "$file" ] && main_files+=("$file")
    done
  fi
  if [ -n "$build_tests" ]; then
    for file in tests/**/*.c; do
      [ -f "$file" ] && tests_files+=("$file")
    done
  fi
  if [ -n "$build_lib" ]; then
    for file in lib/**/*.c; do
      [ -f "$file" ] && lib_files+=("$file")
    done
  fi
  shopt -u globstar
}

verify_targets() {
  unset sep

  if [ -z "$main_files" ]; then
    [ -n "$exec_main" ] && unset exec_main && sep=true \
    && warn 'No files found or build instructions given for executing main'
    [ -n "$build_main" ] && unset build_main && sep=true \
    && warn 'No files found for building main'
    [ -n "$live_main" ] && unset live_main && sep=true \
    && warn 'No files found for activating live mode for main'
    [ -n "$headers_main" ] && unset headers_main && sep=true \
    && warn 'No files found for generating headers for main'
    [ -n "$exec_main" ] && [ ! -f "$bin_path" ] && \
    [ -z "$build_main" ] && unset exec_main && sep=true \
    && warn 'No binary or build instructions given for executing main'
  fi

  if [ -z "$tests_files" ]; then
    [ -n "$exec_tests" ] && unset exec_tests && sep=true \
    && warn 'No files found or build instructions given for executing tests'
    [ -n "$build_tests" ] && unset build_tests && sep=true \
    && warn 'No files found for building tests'
    [ -n "$live_tests" ] && unset live_main && sep=true \
    && warn 'No files found for activating live mode for tests'
    [ -n "$exec_tests" ] && [ ! -f "$tests_path" ] && \
    [ -z "$build_tests" ] && unset exec_tests && sep=true \
    && warn 'No binary or build instructions given for executing tests'
  fi

  if [ -z "$lib_files" ]; then
    [ -n "$build_lib" ] && unset build_lib && sep=true \
    && warn 'No files found for building lib'
    [ -n "$live_lib" ] && unset live_lib && sep=true \
    && warn 'No files found for live mode for lib'
    [ -n "$headers_lib" ] && unset headers_lib && sep=true \
    && warn 'No files found for generating headers for lib'
  fi

  [ -n "$sep" ] && echo
}

###################
# BUILD & EXECUTE #
###################

build() {
  build_flags+='-I./include/ '
  if [ -n "$build_lib" ]; then
    output=$(gcc -o "$lib_path" "${lib_files[@]}" $build_flags)
    [ "$?" != 0 ] && echo && error 'Failed to build lib'
    [ -n "$output" ] && echo
    success 'Built main\n'
  fi
  if [ -n "$build_main" ]; then
    output=$(gcc -o "$bin_path" "${main_files[@]}" $build_flags)
    [ "$?" != 0 ] && echo && error 'Failed to build main'
    [ -n "$output" ] && echo
    success 'Built main\n'
  fi
  if [ -n "$build_tests" ]; then
    output=$(gcc -o "$tests_path" "${tests_files[@]}" $build_flags)
    [ "$?" != 0 ] && echo && error 'Failed to build tests'
    [ -n "$output" ] && echo
    success 'Built main\n'
  fi
}

#execute() {
#	echo -e '\e[0;1mExecuting ./main...\n\e[33m▼\e[0m'
#	make --no-print-directory exec_params
#	echo -e '\e[s\n\e[u\e[33;1m\e[B▲\e[0m\n'
# echo
#}

############
# PRINTING #
############

help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo 'Build options:'
  echo '  -b --build         none all main tests lib'
  echo '  -x --execute       none all main tests'
  echo '  -B --build-exec    none all main tests lib'
  echo '  -l --live          none all main tests lib'
  echo '  -H --headers       none all main lib'
  echo '  -f --flags         none opti debug werror slow csfml'
  echo
  echo 'Output paths:'
  echo '  -X --bin-path      [path]'
  echo '  -L --lib-path      [path]'
  echo '  -T --tests-path    [path]'
  echo
  echo 'Execution options:'
  echo '  -a --args          [str1] [str2] ...'
  echo '  -t --timeout       none all main tests + seconds'
  echo '  -p --cat-pipe      true false'
  echo '  -k --sigkill       true false'
  echo '  -m --makefile      true false'
  echo
  echo 'Code review:'
  echo '  -s --coding-style  ananas banana mango'
  echo '  -g --gcovr         none all lines branches'
  echo '  -v --valgrind      none all main tests'
  echo
  echo 'Cleaning:'
  echo '  -c --clean         none all objects lib bin headers'
  echo '  -C --clean-before  none all objects lib bin headers'
  echo
  exit
}

print_config() {
  echo 'Build options:'
  echo "  build: ${build[@]}"
  echo "  execute: ${execute[@]}"
  echo "  build_exec: ${build_exec[@]}"
  echo "  live: ${live[@]}"
  echo "  headers: ${headers[@]}"
  echo "  flags: ${flags[@]}"
  echo
  echo 'Output paths:'
  echo "  bin_path: $bin_path"
  echo "  lib_path: $lib_path"
  echo "  tests_path: $tests_path"
  echo
  echo 'Execution options:'
  echo -n "  args:"; printf " '%s'" "${args[@]}"; echo
  echo "  timeout: ${timeout[@]}"
  echo "  cat_pipe: $cat_pipe"
  echo "  sigkill: $sigkill"
  echo "  makefile: $makefile"
  echo
  echo 'Code review:'
  echo "  coding_style: ${coding_style[@]}"
  echo "  gcovr: ${gcovr[@]}"
  echo "  valgrind: ${valgrind[@]}"
  echo
  echo 'Cleaning:'
  echo "  clean: ${clean[@]}"
  echo "  clean_before: ${clean_before[@]}"
  echo
}

print_status() {
  unset task
  [ -n "$build_main" ] && task=true && info 'Building main...'
  [ -n "$build_tests" ] && task=true && info 'Building tests...'
  [ -n "$build_lib" ] && task=true && info 'Building lib...'
  [ -n "$exec_main" ] && task=true && info 'Executing main...'
  [ -n "$exec_tests" ] && task=true && info 'Executing tests...'
  [ -n "$live_main" ] && task=true && info 'Live main...'
  [ -n "$live_tests" ] && task=true && info 'Live tests...'
  [ -n "$live_lib" ] && task=true && info 'Live lib...'
  [ -n "$headers_main" ] && task=true && info 'Headers for main...'
  [ -n "$headers_lib" ] && task=true && info 'Headers for lib...'
  [ -z "$task" ] && info "Nothing to do, try '$0 --help'"
  echo
}

main "$@"
