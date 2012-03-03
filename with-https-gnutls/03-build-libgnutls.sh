#!/bin/bash

PRECEDENT_VERSION="1.5.0"
PRECEDENT_LIBNAME="libgcrypt"
VERSION="2.12.17"
LIBNAME="libgnutls"
LIBDOWNLOAD="http://ftp.gnu.org/gnu/gnutls/gnutls-${VERSION}.tar.bz2"
ARCHIVE="${LIBNAME}-${VERSION}.tar.gz"

SDK="5.0"
CONFIGURE_FLAGS="--without-p11-kit"

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

    # Ensure precedent lib is available for this architecture
    if [ -f "${DIR}/bin/${PRECEDENT_LIBNAME}-${PRECEDENT_VERSION}/${PLATFORM}${SDK}-${ARCH}/lib/${PRECEDENT_LIBNAME}.a" ];
    then 
        echo "Using ${PRECEDENT_LIBNAME} ${PRECEDENT_VERSION} (${ARCH})..."
    else
        echo "Please build ${PRECEDENT_LIBNAME} ${PRECEDENT_VERSION} for ${ARCH} first"
        exit 1
    fi

    # Expand source code, prepare output directory and set log
    tar zxf ${ARCHIVE} -C "${DIR}/src"
    rm -rf "${DIR}/src/${LIBNAME}-${VERSION}"
    mv -f "${DIR}/src/gnutls-${VERSION}" "${DIR}/src/${LIBNAME}-${VERSION}"
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

    ./configure --host=${ARCH}-apple-darwin --disable-shared --enable-static --with-libgcrypt ${CONFIGURE_FLAGS} \
                --with-libgcrypt-prefix="${DIR}/bin/${PRECEDENT_LIBNAME}-${PRECEDENT_VERSION}/${PLATFORM}${SDK}-${ARCH}" \
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
