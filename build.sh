#!/usr/bin/env bash

set -o errexit  # abort on nonzero exit status
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

# globals

#
# Start of dynamic data
#

# image registry
REGISTRIES=(
  "docker.io/rpinz"           # docker
  "registry.gitlab.com/rpinz" # gitlab
  "ghcr.io/rpinz"             # github
)

# os vendor
OSVENDORS=(
  "azure-sql-edge"
)

# os versions
OSVERSIONS=(
  "1.0.6"
)

# os platforms
OSPLATFORMS=(
  "linux/amd64,"
  "linux/arm64,"
)

# edge versions
EDGEVERSIONS=(
  "1.0.6"
)

#
# End of dynamic data
#

# concatenate and clean platform list
OSPLATFORMS="${OSPLATFORMS[@]}" # concatenate array
OSPLATFORMS="${OSPLATFORMS//[[:space:]]/}" # remove whitespace
OSPLATFORMS="${OSPLATFORMS%?}" # remove last character (trailing comma)

EDGE="azure-sql-edge"
DOCKER_ARGS=()
EDGEVERSION=""
OSVENDOR=""
OSVERSION=""
REGISTRY=""

# functions

usage() {
  echo " 🐳 ${0:-build.sh} < local | build | buildx > [ no-cache ]"
  echo
  echo " local|build|buildx - (local) container(s)"
  echo "                    - (build) container(s) and push to registry"
  echo "                    - (buildx) multi-arch container(s) and push to registry"
  echo "           no-cache - build without cache"
}

builder_type() {
  echo "${1:-local}"
}

nocache() {
  if [ "${1:-}" = "no" ]; then
    echo "--no-cache"
  fi
}

args() {
  DOCKER_ARGS=(
    --tag "$1"
    --build-arg "OSVENDOR=$OSVENDOR"
    --build-arg "OSVERSION=$OSVERSION"
    --build-arg "EDGEVERSION=$EDGEVERSION"
  )
}

docker() {
  (
    $(which docker) $*
  )
}

push() {
  echo " 🐳 Pushing $1"
  docker push "$1"
}

pull() {
  if [ "$(docker images | grep -e ${OSVENDOR}.*${OSVERSION})" = "" ]; then
    echo " 🐳 Pulling $1"
    docker pull "$1"
  else
    echo " 🐳 Found images: $1"
  fi
}

build() {
  args $*
  echo " 🐳 Building $1 for $OSVENDOR $OSVERSION"
  docker build $NO_CACHE ${DOCKER_ARGS[@]} .
}

buildx_create() {
  if [ "$BUILDER_TYPE" = "buildx" ]; then
    echo " 🐳 Creating buildx $1"
    docker buildx create --name "$1" --driver-opt "network=host" --use --bootstrap
  fi
}

buildx_rm() {
  if [ "$BUILDER_TYPE" = "buildx" ]; then
    echo " 🐳 Removing buildx $1"
    docker buildx rm "$1"
  fi
}

buildx() {
  args $*
  if [ "$BUILDER_TYPE" = "buildx" ]; then
    echo " 🐳 Buildxing $1 for $OSVENDOR $OSVERSION"
    docker buildx build $NO_CACHE --platform "${OSPLATFORMS// }" ${DOCKER_ARGS[@]} --tag "${REGISTRY}/${EDGE}:latest" --push .
  fi
}

builder() {
  case "$1" in
    "buildx")
      for REGISTRY in ${REGISTRIES[@]}; do
        buildx "${REGISTRY}/${EDGE}:${OSVERSION}"
      done
    ;;
    "build")
      pull "mcr.microsoft.com/${OSVENDOR}:${OSVERSION}"
      for REGISTRY in ${REGISTRIES[@]}; do
        build "${REGISTRY}/${EDGE}:${OSVERSION}" \
          && push "${REGISTRY}/${EDGE}:${OSVERSION}"
      done
    ;;
    "local")
      pull "mcr.microsoft.com/${OSVENDOR}:${OSVERSION}"
      build "${EDGE}:${OSVERSION}"
    ;;
    *)
      usage $*
  esac
}

main() {
  for OSVENDOR in ${OSVENDORS[@]}; do
    for OSVERSION in ${OSVERSIONS[@]}; do
      for EDGEVERSION in ${EDGEVERSIONS[@]}; do
        builder "$BUILDER_TYPE"
      done
    done
  done
}

BUILDER_TYPE="$(builder_type ${1:-})"
NO_CACHE="$(nocache ${2:-})"

buildx_create "$EDGE"
main $*
buildx_rm "$EDGE"

# EOF
