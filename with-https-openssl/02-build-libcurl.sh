#!/bin/bash

VERSION="7.26.0"
PRECEDENT_VERSION="1.0.1c"
PRECEDENT_LIBNAME="libssl"
LIBNAME="libcurl"
LIBDOWNLOAD="http://curl.haxx.se/download/curl-${VERSION}.tar.gz"
ARCHIVE="${LIBNAME}-${VERSION}.tar.gz"

SDK="5.1"

# Enabled/disabled protocols (the fewer, the smaller the final binary size)
PROTOCOLS="--enable-http --disable-rtsp --disable-ftp --disable-file --disable-ldap --disable-ldaps \
           --disable-rtsp --disable-dict --disable-telnet --disable-tftp \
           --disable-pop3 --disable-imap --disable-smtp --disable-gopher"

CONFIGURE_FLAGS="--without-libssh2 --without-ca-bundle ${PROTOCOLS}"

DIR=`pwd`
XCODE=$(xcode-select --print-path)
ARCHS="i386 armv7"


# Download or use existing tar.gz
if [ ! -e ${ARCHIVE} ]; then
    echo ""
    echo "* Downloading ${ARCHIVE}"
    echo ""
    curl -o ${ARCHIVE} ${LIBDOWNLOAD}
else
    echo ""
    echo "* Using ${ARCHIVE}"
fi


# Create out dirs
mkdir -p "${DIR}/bin"
mkdir -p "${DIR}/lib"
mkdir -p "${DIR}/src"


# Build for all archs
for ARCH in ${ARCHS}
do
    if [ "${ARCH}" == "i386" ];
    then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    echo ""
    echo "* Building ${LIBNAME} ${VERSION} for ${PLATFORM} ${SDK} ${ARCH}..."

    # Ensure precedent lib is available for this architecture
    if [ -f "${DIR}/bin/${PRECEDENT_LIBNAME}-${PRECEDENT_VERSION}/${PLATFORM}${SDK}-${ARCH}/lib/${PRECEDENT_LIBNAME}.a" ];
    then
        echo ""
        echo "* Using ${PRECEDENT_LIBNAME} ${PRECEDENT_VERSION} (${ARCH})..."
    else
        echo ""
        echo "! Please build ${PRECEDENT_LIBNAME} ${PRECEDENT_VERSION} for ${ARCH} first"
        exit 1
    fi

    # Expand source code, prepare output directory and set log
    tar zxf ${ARCHIVE} -C "${DIR}/src"
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
    mv -f "${DIR}/src/curl-${VERSION}" "${DIR}/src/${LIBNAME}-${VERSION}"

    mkdir -p "${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}"
    LOG="${DIR}/log/${LIBNAME}-${VERSION}-${PLATFORM}${SDK}-${ARCH}.log"

    cd "${DIR}/src/${LIBNAME}-${VERSION}"

    DEVROOT="${XCODE}/Platforms/${PLATFORM}.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK}.sdk"
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
                --with-ssl="${DIR}/bin/${PRECEDENT_LIBNAME}-${PRECEDENT_VERSION}/${PLATFORM}${SDK}-${ARCH}" \
                --prefix="${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}"

    make
    make install
    cd ${DIR}
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
done


# Create a single .a file for all architectures
echo ""
echo "* Creating binaries for ${LIBNAME}..."
lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneSimulator${SDK}-i386/lib/${LIBNAME}.a" \
             "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv7/lib/${LIBNAME}.a" \
     -output "${DIR}/lib/${LIBNAME}.a"

# Create a single .a file for all arm architectures
lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv7/lib/${LIBNAME}.a" \
     -output "${DIR}/lib/${LIBNAME}-armv7.a"

# Create a single .a file for i386
lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneSimulator${SDK}-i386/lib/${LIBNAME}.a" \
     -output "${DIR}/lib/${LIBNAME}-i386.a"


# Copy the header files to include
mkdir -p "${DIR}/include/"
FIRST_ARCH="${ARCHS%% *}"
if [ "${FIRST_ARCH}" == "i386" ];
then
    PLATFORM="iPhoneSimulator"
else
    PLATFORM="iPhoneOS"
fi
cp -R "${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${FIRST_ARCH}/include/" \
      "${DIR}/include/"

echo ""
echo "* Finished; ${LIBNAME} binary created for archs: ${ARCHS}"

