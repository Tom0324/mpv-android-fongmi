import os
import sys

base = sys.argv[1] if len(sys.argv) > 1 else '.'


def patch(rel, marker, old, new, features=()):
    path = os.path.join(base, rel)
    with open(path, encoding='utf-8') as f:
        src = f.read()
    if marker in src:
        print('already applied', marker, rel)
        return
    count = src.count(old)
    if count != 1:
        raise SystemExit('FATAL: %s anchor count != 1: %d' % (marker, count))
    out = src.replace(old, new)
    for feat in features:
        if feat not in out:
            raise SystemExit('FATAL: %s lost feature anchor: %s' % (marker, feat))
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out)
    print('patched', marker, rel)


patch(
    'player/loadfile.c',
    'PATCH: vo_eof_reset A',
    '''    reinit_complex_filters(mpctx, true);\n    uninit_audio_chain(mpctx);\n    uninit_video_chain(mpctx);\n    uninit_sub_all(mpctx);\n''',
    '''    reinit_complex_filters(mpctx, true);\n    uninit_audio_chain(mpctx);\n    /* PATCH: vo_eof_reset A - uninit_video_chain() sets vo_chain to NULL,\n     * so save the VO and release its frame refs before the decoder goes away. */\n    struct vo *eof_reset_vo = mpctx->vo_chain ? mpctx->vo_chain->vo : NULL;\n    if (eof_reset_vo) {\n        MP_VERBOSE(mpctx, "PATCH: vo_eof_reset A: releasing VO frames\\n");\n        vo_eof_reset(eof_reset_vo);\n    }\n    uninit_video_chain(mpctx);\n    uninit_sub_all(mpctx);\n''',
    ('uninit_video_chain(mpctx);', 'uninit_sub_all(mpctx);', 'PATCH: vo_eof_reset A'),
)

patch(
    'video/out/vo.c',
    'PATCH: vo_eof_reset B',
    '    bool send_reset;                // send VOCTRL_RESET\n',
    '    uint8_t send_reset;             /* PATCH: vo_eof_reset B - 1=RESET, 2=FRAME_RESET */\n',
    ('forget_frames(vo)', 'reset_vsync_timings(vo)'),
)

patch(
    'video/out/vo.c',
    'PATCH: vo_eof_reset C',
    '        bool send_reset = in->send_reset;\n        in->send_reset = false;\n',
    '        uint8_t send_reset = in->send_reset; /* PATCH: vo_eof_reset C */\n        in->send_reset = 0;\n',
)

patch(
    'video/out/vo.c',
    'PATCH: vo_eof_reset D',
    '        if (send_reset)\n            vo->driver->control(vo, VOCTRL_RESET, NULL);\n',
    '        if (send_reset > 0)\n            vo->driver->control(vo, VOCTRL_RESET, NULL);\n        if (send_reset == 2) /* PATCH: vo_eof_reset D */\n            vo->driver->control(vo, VOCTRL_FRAME_RESET, NULL);\n',
)

patch(
    'video/out/vo.c',
    'PATCH: vo_eof_reset E',
    '''void vo_seek_reset(struct vo *vo)\n{\n    struct vo_internal *in = vo->in;\n    mp_mutex_lock(&in->lock);\n    forget_frames(vo);\n    reset_vsync_timings(vo);\n    in->send_reset = true;\n    wakeup_locked(vo);\n    mp_mutex_unlock(&in->lock);\n}\n''',
    '''static void send_reset(struct vo *vo, bool forget_all)\n{\n    struct vo_internal *in = vo->in;\n    mp_mutex_lock(&in->lock);\n    forget_frames(vo);\n    if (forget_all)\n        TA_FREEP(&in->current_frame);\n    reset_vsync_timings(vo);\n    in->send_reset = MPMAX(in->send_reset, forget_all ? 2 : 1);\n    wakeup_locked(vo);\n    mp_mutex_unlock(&in->lock);\n}\n\nvoid vo_seek_reset(struct vo *vo)\n{\n    send_reset(vo, false);\n}\n\n/* PATCH: vo_eof_reset E - forget all frame refs on EOF */\nvoid vo_eof_reset(struct vo *vo)\n{\n    send_reset(vo, true);\n}\n''',
)

patch(
    'video/out/vo.h',
    'PATCH: vo_eof_reset F',
    '''    /* signal a device reset seek */\n    VOCTRL_RESET = 1,\n    /* Handle input and redraw events, called by vo_check_events() */\n''',
    '''    /* signal a device reset seek */\n    VOCTRL_RESET = 1,\n    /* PATCH: vo_eof_reset F - forget all frames (sent with VOCTRL_RESET) */\n    VOCTRL_FRAME_RESET,\n    /* Handle input and redraw events, called by vo_check_events() */\n''',
    ('VOCTRL_CHECK_EVENTS',),
)

patch(
    'video/out/vo.h',
    'PATCH: vo_eof_reset G',
    'void vo_seek_reset(struct vo *vo);\nvoid vo_destroy(struct vo *vo);\n',
    'void vo_seek_reset(struct vo *vo);\nvoid vo_eof_reset(struct vo *vo); /* PATCH: vo_eof_reset G */\nvoid vo_destroy(struct vo *vo);\n',
)

patch(
    'video/out/vo_gpu.c',
    'PATCH: vo_eof_reset H',
    '''    case VOCTRL_RESET:\n        gl_video_reset(p->renderer);\n        return true;\n''',
    '''    case VOCTRL_RESET:\n        gl_video_reset(p->renderer);\n        return true;\n    case VOCTRL_FRAME_RESET: /* PATCH: vo_eof_reset H */\n        gl_video_reset_frame(p->renderer);\n        return true;\n''',
    ('gl_video_reset(p->renderer)',),
)

patch(
    'video/out/gpu/video.c',
    'PATCH: vo_eof_reset I',
    '''void gl_video_reset(struct gl_video *p)\n{\n    gl_video_reset_surfaces(p);\n}\n''',
    '''void gl_video_reset(struct gl_video *p)\n{\n    gl_video_reset_surfaces(p);\n}\n\nvoid gl_video_reset_frame(struct gl_video *p)\n{\n    /* PATCH: vo_eof_reset I */\n    unref_current_image(p);\n}\n''',
    ('unref_current_image(p)', 'gl_video_reset_surfaces(p)'),
)

patch(
    'video/out/gpu/video.h',
    'PATCH: vo_eof_reset J',
    'void gl_video_reset(struct gl_video *p);\nbool gl_video_showing_interpolated_frame(struct gl_video *p);\n',
    'void gl_video_reset(struct gl_video *p);\nvoid gl_video_reset_frame(struct gl_video *p); /* PATCH: vo_eof_reset J */\nbool gl_video_showing_interpolated_frame(struct gl_video *p);\n',
)

patch(
    'video/out/vo_gpu_next.c',
    'PATCH: vo_eof_reset K',
    '''    case VOCTRL_RESET:\n        // Defer until the first new frame (unique ID) actually arrives\n        p->want_reset = true;\n        p->reset_map_failed_id = 0;\n        return VO_TRUE;\n''',
    '''    case VOCTRL_RESET:\n        // Defer until the first new frame (unique ID) actually arrives\n        p->want_reset = true;\n        p->reset_map_failed_id = 0;\n        return VO_TRUE;\n    case VOCTRL_FRAME_RESET: /* PATCH: vo_eof_reset K */\n        reset_frame_queue(p);\n        pl_renderer_flush_cache(p->rr);\n        p->flush_cache = false;\n        p->want_reset = false;\n        return VO_TRUE;\n''',
    ('reset_frame_queue', 'pl_queue_reset', 'flush_cache'),
)

patch(
    'video/out/vo_libmpv.c',
    'PATCH: vo_eof_reset L',
    '''    case VOCTRL_RESET:\n        mp_mutex_lock(&ctx->lock);\n        forget_frames(ctx, false);\n        ctx->need_reset = true;\n        mp_mutex_unlock(&ctx->lock);\n        vo->want_redraw = true;\n        return VO_TRUE;\n''',
    '''    case VOCTRL_RESET:\n    case VOCTRL_FRAME_RESET: /* PATCH: vo_eof_reset L */\n        mp_mutex_lock(&ctx->lock);\n        forget_frames(ctx, request == VOCTRL_FRAME_RESET);\n        ctx->need_reset = true;\n        mp_mutex_unlock(&ctx->lock);\n        vo->want_redraw = true;\n        return VO_TRUE;\n''',
    ('ctx->need_reset = true',),
)
