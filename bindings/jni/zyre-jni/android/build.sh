#!/bin/bash
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
#   Build JNI interface for Android
#
#   Requires these environment variables be set, e.g.:
#
#     ANDROID_NDK_ROOT=$HOME/android-ndk-r25
#
#   Exit if any step fails
set -e

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
        set -x
        MAKE_OPTIONS=VERBOSE=1
        ;;
esac

function usage {
    echo "Usage ./build.sh [ arm | arm64 | x86 | x86_64 ]"
}

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

source ../../../../builds/android/android_build_helper.sh

export MIN_SDK_VERSION=21
export ANDROID_BUILD_DIR=/tmp/android_build

GRADLEW_OPTS=()
GRADLEW_OPTS+=("-PbuildPrefix=$BUILD_PREFIX")
GRADLEW_OPTS+=("--info")

#   Build any dependent libraries
#   Use a default value assuming that dependent libraries sits alongside this one
( cd ${CZMQ_ROOT:-../../../../../czmq}/bindings/jni/czmq-jni/android; ./build.sh $BUILD_ARCH )

#   Ensure we've built dependencies for Android
echo "********  Building zyre Android native libraries"
( cd ../../../../builds/android && ./build.sh $BUILD_ARCH )

#   Ensure we've built JNI interface
echo "********  Building zyre JNI interface & classes"
( cd ../.. && TERM=dumb ./gradlew build jar ${GRADLEW_OPTS[@]} ${ZYRE_GRADLEW_OPTS} )

echo "********  Building zyre JNI for Android"
rm -rf build && mkdir build && cd build
# Export android build's environment variables for cmake
android_build_set_env $BUILD_ARCH
(
    VERBOSE=1 \
    cmake \
        -DANDROID_ABI=$TOOLCHAIN_ABI \
        -DANDROID_PLATFORM=$MIN_SDK_VERSION \
        -DANDROID_STL=c++_shared \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
        -DCMAKE_FIND_ROOT_PATH=$ANDROID_BUILD_PREFIX \
        ..
)

#   CMake wrongly searches current directory and then toolchain path instead
#   of lib path for these files, so make them available temporarily
ln -s $ANDROID_SYS_ROOT/usr/lib/crtend_so.o
ln -s $ANDROID_SYS_ROOT/usr/lib/crtbegin_so.o

make $MAKE_OPTIONS

echo "********  Building jar for $TOOLCHAIN_ABI"
#   Copy class files into org/zeromq/etc.
find ../../build/libs/ -type f -name 'zyre-jni-*.jar' ! -name '*javadoc.jar' ! -name '*sources.jar' -exec unzip -q {} +
unzip -qo "${CZMQ_ROOT:-../../../../../../czmq}/bindings/jni/czmq-jni/android/czmq-android*$TOOLCHAIN_ABI*.jar"

#   Copy native libraries into lib/$TOOLCHAIN_ABI
mkdir -p lib/$TOOLCHAIN_ABI
cp libzyrejni.so lib/$TOOLCHAIN_ABI
cp $ANDROID_BUILD_PREFIX/lib/*.so lib/$TOOLCHAIN_ABI
cp ${ANDROID_STL_ROOT}/${ANDROID_STL} lib/$TOOLCHAIN_ABI

#   Build android jar
zip -r -m ../zyre-android-$TOOLCHAIN_ABI-2.0.1.jar lib/ org/ META-INF/
cd ..
rm -rf build

echo "********  Merging ABI jars"
mkdir build && cd build
#   Copy contents from all ABI jar - overwriting class files and manifest
unzip -qo '../zyre-android-*2.0.1.jar'
#   Build merged jar
zip -r -m ../zyre-android-2.0.1.jar lib/ org/ META-INF/
cd ..
rm -rf build

echo "********  Complete"
