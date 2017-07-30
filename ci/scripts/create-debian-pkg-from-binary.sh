#!/bin/bash

set -e
[ -n "$DEBUG" ] && set -x

#
# ci/scripts/create-debian-pkg-from-binary.sh - Create .deb package
#
# This script is run from a concourse pipeline (per ci/pipeline.yml).
#

echo ">> Retrieving version metadata"

VERSION=$(cat recipe/version)
if [[ -z "${VERSION:-}" ]]; then
  echo >&2 "VERSION not found in `recipe/version`"
  exit 1
fi

if [[ ! -x fpm ]]; then
  gem install fpm --no-ri --no-rdoc
fi
fpm -s dir -t deb -n "${NAME:?required}" -v "${VERSION}" \
  --provides "${NAME}" \
  --vendor "${VENDOR:-Unknown}" \
  --license "${LICENSE:-Unknown}" \
  -m "${MAINTAINERS:-Unknown}" \
  --description "${DESCRIPTION:-Unknown}" \
  --url "${URL:-Unknown}" \
  --deb-use-file-permissions \
  --deb-no-default-config-files \
  recipe/${IN_BINARY}=/usr/bin/${OUT_BINARY}

DEBIAN_FILE="${NAME}_${VERSION}_amd64.deb"

if [[ ! -x deb-s3 ]]; then
  gem install deb-s3 --no-ri --no-rdoc
fi

mkdir ~/.aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY:?required}
aws_secret_access_key = ${AWS_SECRET_KEY:?required}
EOF
deb-s3 upload "${DEBIAN_FILE}" --bucket "${RELEASE_BUCKET}"
