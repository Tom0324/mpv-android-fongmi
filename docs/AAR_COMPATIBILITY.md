# AAR 兼容性说明

本文件记录 `mpv-android-avcfix.aar` 的 ABI 范围、当前 Release 基线与验证方式。版本判断以 **GitHub Release Notes、workflow pin 与 AAR SHA256** 为准；历史 tag 名称不作为二进制版本依据。

---

## ABI 支持

| ABI | 支持 | 说明 |
|---|---:|---|
| `arm64-v8a` | 是 | 当前唯一支持的 ABI |
| `armeabi-v7a` | 否 | 未构建进当前 AAR |
| `x86` | 否 | 未构建进当前 AAR |
| `x86_64` | 否 | 未构建进当前 AAR |
| universal | 否 | 当前不是通用 AAR |

结论：

```text
当前 AAR 只能用于 arm64-v8a。
XNPlayer 当前也只构建 arm64-v8a。
```

---

## 当前 Release

| 项目 | 当前值 |
|---|---|
| Release tag | `native-avcfix-mpv042-iso-eof-frame-reset-sync-20261129` |
| Asset | `app-release.aar` |
| SHA256 | `97174e10559b00cae26480947a5a9b2d5130dc33ad53a5f44e5d263f7c79e51e` |
| 消费方 | XNPlayer workflow 下载后写入 `app/libs/mpv-android-avcfix.aar` |
| ABI | 仅 `arm64-v8a` |

XNPlayer 使用路径：

```text
app/libs/mpv-android-avcfix.aar
```

---

## 当前构建基线

当前主 workflow 为：

```text
.github/workflows/build_iso.yml
```

已核实的关键 pin / 来源：

| 组件 | 来源或固定值 |
|---|---|
| mpv kernel | `76f963cc4002125776f741738b6c1d8cc08daf18` |
| mpv source env | `NextPlayerCloud/mpv.git`，ref `NeoPlayer` |
| FFmpeg env | `NextPlayerCloud/FFmpeg.git` |
| FFmpeg 派生 | `release-8.1-fongmi` |
| libplacebo | `FongMi/libplacebo.git` |
| 字幕 / 解码依赖 | `libass/libass`、`videolan/dav1d` |
| AVC | PTS patch 已应用 |
| JNI | `event(int, MPVNode)`，非空 `MPVNode` |

当前 Release Notes 明确包含：

- AVC PTS patch。
- `stream_iso/fongmi`、DVD / Blu-ray / ISO。
- disc demuxer 始终允许预读。
- FFmpeg MediaCodec configure retry：`20 × 100ms`。
- FFmpeg close 诊断：`hw_buffer_count` 与 stop 决策。
- `hwdec_aimagereader.c` uninit 释放顺序修复。
- 同步 EOF frame reset，参考 mpv PR #14631。
- NeoPlayer 特性保留：Vulkan、Dolby Vision GPU mapping、HDR 色彩空间、stale-frame 检查、retained frame、异步 image API、`max_images=5`、AImageReader stats。

---

## 历史版本说明

早期 Release `native-avcfix-mpv042-ffmpeg9.1-lp7.387.0` 使用过：

```text
FFmpeg n9.1
libplacebo v7.387.0
```

这属于历史基线，不是当前 Release 的构建目标。当前主线已切换到 FongMi / NeoPlayer recipe，Release tag 中的 `mpv042` 也只是历史命名，不代表当前二进制版本字符串。

---

## 如何验证 AAR

下载 `app-release.aar` 后，按顺序检查：

```text
1. SHA256 = 97174e10559b00cae26480947a5a9b2d5130dc33ad53a5f44e5d263f7c79e51e
2. jni/arm64-v8a/ 下存在 native libraries
3. 不存在 jni/armeabi-v7a/
4. 不存在 jni/x86/
5. 不存在 jni/x86_64/
6. libmpv.so 存在 ISO / DVD / bluray 标记
7. libmpv.so 存在 force-iso / stream_iso 标记
8. libmpv.so 存在 MPVLib JNI 标记
9. event(int, MPVNode) 签名存在
10. AVC PTS patch、configure retry、close probe、EOF frame reset 的构建日志标记存在
```

XNPlayer workflow 当前固定校验同一个 SHA256。若 SHA256 不匹配，不要替换 XNPlayer 中的 AAR。
