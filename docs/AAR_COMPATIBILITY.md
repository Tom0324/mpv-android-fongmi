# AAR 兼容性说明

本文件记录 `mpv-android-avcfix.aar` 的 ABI 与版本兼容范围。

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

## 当前版本基线

验证日期：

```text
2026-11-24
```

版本：

| 组件 | 版本 |
|---|---|
| mpv | `v0.42.0` |
| FFmpeg | `n9.1` |
| FFmpeg commit | `74e4393595cf2b5857f0da925c4e0dd74ea306e5` |
| libplacebo | `v7.387.0` |
| AVC | PTS patch 已应用 |
| JNI | `event(int, MPVNode)` |

---

## 历史版本说明

```text
v7.399.0 曾用于旧构建，但不是 libplacebo 官方稳定 tag/release。
当前稳定基线是 v7.387.0。
```

---

## 当前 Release

```text
tag: native-avcfix-mpv042-ffmpeg9.1-lp7.387.0
asset: app-release.aar
```

XNPlayer 使用路径：

```text
app/libs/mpv-android-avcfix.aar
```

---

## 如何验证 AAR

下载 `app-release.aar` 后检查：

```text
1. jni/arm64-v8a/ 下存在 native libraries
2. 不存在 jni/armeabi-v7a/
3. 不存在 jni/x86/
4. 不存在 jni/x86_64/
5. libmpv.so 中存在 mpv v0.42.0
6. JNI 类 MPVLib / MPVNode 存在
7. event(int, MPVNode) 签名存在
```

以上检查全部通过，才能替换 XNPlayer 中的 AAR。
