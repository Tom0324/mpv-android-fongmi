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

[ -f configure ] || ./bootstrap

mkdir -p $build
cd $build

# Minimal static build for Android:
#  - in-tree libudfread provides ISO/UDF reading (--without-external-libudfread)
#  - disable BD-J jar/fontconfig/freetype/libxml2 to avoid Android-hostile deps
#  - mpv only needs libbluray core (disc navigation + ISO), not the Java menu UI
../configure \
	--host=$ndk_triple --with-pic \
	--enable-static --disable-shared \
	--disable-bdjava-jar \
	--without-libxml2 --without-freetype --without-fontconfig \
	--without-external-libudfread

make -j$cores
make DESTDIR="$prefix_dir" install
