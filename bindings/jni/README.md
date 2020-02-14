# zyre-jni

[ ![Download](https://api.bintray.com/packages/zeromq/maven/zyre-jni/images/download.svg) ](https://bintray.com/zeromq/maven/zyre-jni/_latestVersion)

JNI Binding for zyre

## Building the JNI Layer for Linux

Ensure you have gradle and cmake installed, then run:

    gradle build jar
    gradle test

If you don't like to install gradle beforehand just use the gradle wrapper.

    ./gradlew build jar
    ./gradlew test

This calls javah to build the headers in src/native/include, and then compiles the C and Java pieces to create a jar file a sharable library (.so).

## Building the JNI Layer for Android

Please read the prerequisites section of the [README](../../builds/android/README.md) in the android build directory.

You only need to set the environment variables.

Then in the jni's android directory (zyre-jni/android), run:

    ./build.sh [ arm | arm64 | x86 | x86_64 ]

This does the following:

* It compiles the zyre C sources for Android, into a native library libzyre.so in /tmp/android_build/<architecture>/lib
* It compiles the JNI Java classes into a jar file zyre-jni-2.0.1.jar in bindings/jni/zyre-jni/build/libs
* It compiles the JNI C sources for Android, into a native library libzyrejni.so.
* It takes czmq-jni-*.jar, which must already be built in ../czmq/bindings/jni/czmq-jni/build/libs/
* It combines all these into jar file for the built architecture, which you can use in your Android projects.
* It merges the jar files built for the different architectures into one jar file.

## Building the JNI Layer for Windows

Prerequisites:
* MS Visual Studio or MS Visual Studio Tools 2010 or later are installed
* Java JDK 8 or later is installed

Environment Variables:
* Add MSBuild.exe to the PATH, e.g. C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin
* Set JAVA_HOME to the installation location, e.g. C:\Program Files\Java\jdk1.8.0_66.

1. Check out all dependent projects from github, at the same level as this project. E.g.: libzmq, czmq.
2. Follow the dependent projects instuctions to build thier '.dll' and '.lib' file.
3. Copy a dependent '.dll' and '.lib' files to a folder
4. Add this library folder to the path, e.g.:

	PATH %PATH%;C:\projects\libs

Now run:

	gradlew build jar "-PvsGenerator=Visual Studio 16 2019"
	gradlew test "-PvsGenerator=Visual Studio 16 2019"

Change the vsGenerator parameter to the version of MS Visual Studio you have installed.

## Installing the JNI Layer

If you like to use this JNI Layer in another project you'll need to distribute it
to a location where the other project can locate it. The easiest way to do this
is by leveraging maven and install to the local maven repository located at
$HOME/.m2. Therefore simply run:

    ./gradlew publishToMavenLocal

## Using the JNI API

- to be written.

## License


Copyright (c) the Contributors as noted in the AUTHORS file.

This file is part of Zyre, an open-source framework for proximity-based
peer-to-peer applications -- See http://zyre.org.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.


## Information for maintainers

### Building the gradle wrapper

The gradle wrapper is a tool that allows to use gradle on multiple platforms
without installing it beforehand. Make sure you have installed a version of
gradle that is at least the version the wrapper should have (local version >=  wrapper version).
Then just run

    gradle wrapper

Now commit all generated files to the project. Yes the jar file as well! Users
will now be able to call the gradle wrapper (gradlew) which will install gradle
for them.

### Travis build

Travis can build and check this jni layer there add the following line to your
travis environment matrix

    - BUILD_TYPE=bindings BINDING=jni

### Travis deploy to bintray

When tagging a release travis can automatically deploy this jni layer to bintray.
Therefore you'll need to supply travis with three environment variables:

* BINTRAY_USER - your personal user name
* BINTRAY_KEY - your personal api key
* BINTRAY_USER_ORG - the organisation you like to publish to

You may extent .travis.yml as follows

    - BUILD_TYPE=bindings BINDING=jni BINTRAY_USER=<user> BINTRAY_KEY=<key> BINTRAY_USER_ORG=<org>

But I recommend to encrypt your bintray api key. This can be done with the
travis commandline client

    travis encrypt BINTRAY_KEY=123...

Please be aware that secure environmental variables can only be added as global.

    global:
       - secure: "ZMvDhR..."
    matrix:
       - BUILD_TYPE=bindings BINDING=jni BINTRAY_USER=<user> BINTRAY_USER_ORG=<org>

