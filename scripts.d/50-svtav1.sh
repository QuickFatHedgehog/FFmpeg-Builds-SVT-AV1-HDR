#!/bin/bash

SCRIPT_REPO="https://github.com/juliobbv-p/svt-av1-hdr.git"
SCRIPT_COMMIT="20c88a7cec170c03294869b4137d21a124c31b2e"

ffbuild_enabled() {
    [[ $TARGET == win32 ]] && return -1
    (( $(ffbuild_ffver) > 700 )) || return -1
    return 0
}

ffbuild_dockerdl() {
    echo "git clone \"$SCRIPT_REPO\" . && git checkout \"$SCRIPT_COMMIT\""
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_APPS=OFF -DENABLE_AVX512=ON -DSVT_AV1_LTO=OFF ..
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"
}

ffbuild_configure() {
    echo --enable-libsvtav1
}

ffbuild_unconfigure() {
    echo --disable-libsvtav1
}
