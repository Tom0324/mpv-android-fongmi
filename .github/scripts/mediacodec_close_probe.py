import os
import sys

path = sys.argv[1]
marker = 'PATCH: mediacodec close probe'

with open(path, encoding='utf-8') as f:
    src = f.read()

if marker in src:
    print('already applied', marker)
    raise SystemExit(0)

old = '''    if (s->codec) {\n        if (atomic_load(&s->hw_buffer_count) == 0) {\n            ff_AMediaCodec_stop(s->codec);\n            av_log(avctx, AV_LOG_DEBUG, "MediaCodec %p stopped\\n", s->codec);\n        } else {\n            av_log(avctx, AV_LOG_DEBUG, "Not stopping MediaCodec (there are buffers pending)\\n");\n        }\n    }\n'''

new = '''    if (s->codec) {\n        /* PATCH: mediacodec close probe */\n        int hwbuf = atomic_load(&s->hw_buffer_count);\n        av_log(avctx, AV_LOG_WARNING,\n               "PATCH: mediacodec close probe: codec=%p hw_buffer_count=%d\\n",\n               s->codec, hwbuf);\n        if (hwbuf == 0) {\n            ff_AMediaCodec_stop(s->codec);\n            av_log(avctx, AV_LOG_WARNING,\n                   "PATCH: mediacodec close probe: MediaCodec %p stopped\\n", s->codec);\n        } else {\n            av_log(avctx, AV_LOG_WARNING,\n                   "PATCH: mediacodec close probe: NOT stopping MediaCodec, buffers pending\\n");\n        }\n    }\n'''

count = src.count(old)
if count != 1:
    raise SystemExit('FATAL: mediacodec close anchor count != 1: %d' % count)

out = src.replace(old, new)
with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(out)
print('patched', marker)
