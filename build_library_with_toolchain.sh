#!/bin/bash

# Abort script on any failures
set -e

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh

if [ $# != 2 ] || [ $1 == '-h' ] || [ $1 == '--help' ]; then
    echo "Usage: $0 library_name library_source_dir"
    echo "  example: $0 /home/user/my_workspace/libxml2-2.9.1"
    exit 1
fi

prefix=$(cd $2 && pwd)

cd $2

# Create a stand alone version of the android toolchain
echo
echo -e '\e[34mBuilding '$1'.\e[39m'
echo

[ "$CMAKE_PREFIX_PATH" = "" ] && die 'could not find target basedir. Have you run build_catkin.sh and sourced setup.bash?'

if [ ! -d toolchain/ ]; then
  mkdir toolchain/
  echo "$ANDROID_NDK/build/tools/make-standalone-toolchain.sh --arch=$PLATFORM --platform=android-21 --install-dir=./toolchain --ndk-dir=$ANDROID_NDK --system=linux-x86_64 --toolchain=$toolchain"
  $ANDROID_NDK/build/tools/make-standalone-toolchain.sh --arch=$PLATFORM --platform=android-21 --install-dir=./toolchain --ndk-dir=$ANDROID_NDK --system=linux-x86_64 --toolchain=$toolchain
fi

export PATH=$PATH:$2/toolchain/bin

if [ $1 == 'poco' ]; then
    if [ $PLATFORM == 'x86' ] ; then
        export ANDROID_ABI=$PLATFORM
    fi
    if [ $PLATFORM == 'x86_64' ] ; then
        export ANDROID_ABI=$PLATFORM
    fi
    ./configure --config=Android_static --no-samples --no-tests
elif [ $1 == 'curl' ]; then
    ./configure --prefix=$CMAKE_PREFIX_PATH --disable-shared --enable-static --without-ssl --disable-tftp --disable-sspi --disable-ipv6 --disable-ldaps --disable-ldap --disable-telnet --disable-pop3 --disable-ftp --disable-imap --disable-smtp --disable-pop3 --disable-rtsp --disable-ares --without-ca-bundle --disable-warnings --disable-manual --without-nss --without-random --host=$host_system
elif [ $1 == 'libxml2' ]; then
    ./configure --prefix=$CMAKE_PREFIX_PATH --enable-shared=no --enable-static --host=$host_system --without-python
elif [ $1 == 'libiconv' ]; then
    ./configure --prefix=$CMAKE_PREFIX_PATH --enable-shared=no --enable-static
elif [ $1 == 'log4cxx' ]; then
    ./configure --prefix=$CMAKE_PREFIX_PATH --enable-shared=no --enable-static
else
    ./configure --prefix=$CMAKE_PREFIX_PATH --enable-shared=no --enable-static --host=$host_system
fi

make -s -j$PARALLEL_JOBS -l$PARALLEL_JOBS

if [ $1 == 'poco' ]; then
    mkdir -p $CMAKE_PREFIX_PATH/lib
    cd $CMAKE_PREFIX_PATH/lib
    if [ $PLATFORM == 'arm' ] ; then
        cp $prefix/lib/Android/armeabi/lib*.a ./
    fi
    if [ $PLATFORM == 'x86' ] ; then
        cp $prefix/lib/Android/x86/lib*.a ./
    fi
    if [ $PLATFORM == 'x86_64' ] ; then
        cp $prefix/lib/Android/x86_64/lib*.a ./
    fi
    mkdir -p ../include && cd ../include
    cp -r $prefix/Foundation/include/Poco ./
else
    make install
fi

if [ $1 == 'curl' ]; then
    if [ $PLATFORM == 'x86' ] ; then
        sed -i 's/#define CURL_SIZEOF_LONG 8/#define CURL_SIZEOF_LONG 4/g' $CMAKE_PREFIX_PATH/include/curl/curlbuild.h
        sed -i 's/#define CURL_SIZEOF_CURL_OFF_T 8/#define CURL_SIZEOF_CURL_OFF_T 4/g' $CMAKE_PREFIX_PATH/include/curl/curlbuild.h
    fi
fi
