#!/usr/bin/env bash

: "${OPENNEBULA_VERSION:=6.2}"
: "${OPENNEBULA_TAG:=v6.2.0}"

export DEBIAN_FRONTEND=noninteractive

set -o errexit -o nounset -o pipefail
set -x

curl -fsSL https://downloads.opennebula.org/repo/repo.key | apt-key add -

tee /etc/apt/sources.list.d/opennebula.list <<< "deb https://downloads.opennebula.org/repo/$OPENNEBULA_VERSION/Ubuntu/$(lsb_release -rs) stable opennebula"

apt-get -q update -y

install -m+x <(curl -fsSL https://github.com/OpenNebula/minione/releases/download/$OPENNEBULA_TAG/minione) /terraform/minione

sync
