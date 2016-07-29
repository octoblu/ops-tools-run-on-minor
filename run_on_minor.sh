#!/bin/bash

get_machines() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=service-minor-cluster" \
  | jq '.Reservations[].Instances[].PublicIpAddress' \
  | grep -v null \
  | xargs
}

run_on_machine() {
  local machine=$1
  local cmd=$2

  echo "running: ${machine} - ${cmd}"
  ssh \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    core@$machine $cmd
}

usage(){
  echo "USAGE: ./run_on_major [options] <some-command>"
  echo ""
  echo "  -h, --help      print this help text"
  echo "  -v, --version   print the version"
  echo ""
}

script_directory(){
  local source="${BASH_SOURCE[0]}"
  local dir=""

  while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done

  dir="$( cd -P "$( dirname "$source" )" && pwd )"

  echo "$dir"
}

version(){
  local directory="$(script_directory)"
  local version=$(cat "$directory/VERSION")

  echo "$version"
  exit 0
}

main(){
  local cmd="$@"
  if [ "$1" == "--help" -o "$1" == "-h" ]; then
    usage
    exit 0
  fi

  if [ "$1" == "--version" -o "$1" == "-v" ]; then
    version
    exit 0
  fi

  local machines=( $(get_machines) )
  for machine in "${machines[@]}"; do
    run_on_machine "${machine}" "$cmd"
  done
}
main $@
