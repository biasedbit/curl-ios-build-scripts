#!/bin/bash

VERSION="1.0.0g"
LIBNAME="libssl"
LIBDOWNLOAD="http://www.openssl.org/source/openssl-${VERSION}.tar.gz"
ARCHIVE="${LIBNAME}-${VERSION}.tar.gz"

SDK="5.1"
CONFIGURE_FLAGS=""

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

    # pre Xcode 4.3 DEVROOT
    # export DEVROOT="/Developer/Platforms/${PLATFORM}.platform/Developer"
    export DEVROOT="/Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer"
    export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK}.sdk"
    export CC="${DEVROOT}/usr/bin/llvm-gcc-4.2 -arch ${ARCH} -isysroot ${SDKROOT}"
    export LD="${DEVROOT}/usr/bin/ld -arch ${ARCH} -isysroot ${SDKROOT}"
    export AR="${DEVROOT}/usr/bin/ar"
    export AS="${DEVROOT}/usr/bin/as"
    export NM="${DEVROOT}/usr/bin/nm"
    export RANLIB="${DEVROOT}/usr/bin/ranlib"

    ./configure BSD-generic32 no-shared ${CONFIGURE_FLAGS} \
                --openssldir="${DIR}/bin/${LIBNAME}-${VERSION}/${PLATFORM}${SDK}-${ARCH}" >> "${LOG}" 2>&1

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
