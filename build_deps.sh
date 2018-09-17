#!/bin/bash
set -e
export NDK_VERSION=android-ndk-r20
export NDK_FILENAME=${NDK_VERSION}-linux-x86_64.zip

apt-get -yqq update
apt-get -yqq upgrade
apt-get -yqq install python curl build-essential libtool autotools-dev automake pkg-config bsdmainutils unzip git wget libc6-dev gcc g++ build-essential libc6 git python3 python3-pip gettext

python3 -m pip install virtualenv

mkdir -p /opt
cd /opt
curl -sSO https://dl.google.com/android/repository/${NDK_FILENAME}
unzip -qq ${NDK_FILENAME}
rm ${NDK_FILENAME}

/opt/${NDK_VERSION}/build/tools/make-standalone-toolchain.sh --use-llvm --stl=libc++ --platform=26 --toolchain=arm-linux-androideabi-clang --install-dir=/opt/arm-linux-androideabi-clang
/opt/${NDK_VERSION}/build/tools/make-standalone-toolchain.sh --use-llvm --stl=libc++ --platform=26 --toolchain=x86-clang --install-dir=/opt/x86-clang
/opt/${NDK_VERSION}/build/tools/make-standalone-toolchain.sh --use-llvm --stl=libc++ --platform=26 --toolchain=x86_64-clang --install-dir=/opt/x86_64-clang
/opt/${NDK_VERSION}/build/tools/make-standalone-toolchain.sh --use-llvm --stl=libc++ --platform=26 --toolchain=aarch64-linux-android-clang --install-dir=/opt/aarch64-linux-android-clang

