# mpv-android-fongmi

Native source repository for the AVC-fixed mpv Android AAR used by XNPlayer.

This repository is public. It is still a core build dependency and must not be deleted.

## Purpose

Builds the AAR consumed by `Tom0324/mpvEx-private/app/libs/mpv-android-avcfix.aar`.

It owns:

- mpv source pin
- FFmpeg source pin
- libplacebo source pin
- AVC PTS patch
- Android native AAR build workflow
- AAR Release asset

## Current release

Tag:

```text
native-avcfix-mpv042-ffmpeg9.1-lp7.387.0
```

Asset:

```text
app-release.aar
```

Consumed by the app repo as:

```text
app/libs/mpv-android-avcfix.aar
```

## Current pin and patch

Verified 2026-11-24:

- mpv: `v0.42.0`
- FFmpeg: `n9.1`, commit `74e4393595cf2b5857f0da925c4e0dd74ea306e5`
- libplacebo: `v7.387.0`
- AVC: native PTS patch applied in `.github/workflows/build_avcfix.yml`

`v7.399.0` was an earlier non-release build string and is no longer used.

## AAR ABI compatibility

Verified from the current release asset:

| ABI | Supported | Note |
|---|---:|---|
| `arm64-v8a` | Yes | Current AAR contains 10 arm64 native libraries |
| `armeabi-v7a` | No | Not built into this AAR |
| `x86` | No | Not built into this AAR |
| `x86_64` | No | Not built into this AAR |
| universal | No | This is not a universal AAR |

So this AAR is **v8 only**. It cannot be installed/used as the native core for v7a, x86 or x86_64 builds.

The app repository is also arm64-only.

## Why only arm64

The patched native build was validated for:

```text
mpv 0.42.0 + AVC PTS patch + mpvEx JNI event(int, MPVNode)
```

Adding v7a/x86/x86_64 requires:

1. adding ABI build steps to `build_avcfix.yml`
2. validating JNI for each ABI
3. producing a multi-ABI AAR or separate per-ABI AARs
4. changing the app build config

Until then, do not promise v7a/x86 support.

## Workflow

Main workflow:

```text
.github/workflows/build_avcfix.yml
```

It:

1. pins mpv to `v0.42.0`
2. applies the AVC PTS patch
3. pins FFmpeg and libplacebo
4. builds arm64 native libraries
5. uploads `app-release.aar` to the GitHub Release asset

## Do not delete

Do not delete:

- this repository
- the Release tag `native-avcfix-mpv042-ffmpeg9.1-lp7.387.0`
- the Release asset `app-release.aar`
- `.github/workflows/build_avcfix.yml`

Deleting them loses the reproducible source of the AVC-fixed native core.

## Relationship with app repo

Main app repo:

```text
https://github.com/Tom0324/mpvEx-private
```

This repo produces the native AAR. The app repo assembles the APK.
