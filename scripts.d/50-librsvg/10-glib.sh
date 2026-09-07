#!/bin/bash

SCRIPT_REPO="https://github.com/gnome/glib.git"
SCRIPT_COMMIT="fb43b26b26e9d4a7a2ab6c2252951e039058297e"

ffbuild_depends() {
    echo base
    echo zlib
    echo libiconv
    echo pcre2
    echo libffi
}

ffbuild_enabled() {
    return 0
}

ffbuild_dockerdl() {
    default_dl .
    echo "git submodule update --init --recursive --depth=1"
    echo "meson subprojects download proxy-libintl"
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        --wrap-mode=nodownload
        -Dtests=false
        -Dinstalled_tests=false
        -Dglib_debug=disabled
        -Dnls=disabled
        -Dintrospection=disabled
        -Ddocumentation=false
        -Dman-pages=disabled
        -Dsysprof=disabled
        -Dlibelf=disabled
        -Dmultiarch=false
        -Dbsymbolic_functions=false
    )

    if [[ $TARGET == linux* ]]; then
        myconf+=(
            -Dselinux=disabled
            -Dlibmount=disabled
            -Ddtrace=disabled
            -Dsystemtap=disabled
        )
    fi

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    else
        echo "Unknown target"
        return -1
    fi

    meson setup "${myconf[@]}" ..
    ninja -j$(nproc)
    DESTDIR="$FFBUILD_DESTDIR" ninja install

    rm -rf "$FFBUILD_DESTPREFIX"/share
}
