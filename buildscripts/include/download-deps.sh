#!/bin/bash -e

. ./include/depinfo.sh

[ -z "$IN_CI" ] && IN_CI=0
[ -z "$WGET" ] && WGET=wget

mkdir -p deps && cd deps

# mbedtls
if [ ! -d mbedtls ]; then
	mkdir mbedtls
	$WGET https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$v_mbedtls/mbedtls-$v_mbedtls.tar.bz2 -O - | \
		tar -xj -C mbedtls --strip-components=1
fi

# dav1d
[ ! -d dav1d ] && git clone https://github.com/videolan/dav1d

# ffmpeg
if [ ! -d ffmpeg ]; then
	args=()
	[ $IN_CI -eq 1 ] && args+=(--depth=1 -b "$v_ci_ffmpeg")
	# FongMi fork provides av_mediacodec_release_buffer_status() used by FongMi/mpv
	git clone https://github.com/FongMi/FFmpeg.git ffmpeg "${args[@]}"
fi

# freetype2
[ ! -d freetype2 ] && git clone --recurse-submodules https://gitlab.freedesktop.org/freetype/freetype.git freetype2 -b VER-${v_freetype//./-}

# fribidi
if [ ! -d fribidi ]; then
	mkdir fribidi
	$WGET https://github.com/fribidi/fribidi/releases/download/v$v_fribidi/fribidi-$v_fribidi.tar.xz -O - | \
		tar -xJ -C fribidi --strip-components=1
fi

# harfbuzz
if [ ! -d harfbuzz ]; then
	mkdir harfbuzz
	$WGET https://github.com/harfbuzz/harfbuzz/releases/download/$v_harfbuzz/harfbuzz-$v_harfbuzz.tar.xz -O - | \
		tar -xJ -C harfbuzz --strip-components=1
fi

# unibreak
if [ ! -d unibreak ]; then
	mkdir unibreak
	$WGET https://github.com/adah1972/libunibreak/releases/download/libunibreak_${v_unibreak//./_}/libunibreak-${v_unibreak}.tar.gz -O - | \
		tar -xz -C unibreak --strip-components=1
fi

# libxml2
if [ ! -d libxml2 ]; then
	mkdir libxml2
	$WGET https://gitlab.gnome.org/GNOME/libxml2/-/archive/v${v_libxml2}/libxml2-v${v_libxml2}.tar.gz -O - | \
		tar -xz -C libxml2 --strip-components=1
fi

# fontconfig
if [ ! -d fontconfig ]; then
	mkdir fontconfig
	$WGET https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/${v_fontconfig}/fontconfig-${v_fontconfig}.tar.gz -O - | \
		tar -xz -C fontconfig --strip-components=1
fi

# libass
[ ! -d libass ] && git clone https://github.com/libass/libass

# lua
if [ ! -d lua ]; then
	mkdir lua
	$WGET https://www.lua.org/ftp/lua-$v_lua.tar.gz -O - | \
		tar -xz -C lua --strip-components=1
fi

# shaderc
mkdir -p shaderc
cat >shaderc/README <<'HEREDOC'
shaderc sources are provided by the NDK
see <ndk>/sources/third_party/shaderc
HEREDOC

# libplacebo
if [ ! -d libplacebo ]; then
	args=()
	[ $IN_CI -eq 1 ] && args+=(--depth=1 -b "$v_ci_libplacebo")
	# FongMi fork carries the pl_rendered_mix API used by FongMi/mpv
	git clone --recursive https://github.com/FongMi/libplacebo.git libplacebo "${args[@]}"
fi

# curl
if [ ! -d curl ]; then
	mkdir curl
	$WGET https://curl.se/download/curl-$v_curl.tar.gz -O - | \
		tar -xz -C curl --strip-components=1
fi

# mpv
[ ! -d mpv ] && git clone https://github.com/mpv-player/mpv

# libdvdread (DVD ISO reading) — use FongMi's tarball + iso9660 patch
if [ ! -d libdvdread ]; then
	mkdir libdvdread
	$WGET "https://downloads.videolan.org/pub/videolan/libdvdread/${v_libdvdread}/libdvdread-${v_libdvdread}.tar.xz" -O - | \
		tar -xJ -C libdvdread --strip-components=1
fi
dvdread_patch=../patches/libdvdread-7.0.1-iso9660.patch
if patch --batch --forward --fuzz=0 --dry-run -d libdvdread -p1 < "$dvdread_patch" >/dev/null 2>&1; then
	patch --batch --forward --fuzz=0 -d libdvdread -p1 < "$dvdread_patch"
elif ! patch --batch --reverse --fuzz=0 --dry-run -d libdvdread -p1 < "$dvdread_patch" >/dev/null 2>&1; then
	echo "WARNING: libdvdread iso9660 patch does not apply to $v_libdvdread; continuing without it" >&2
fi

# libdvdnav (DVD menus + ISO) — FongMi's patches add time-search-floor,
# preserve-stream-callbacks etc. required by stream_iso.c over HTTP.
if [ ! -d libdvdnav ]; then
	mkdir libdvdnav
	$WGET "https://downloads.videolan.org/pub/videolan/libdvdnav/${v_libdvdnav}/libdvdnav-${v_libdvdnav}.tar.xz" -O - | \
		tar -xJ -C libdvdnav --strip-components=1
fi
for nav_patch in ../patches/libdvdnav-7.0.0-go-up-hop.patch \
	../patches/libdvdnav-7.0.0-pgc-cell-duration.patch \
	../patches/libdvdnav-7.0.0-menu-availability.patch \
	../patches/libdvdnav-7.0.0-vm-copy-failure.patch \
	../patches/libdvdnav-7.0.0-time-search-floor.patch \
	../patches/libdvdnav-7.0.0-menu-audio-count.patch \
	../patches/libdvdnav-7.0.0-title-chapter-duration.patch \
	../patches/libdvdnav-7.0.0-preserve-stream-callbacks.patch \
	../patches/libdvdnav-7.0.0-active-logical-stream.patch \
	../patches/libdvdnav-7.0.0-title-scope.patch \
	../patches/libdvdnav-7.0.0-stream-attributes.patch \
	../patches/libdvdnav-7.0.0-block-replay.patch; do
	if patch --batch --forward --fuzz=3 --dry-run -d libdvdnav -p1 < "$nav_patch" >/dev/null 2>&1; then
		patch --batch --forward --fuzz=3 -d libdvdnav -p1 < "$nav_patch"
	elif ! patch --batch --reverse --fuzz=3 --dry-run -d libdvdnav -p1 < "$nav_patch" >/dev/null 2>&1; then
		echo "WARNING: libdvdnav patch $(basename "$nav_patch") does not apply" >&2
	fi
done

# libbluray (Blu-ray ISO/menus) — FongMi version + BD-J/seek patches
if [ ! -d libbluray ]; then
	mkdir libbluray
	$WGET "https://downloads.videolan.org/pub/videolan/libbluray/${v_libbluray}/libbluray-${v_libbluray}.tar.xz" -O - | \
		tar -xJ -C libbluray --strip-components=1
fi
bash ../include/patch-libbluray.sh libbluray

cd ..
