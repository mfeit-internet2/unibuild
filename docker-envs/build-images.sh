#!/usr/bin/env bash
#
# Usage info
show_help() {
    cat << EOF
    Usage: ${0##*/} -chv [build_type]
    This script build all Docker images containing Unibuild.

    Note:
    This is a developer only script, official images are built using GitHub Actions.

    Requirements:
        - Functionnal docker buildx setup

    The default build_type is defined in docker-bake.hcl

    Options:
        -c clear all Docker caches
        -h show this help
        -v verbose mode

EOF
}

# TODO: Make the Registry configurable so developer can publish their own instances on their own registry

# Defaults
docker_dir=docker-envs
clear_cache=false
verbose=false
build_type=
declare -a OSimages=("d10" "u18" "u20")

while getopts "chv" OPT; do
    case $OPT in
        c) clear_cache=true ;;
        v) verbose=true ;;
        h)
            show_help >&2
            exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Check what type of build we want
if [ $# -gt 0 ]; then
    build_type=$@
fi
if [ -n "$build_type" ]; then
    echo -e "\033[1mWe'll use docker bake target: \033[1;32m$build_type\033[0m"
fi
cd $docker_dir

### Check current status
if $verbose; then
    echo -e "\033[1mCurrent Docker setup is as follows:\033[0m"
    docker buildx ls
    echo
    docker ps -a
    echo
    docker images
    echo
fi

### Clear Docker caches
if $clear_cache; then
    echo -e "\033[1mLet's clear caches\033[0m"
    docker builder prune -af
    echo
    docker buildx prune -af
    echo
    docker system prune -f
    echo
    docker volume prune -f
    echo
fi

### Create and setup the buildx instance for the multi arch builds
# See https://docs.docker.com/desktop/multi-arch/
echo -e "\033[1mMake sure docker buildx is ready for multi arch builds\033[0m"
if ! docker buildx use perfbuild 2>/dev/null; then 
    docker buildx create --driver docker-container --name perfbuild --use
fi

# Setup buildx for all supported architectures by installing and registering the latest qemu image
# It uses the images from https://github.com/multiarch/qemu-user-static
# Also see https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408 for more context
# This should only be needed once per Docker daemon run,
# but it shouldn't be a problem running it everytime we run the setup
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
echo

### Verify new status
if $verbose; then
    echo -e "\033[1mNew Docker setup is as follows:\033[0m"
    docker buildx ls
    echo
    docker ps -a
    echo
    docker images
    echo
fi

### Build the new images on the different platforms
export OSimage
# Loop on all OS we want to have images
for OSimage in ${OSimages[@]}; do
    echo -e "\033[1mNow let's build Docker images for \033[1;32m$OSimage \033[0m"
    # Prepare and push the images
    docker buildx bake $build_type
    echo
done

# Display result
if $verbose; then
    docker images
    echo
fi
echo -e "\033[1mAll images built and pushed!\033[0m"
