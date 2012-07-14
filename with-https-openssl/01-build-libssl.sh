#!/bin/bash

VERSION="1.0.1c"
LIBNAME="libssl"
LIBDOWNLOAD="http://www.openssl.org/source/openssl-${VERSION}.tar.gz"
ARCHIVE="${LIBNAME}-${VERSION}.tar.gz"

SDK="5.1"
CONFIGURE_FLAGS=""

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
    tar zxf ${ARCHIVE} -C "${DIR}/src"
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
    mv -f "${DIR}/src/openssl-${VERSION}" "${DIR}/src/${LIBNAME}-${VERSION}"

    if [ "${PLATFORM}" == "iPhoneOS" ];
    then
        sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" \
                "${DIR}/src/${LIBNAME}-${VERSION}/crypto/ui/ui_openssl.c"
    fi

    mkdir -p "${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}"
    LOG="${DIR}/log/${LIBNAME}-${VERSION}-${PLATFORM}${SDK}-${ARCH}.log"

    cd "${DIR}/src/${LIBNAME}-${VERSION}"

    DEVROOT="${XCODE}/Platforms/${PLATFORM}.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK}.sdk"
    export CC="${DEVROOT}/usr/bin/llvm-gcc-4.2 -arch ${ARCH} -isysroot ${SDKROOT}"
    export LD="${DEVROOT}/usr/bin/ld -arch ${ARCH} -isysroot ${SDKROOT}"
    export AR="${DEVROOT}/usr/bin/ar"
    export AS="${DEVROOT}/usr/bin/as"
    export NM="${DEVROOT}/usr/bin/nm"
    export RANLIB="${DEVROOT}/usr/bin/ranlib"

    ./configure BSD-generic32 no-shared ${CONFIGURE_FLAGS} \
                --openssldir="${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}"

    make
    make install
    cd ${DIR}
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
done


# Create a single .a file for all architectures
echo ""
echo "* Creating binaries for ${LIBNAME}..."
LIBS="${LIBNAME} libcrypto"
# Build for all archs
for LIB in ${LIBS}
do
    lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneSimulator${SDK}-i386/lib/${LIB}.a" \
                 "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv7/lib/${LIB}.a" \
         -output "${DIR}/lib/${LIB}.a"

    # Create a single .a file for all arm architectures
    lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneOS${SDK}-armv7/lib/${LIB}.a" \
         -output "${DIR}/lib/${LIB}-armv7.a"

    # Create a single .a file for i386
    lipo -create "${DIR}/bin/${LIBNAME}-${VERSION}/iPhoneSimulator${SDK}-i386/lib/${LIB}.a" \
         -output "${DIR}/lib/${LIB}-i386.a"
done


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
