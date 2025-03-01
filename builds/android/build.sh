#!/usr/bin/env bash
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
#
#   Exit if any step fails
set -e

# By default, use directory of current script as the Android build directory.
# ANDROID_BUILD_DIR must be an absolute path:
export ANDROID_BUILD_DIR="${ANDROID_BUILD_DIR:-$(cd $(dirname ${BASH_SOURCE[0]}) ; pwd)}"

# Set this to enable verbose profiling
[ -n "${CI_TIME-}" ] || CI_TIME=""
case "$CI_TIME" in
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        CI_TIME="time -p " ;;
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        CI_TIME="" ;;
esac

# Set this to enable verbose tracing
[ -n "${CI_TRACE-}" ] || CI_TRACE="no"
case "$CI_TRACE" in
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        set +x ;;
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        set -x ;;
esac

function usage {
    echo "Usage ./build.sh [ arm | arm64 | x86 | x86_64 ]"
}

# Use directory of current script as the working directory
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Get access to android_build functions and variables
source ./android_build_helper.sh

# Choose a C++ standard library implementation from the ndk
export ANDROID_BUILD_CXXSTL="gnustl_shared_49"

# Additional flags for LIBTOOL, for LIBZMQ and other dependencies.
export LIBTOOL_EXTRA_LDFLAGS='-avoid-version'

BUILD_ARCH=$1
if [ -z $BUILD_ARCH ]; then
    usage
    exit 1
fi

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    export HOST_PLATFORM=linux-x86_64
    ;;
  darwin*)
    export HOST_PLATFORM=darwin-x86_64
    ;;
  *)
    echo "Unsupported platform"
    exit 1
    ;;
esac

# Set default values used in ci builds
export NDK_VERSION=${NDK_VERSION:-android-ndk-r25}
# With NDK r22b, the minimum SDK version range is [16, 31].
# Since NDK r24, the minimum SDK version range is [19, 31].
# SDK version 21 is the minimum version for 64-bit builds.
export MIN_SDK_VERSION=${MIN_SDK_VERSION:-21}

# Set up android build environment and set ANDROID_BUILD_OPTS array
android_build_set_env $BUILD_ARCH
android_build_env
android_build_opts

# Use a temporary build directory
cache="/tmp/android_build/${TOOLCHAIN_ARCH}"
rm -rf "${cache}"
mkdir -p "${cache}"

# Check for environment variable to clear the prefix and do a clean build
if [[ $ANDROID_BUILD_CLEAN ]]; then
    echo "Doing a clean build (removing previous build and depedencies)..."
    rm -rf "${ANDROID_BUILD_PREFIX}"/*
fi

##
# Make sure czmq is built and copy the prefix

(android_build_verify_so "libczmq.so" &> /dev/null) || {
    # Use a default value assuming the czmq project sits alongside this one
    test -z "$CZMQ_ROOT" && CZMQ_ROOT="$(cd ../../../czmq && pwd)"

    if [ ! -d "$CZMQ_ROOT" ]; then
        echo "The CZMQ_ROOT directory does not exist"
        echo "  ${CZMQ_ROOT}" run run
        exit 1
    fi
    echo "Building czmq in ${CZMQ_ROOT}..."

    (bash ${CZMQ_ROOT}/builds/android/build.sh $BUILD_ARCH) || exit 1
    UPSTREAM_PREFIX=${CZMQ_ROOT}/builds/android/prefix/${TOOLCHAIN_ARCH}
    cp -rn ${UPSTREAM_PREFIX}/* ${ANDROID_BUILD_PREFIX} || :
}

##
[ -z "$CI_TIME" ] || echo "`date`: Build zyre from local source"

(android_build_verify_so "libzyre.so" "libczmq.so" &> /dev/null) || {
    rm -rf "${cache}/zyre"
    (cp -r ../.. "${cache}/zyre" && cd "${cache}/zyre" \
        && ( make clean || : ) && rm -f configure config.status)

    # Remove *.la files as they might cause errors with cross compiled libraries
    find ${ANDROID_BUILD_PREFIX} -name '*.la' -exec rm {} +

    (
        CONFIG_OPTS=()
        CONFIG_OPTS+=("--quiet")
        CONFIG_OPTS+=("${ANDROID_BUILD_OPTS[@]}")
        CONFIG_OPTS+=("--without-docs")

        cd "${cache}/zyre" \
        && $CI_TIME ./autogen.sh 2> /dev/null \
        && android_show_configure_opts "LIBZYRE" "${CONFIG_OPTS[@]}" \
        && $CI_TIME ./configure "${CONFIG_OPTS[@]}" \
        && $CI_TIME make -j 4 \
        && $CI_TIME make install
    ) || exit 1
}

##
# Verify shared libraries in prefix

android_build_verify_so "libczmq.so"
android_build_verify_so "libzyre.so" "libczmq.so"
echo "Android (${TOOLCHAIN_ARCH}) build successful"
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
