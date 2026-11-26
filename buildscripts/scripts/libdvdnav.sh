#!/bin/bash -e

. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

[ -f configure ] || autoreconf -fi

mkdir -p $build
cd $build

# libdvdread is found via PKG_CONFIG_LIBDIR (set by buildall.sh -> prefix_dir/lib/pkgconfig)
../configure \
	--host=$ndk_triple --with-pic \
	--enable-static --disable-shared

make -j$cores
make DESTDIR="$prefix_dir" install
