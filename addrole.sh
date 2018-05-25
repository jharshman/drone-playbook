#!/usr/bin/env bash
set -o errtrace
set -euo pipefail
IFS=$'\n\t'

trap_err() {
  echo "[!] ${0}: error creating role"
  exit 2
}
trap 'trap_err ${$?}' ERR

pushd() { builtin pushd "$@" > /dev/null; }
popd() { builtin popd "$@" > /dev/null; }

addvarsymlink() {
  pushd "$PWD/roles/${1}/defaults/"
  ln -s "../../../global_vars/${1}.yaml" main.yaml
  popd
}

main() {

  if [ -d "roles/${1}" ]; then
    echo "role ${1}, already exists"
    exit 1
  fi

  mkdir -p "roles/${1}/"{files,handlers,tasks,templates,meta,vars,defaults}
  mkdir -p "global_vars"

  cat << EOF > "global_vars/${1}.yaml"
# Optional default variables for your role.
---
EOF

  cat << EOF > "${1}.yaml"
# generated role: ${1}
---
- hosts: localhost
  roles:
  - ${1}
EOF

  addvarsymlink $1

  mkdir -p environment/rnd/group_vars/all
  echo 'all' > environment/rnd/hosts
  touch environment/rnd/group_vars/all/env_specific

}

if [ "$#" -lt 1 ]; then
  exit 1
fi

main "$@"
