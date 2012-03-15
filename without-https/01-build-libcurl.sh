#!/bin/bash

VERSION="7.24.0"
LIBNAME="libcurl"
LIBDOWNLOAD="http://curl.haxx.se/download/curl-7.24.0.tar.gz"
ARCHIVE="${LIBNAME}-${VERSION}.tar.gz"

SDK="5.1"

# Enabled/disabled protocols (the fewer, the smaller the final binary size)
export PROTOCOLS="--enable-http --disable-rtsp --disable-ftp --disable-file --disable-ldap --disable-ldaps"
PROTOCOLS="${PROTOCOLS} --disable-rtsp --disable-dict --disable-telnet --disable-tftp"
PROTOCOLS="${PROTOCOLS} --disable-pop3 --disable-imap --disable-smtp --disable-gopher"

CONFIGURE_FLAGS="--without-ssl --without-libssh2 --without-ca-bundle ${PROTOCOLS}"

DIR=`pwd`
ARCHS="i386 armv6 armv7"


# Download or use existing tar.gz
set -e
if [ ! -e ${ARCHIVE} ]; then
    echo "Downloading ${ARCHIVE}"
    curl -o ${ARCHIVE} ${LIBDOWNLOAD}
    echo ""
else
    echo "Using ${ARCHIVE}"
fi


# Create out dirs
mkdir -p "${DIR}/bin"
mkdir -p "${DIR}/lib"
mkdir -p "${DIR}/lib-i386"
mkdir -p "${DIR}/lib-no-i386"
mkdir -p "${DIR}/src"
mkdir -p "${DIR}/log"


# Build for all archs
for ARCH in ${ARCHS}
do
    if [ "${ARCH}" == "i386" ];
    then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    echo "Building ${LIBNAME} ${VERSION} for ${PLATFORM} ${SDK} ${ARCH}..."

    # Expand source code, prepare output directory and set log
    tar zxf ${ARCHIVE} -C "${DIR}/src"
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
    mv -f "${DIR}/src/curl-${VERSION}" "${DIR}/src/${LIBNAME}-${VERSION}"

    mkdir -p "${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}"
    LOG="${DIR}/log/${LIBNAME}-${VERSION}-${PLATFORM}${SDK}-${ARCH}.log"

    cd "${DIR}/src/${LIBNAME}-${VERSION}"

    export DEVROOT="/Developer/Platforms/${PLATFORM}.platform/Developer"
    export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK}.sdk"
    export CC="${DEVROOT}/usr/bin/llvm-gcc-4.2"
    export LD="${DEVROOT}/usr/bin/ld"
    export CPP="${DEVROOT}/usr/bin/llvm-cpp-4.2"
    export CXX="${DEVROOT}/usr/bin/llvm-g++-4.2"
    export AR="${DEVROOT}/usr/bin/ar"
    export AS="${DEVROOT}/usr/bin/as"
    export NM="${DEVROOT}/usr/bin/nm"
    export RANLIB="${DEVROOT}/usr/bin/ranlib"
    export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -L${DIR}/lib"
    export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${DIR}/include"
    export CXXFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${DIR}/include"

    ./configure --host=${ARCH}-apple-darwin --disable-shared --enable-static ${CONFIGURE_FLAGS} \
                --prefix="${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}" >> "${LOG}" 2>&1

    make >> "${LOG}" 2>&1
    make install >> "${LOG}" 2>&1
    cd ${DIR}
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
done


# Create a single .a file for all architectures
echo "Creating binaries for ${LIBNAME}..."
lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneSimulator${SDK}-i386/lib/${LIBNAME}.a" \
             "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv6/lib/${LIBNAME}.a" \
             "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv7/lib/${LIBNAME}.a" \
     -output "${DIR}/lib/${LIBNAME}.a"

# Create a single .a file for all arm architectures
lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv6/lib/${LIBNAME}.a" \
             "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv7/lib/${LIBNAME}.a" \
     -output "${DIR}/lib-no-i386/${LIBNAME}.a"

# Create a single .a file for i386
lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneSimulator${SDK}-i386/lib/${LIBNAME}.a" \
     -output "${DIR}/lib-i386/${LIBNAME}.a"


# Copy the header files to include
mkdir -p "${DIR}/include/${LIBNAME}"
FIRST_ARCH="${ARCHS%% *}"
if [ "${FIRST_ARCH}" == "i386" ];
then
    PLATFORM="iPhoneSimulator"
else
    PLATFORM="iPhoneOS"
fi
cp -R "${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${FIRST_ARCH}/include/" \
      "${DIR}/include/${LIBNAME}/"

echo "Finished; ${LIBNAME} binary created for archs: ${ARCHS}"
