#!/usr/bin/env bash
set -o errtrace
set -eo pipefail
IFS=$'\n\t'

GREEN=$(printf '\033[0;32m')
BLUE=$(printf '\033[0;34m')
RED=$(printf '\033[0;31m')
NC=$(printf '\033[0m')

usage() {
  cat << EOM
usage:
  -c | --check
    Perform a "dry-run" of the role.
  -d | --docker
    Run in docker.
  -e | --env
    Set environment for playbook.
  -h | --help
    Display this menu.
  -l | --list
    List all available roles.
  -r | --role
    The name of the target role the command will run.

  Example(s):

    $@ --list
      Lists all available roles and environments

    $@ --check --role deploy
      Executes a dry-run on the deploy role.

    $@ --role deploy
      Runs the deploy role.
EOM
}

pushd() { builtin pushd "$@" > /dev/null; }
popd() { builtin popd "$@" > /dev/null; }

list() {
  # execute list
  shopt -s nullglob
  local _roles=$(grep -l '# generated role' *.yaml)
  local _environments=$(ls environment | cut -d'/' -f1)
  shopt -u nullglob

  cat << EOM
${GREEN}ROLES:
------
$_roles${NC}

${BLUE}ENVIRONMENTS:
-------------
$_environments${NC}
EOM
}

wrapc() {
  local _kubeconfig=$KUBECONFIG
  docker run --rm \
    -e "KUBECONFIG=/root/.kubeconfig.yaml" \
    -e "playbook=/root/ansible/drone-playbook" \
    -v "$_kubeconfig":"/root/.kubeconfig.yaml" \
    -v "$HOME/kubeCA.pem":"/root/kubeCA.pem" \
    -v "$(cd "${0%/*}/../.." && pwd)":"/root/ansible/drone-playbook" \
    -w "/root/ansible/drone-playbook" \
    jharshman/helmsible \
    ./runrole.sh "$@"
}


runtask() {
  sh -c "ansible-playbook -i environment/${3} $(parsecmd $@)"
}

parsecmd() {
  if [ $1 -eq 1 ]; then
    echo "${2}.yaml --check"
  else
    echo "${2}.yaml"
  fi
}

main() {

  local _check=0
  local _docker=0
  local _list=0
  local _role=""
  local _env="rnd"

  # get args
  while (( "$#" )); do
    case "$1" in
      -c|--check)
        _check=1
        shift
        ;;
      -d|--docker)
        _docker=1
        shift
        break
        ;;
      -e|--env)
        _env=$2
        shift 2
        ;;
      -l|--list)
        _list=1
        shift
        break
        ;;
      -r|--role)
        _role=$2
        shift 2
        ;;
      -h|--help)
        usage
        exit 2
        ;;
      *)
        usage
        exit 2
    esac
  done

  if [ "$_docker" -eq 1 ]; then
    wrapc "$@"
  fi


  if [ -n "$_role" ] && [ "$_list" -eq "0" ]; then
    runtask $_check $_role $_env
  elif [ "$_list" -eq "1" ]; then
    list
  fi

}

if [ $# -lt 1 ]; then
  usage
  exit 2
fi

main "$@"
