#include <stdlib.h>
#include <string>

#include <jni.h>
#include <android/bitmap.h>
#include <mpv/client.h>

#include "jni_utils.h"
#include "globals.h"
#include "log.h"

extern "C" {
    jni_func(jobject, grabThumbnail, jint dimension);
    jni_func(jobject, grabThumbnailFast, jstring jpath, jdouble position, jint dimension, jboolean use_hw_dec);
    jni_func(void, setThumbnailJavaVM, jobject appctx);
    jni_func(void, clearThumbnailCache);
};

static inline mpv_node make_node_str(const char *s)
{
    mpv_node r{};
    r.format = MPV_FORMAT_STRING;
    r.u.string = const_cast<char*>(s);
    return r;
}

jni_func(jobject, grabThumbnail, jint dimension) {
    if (!check_mpv_initialized())
        return NULL;

    mpv_node result{};
    {
        mpv_node c{}, c_args[2];
        mpv_node_list c_array{};
        c_args[0] = make_node_str("screenshot-raw");
        c_args[1] = make_node_str("video");
        c_array.num = 2;
        c_array.values = c_args;
        c.format = MPV_FORMAT_NODE_ARRAY;
        c.u.list = &c_array;
        if (mpv_command_node(g_mpv, &c, &result) < 0) {
            ALOGE("screenshot-raw command failed");
            return NULL;
        }
    }

    int w = 0, h = 0, stride = 0;
    bool format_ok = false;
    struct mpv_byte_array *data = NULL;
    do {
        if (result.format != MPV_FORMAT_NODE_MAP)
            break;
        for (int i = 0; i < result.u.list->num; i++) {
            std::string key(result.u.list->keys[i]);
            const mpv_node *val = &result.u.list->values[i];
            if (key == "w" || key == "h" || key == "stride") {
                if (val->format != MPV_FORMAT_INT64)
                    break;
                if (key == "w")
                    w = val->u.int64;
                else if (key == "h")
                    h = val->u.int64;
                else
                    stride = val->u.int64;
            } else if (key == "format") {
                if (val->format != MPV_FORMAT_STRING)
                    break;
                format_ok = !strcmp(val->u.string, "bgr0");
            } else if (key == "data") {
                if (val->format != MPV_FORMAT_BYTE_ARRAY)
                    break;
                data = val->u.ba;
            }
        }
    } while (0);
    if (!w || !h || !stride || !format_ok || !data) {
        ALOGE("extracting data failed");
        mpv_free_node_contents(&result);
        return NULL;
    }

    int crop_left = 0, crop_top = 0;
    int new_w = w, new_h = h;
    if (w > h) {
        crop_left = (w - h) / 2;
        new_w = h;
    } else {
        crop_top = (h - w) / 2;
        new_h = w;
    }

    uint8_t *src = reinterpret_cast<uint8_t*>(data->data);
    jintArray arr = env->NewIntArray(dimension * dimension);
    jint *scaled = env->GetIntArrayElements(arr, NULL);

    // screenshot-raw returns BGR0 (BGRA). Convert to Android ARGB_8888 with
    // nearest-neighbor center-crop scaling; no libswscale dependency.
    for (int y = 0; y < dimension; y++) {
        int sy = crop_top + (new_h == dimension ? y : (y * new_h / dimension));
        const uint8_t *row = src + stride * sy;
        for (int x = 0; x < dimension; x++) {
            int sx = crop_left + (new_w == dimension ? x : (x * new_w / dimension));
            const uint8_t *px = row + sx * 4;
            uint32_t b = px[0], g = px[1], r = px[2], a = px[3];
            scaled[y * dimension + x] = static_cast<jint>(
                (a << 24) | (r << 16) | (g << 8) | b);
        }
    }

    mpv_free_node_contents(&result);
    env->ReleaseIntArrayElements(arr, scaled, 0);

    jobject bitmap_config =
        env->GetStaticObjectField(android_graphics_Bitmap_Config, android_graphics_Bitmap_Config_ARGB_8888);
    jobject bitmap =
        env->CallStaticObjectMethod(android_graphics_Bitmap, android_graphics_Bitmap_createBitmap,
        arr, dimension, dimension, bitmap_config);
    env->DeleteLocalRef(arr);
    env->DeleteLocalRef(bitmap_config);

    return bitmap;
}

// Kept for Java API compatibility. Fast thumbnail generation now uses the
// same mpv screenshot path and ignores the extra arguments.
jni_func(jobject, grabThumbnailFast, jstring jpath, jdouble position, jint dimension, jboolean use_hw_dec) {
    // Fast path is intentionally disabled in the dlsym/JVM-compatible build.
    return NULL;
}

jni_func(void, setThumbnailJavaVM, jobject appctx) {
    // Main JavaVM registration is already done on libffmpeg.so in main.cpp.
}

jni_func(void, clearThumbnailCache) {
    // No separate cache is used by screenshot-raw implementation.
}
