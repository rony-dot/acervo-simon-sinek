#!/usr/bin/env python3
"""Converte legendas json3 do YouTube em texto limpo com timestamps por minuto.

    python3 conv.py            # converte tudo que estiver em raw/
    python3 conv.py <video_id> # converte só um
"""
import json, glob, os, re, sys

BASE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.join(os.path.dirname(BASE), "texto")
os.makedirs(OUTDIR, exist_ok=True)

# Faixa de legenda deste acervo (canal em inglês). Sobrescreva com SUBLANG=en se
# o canal não tiver a faixa ASR original "en-orig".
SUBLANG = os.environ.get("SUBLANG", "en-orig")

alvo = sys.argv[1] if len(sys.argv) > 1 else "*"
arquivos = sorted(glob.glob(os.path.join(BASE, f"{alvo}.{SUBLANG}.json3")))

if not arquivos:
    sys.exit(f"nada encontrado para '{alvo}' em {BASE}")

for f in arquivos:
    vid = os.path.basename(f).split(".")[0]
    data = json.load(open(f, encoding="utf-8"))

    linhas = []
    for ev in data.get("events", []):
        segs = ev.get("segs")
        if not segs:
            continue
        texto = "".join(s.get("utf8", "") for s in segs).replace("\n", " ").strip()
        if not texto:
            continue
        # legenda rolante repete a última linha; descarta
        if linhas and linhas[-1][1] == texto:
            continue
        linhas.append((ev.get("tStartMs", 0), texto))

    # agrupa em parágrafos, com um timestamp a cada ~60s
    out, buf, ultimo = [], [], -1
    for ms, t in linhas:
        seg = ms // 1000
        if ultimo < 0 or seg - ultimo >= 60:
            if buf:
                out.append(" ".join(buf))
                buf = []
            out.append("\n[%02d:%02d:%02d]" % (seg // 3600, (seg % 3600) // 60, seg % 60))
            ultimo = seg
        buf.append(t)
    if buf:
        out.append(" ".join(buf))

    txt = re.sub(r"[ \t]+", " ", "\n".join(out))
    open(os.path.join(OUTDIR, vid + ".txt"), "w", encoding="utf-8").write(txt)

    dur = linhas[-1][0] // 1000 if linhas else 0
    print("    %s  %d min  %d palavras" % (vid, dur // 60, len(txt.split())))
