#!/usr/bin/env bash
# Baixa e transcreve os Shorts do canal (aba /shorts), separados dos vídeos longos.
#
#   ./baixar-shorts.sh              # todos os shorts do canal
#   ./baixar-shorts.sh 20260901     # só os publicados a partir dessa data
#
# Os shorts ficam em transcricoes/shorts/ e no catálogo shorts.txt, para não
# se misturarem aos episódios longos (que alimentam o skill). O uso principal
# dos shorts é garimpar ganchos e frases para roteiro.
#
# Roda em rodadas porque o YouTube limita a taxa da sessão: nesse caso o yt-dlp
# registra erro por vídeo e segue, terminando incompleto sem falhar.
set -uo pipefail

CANAL="https://www.youtube.com/@simonsinek/shorts"
DE="${1:-19700101}"
ATE="$(date +%Y%m%d)"
RODADAS="${RODADAS:-14}"
ESPERA="${ESPERA:-3600}"   # o bloqueio do YouTube costuma durar de uma a várias horas

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW="$REPO/transcricoes/raw-shorts"
SAIDA="$REPO/transcricoes/shorts"
mkdir -p "$RAW" "$SAIDA"
LOG=/tmp/sinek-shorts.log

conta() { find "$RAW" -name "*.json3" | wc -l | tr -d ' '; }

echo "Shorts de $DE a $ATE. Legendas já baixadas: $(conta)"
for r in $(seq 1 "$RODADAS"); do
  ANTES=$(conta)
  yt-dlp --no-update "$CANAL" --skip-download \
    --playlist-end 3000 \
    --dateafter "$DE" --datebefore "$ATE" \
    --extractor-args "youtube:lang=en;player_client=web_embedded" \
    --no-simulate --ignore-no-formats-error \
    --write-auto-sub --sub-lang "en-orig" --sub-format json3 \
    --sleep-requests 2 --sleep-subtitles 3 \
    --ignore-errors --no-abort-on-error \
    -o "$RAW/%(id)s.%(ext)s" \
    --print-to-file "%(id)s|%(upload_date)s|%(duration)s|%(title)s" "$RAW/shorts.txt" \
    > "$LOG" 2>&1
  DEPOIS=$(conta)
  echo "  rodada $r: +$((DEPOIS-ANTES)) (total $DEPOIS)"
  if grep -qiE "rate-limited|HTTP Error 429|Too Many Requests" "$LOG"; then
    echo "  YouTube limitou a taxa; esperando $((ESPERA/60)) min."
    [ "$r" -lt "$RODADAS" ] && sleep "$ESPERA"
  else
    break
  fi
done

# Converte as legendas en-orig (ASR original em inglês) em texto.
python3 - "$RAW" "$SAIDA" <<'PYEOF'
import glob, json, os, re, sys, unicodedata
raw, saida = sys.argv[1], sys.argv[2]
meta = {}
cat = os.path.join(raw, "shorts.txt")
if os.path.exists(cat):
    for l in open(cat, encoding="utf-8"):
        p = l.rstrip("\n").split("|", 3)
        if len(p) == 4: meta[p[0]] = (p[1], p[2], p[3])
    # deduplica o catálogo, que cresce a cada rodada
    with open(cat, "w", encoding="utf-8") as fh:
        for k, (d, dur, t) in sorted(meta.items(), key=lambda kv: kv[1][0]):
            fh.write(f"{k}|{d}|{dur}|{t}\n")
def slug(t):
    s = "".join(c if unicodedata.normalize("NFKD", c).encode("ascii", "ignore") else "-" for c in t.lower())
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")[:60].rstrip("-")
arquivos = {}
for f in glob.glob(os.path.join(raw, "*.json3")):
    vid, lang = os.path.basename(f).split(".")[:2]
    if vid not in arquivos or lang == "en-orig": arquivos[vid] = f
ja = set(os.listdir(saida)); novos = 0
for vid, f in arquivos.items():
    if vid not in meta: continue
    d, _, tit = meta[vid]
    nome = f"{d}-{slug(tit) or vid}.txt"
    if nome in ja: continue
    ev = json.load(open(f, encoding="utf-8")).get("events", [])
    partes = []
    for e in ev:
        t = "".join(s.get("utf8", "") for s in e.get("segs") or []).replace("\n", " ").strip()
        if t and (not partes or partes[-1] != t): partes.append(t)
    txt = re.sub(r"\s+", " ", " ".join(partes)).strip()
    if len(txt.split()) < 8: continue
    open(os.path.join(saida, nome), "w", encoding="utf-8").write(f"{tit}\n\n{txt}\n")
    ja.add(nome); novos += 1
print(f"shorts convertidos agora: {novos} | total: {len(os.listdir(saida))}")
PYEOF
