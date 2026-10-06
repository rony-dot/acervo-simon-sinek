#!/usr/bin/env bash
# Varre o canal em busca de episódios novos desde a última transcrição e os converte em texto.
#
#   ./atualizar-acervo.sh              # do dia seguinte à última transcrição até hoje
#   ./atualizar-acervo.sh 20260901     # a partir de uma data específica
#
# Não commita nada. Só baixa, converte e lista o que é novo.
set -uo pipefail

CANAL="https://www.youtube.com/@simonsinek/videos"
MINDUR=0      # sem filtro de duração. O canal mistura clipes solo de 1 a 5 min (o Simon
              # sozinho, que é o que mais interessa) e episódios de podcast de ~1 h.
SUBLANG="en-orig"   # faixa ASR original do YouTube. NUNCA usar faixa traduzida.
PORDIA=2      # o Simon publica ~2 vídeos por semana na aba de vídeos; 2 por dia é folga.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW="$REPO/transcricoes/raw"
TEXTO="$REPO/transcricoes/texto"
mkdir -p "$RAW" "$TEXTO"

# Onde paramos: maior data AAAAMMDD entre os arquivos já transcritos.
ULTIMA="$(ls "$TEXTO" 2>/dev/null | grep -oE '^[0-9]{8}' | sort | tail -1)"
if [ -n "${1:-}" ]; then
  DE="$1"
elif [ -n "$ULTIMA" ]; then
  DE="$(date -j -v+1d -f %Y%m%d "$ULTIMA" +%Y%m%d)"
else
  DE="20260101"
fi
ATE="$(date +%Y%m%d)"

# Profundidade proporcional à lacuna: o canal publica muito por dia, então
# varrer "os N mais recentes" com N fixo não garante alcançar a data inicial.
DIAS=$(( ( $(date -j -f %Y%m%d "$ATE" +%s) - $(date -j -f %Y%m%d "$DE" +%s) ) / 86400 + 1 ))
FIM=$(( DIAS * PORDIA ))
[ "$FIM" -lt 60 ] && FIM=60
[ "$FIM" -gt 1000 ] && FIM=1000  # o canal inteiro tem ~900 vídeos

echo "Última transcrição: ${ULTIMA:-nenhuma}"
echo "Buscando de $DE até $ATE (${DIAS} dias, duração >= ${MINDUR}s, legenda $SUBLANG)"
echo "Profundidade da varredura: $FIM vídeos"
echo

ANTES="$(ls "$TEXTO"/*.txt 2>/dev/null | wc -l | tr -d ' ')"

# IMPORTANTE: nunca usar --break-on-reject junto com --match-filter de duração.
# Ele para de varrer no primeiro vídeo rejeitado — neste canal a maioria dos
# vídeos é curta, então a varredura morreria nos primeiros itens.
yt-dlp --no-update "$CANAL" --skip-download \
  --playlist-end "$FIM" \
  --dateafter "$DE" --datebefore "$ATE" \
  --match-filter "duration >= $MINDUR" \
  --extractor-args "youtube:lang=en;player_client=web_embedded" \
  --no-simulate --ignore-no-formats-error \
  --write-auto-sub --sub-lang "$SUBLANG" --sub-format json3 \
  --sleep-requests 1 --sleep-subtitles 3 \
  --ignore-errors --no-abort-on-error \
  -o "$RAW/%(id)s.%(ext)s" \
  --print-to-file "%(id)s|%(upload_date)s|%(duration)s|%(title)s" "$RAW/episodios.txt" \
  2>&1 | tee /tmp/sinek-scrape.log | grep -Ei "^\[info\].*writing|^ERROR" | tail -50

# O YouTube limita a taxa de requisições e, quando isso acontece, o yt-dlp
# apenas registra erro por vídeo e segue — a varredura "termina" incompleta
# sem falhar. Sem este aviso, a lacuna passa despercebida.
if grep -qiE "rate-limited|HTTP Error 429|Too Many Requests" /tmp/sinek-scrape.log; then
  echo
  echo "AVISO: o YouTube limitou a taxa desta sessão. A varredura está INCOMPLETA."
  echo "Espere cerca de uma hora e rode de novo — o que já baixou é aproveitado."
fi

# Converte só os json3 que ainda não viraram texto e dá nome AAAAMMDD-slug.txt
SUBLANG="$SUBLANG" python3 - "$REPO" <<'PYEOF'
import glob, json, os, re, subprocess, sys, unicodedata

repo = sys.argv[1]
raw   = os.path.join(repo, "transcricoes", "raw")
texto = os.path.join(repo, "transcricoes", "texto")
sublang = os.environ.get("SUBLANG", "en-orig")

# id -> (data, titulo) a partir do episodios.txt
meta = {}
cat = os.path.join(raw, "episodios.txt")
if os.path.exists(cat):
    for linha in open(cat, encoding="utf-8"):
        p = linha.rstrip("\n").split("|", 3)
        if len(p) == 4:
            meta[p[0]] = (p[1], p[3])

def slug(titulo):
    s = "".join(c if unicodedata.normalize("NFKD", c).encode("ascii", "ignore") else "-"
                for c in titulo.lower())
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s[:60].rstrip("-")

# A chave de "já transcrito" é data+slug, não só a data, para não confundir
# dois vídeos publicados no mesmo dia.
ja_tem = {f[:-4] for f in os.listdir(texto) if f.endswith(".txt")}

novos = []
for f in sorted(glob.glob(os.path.join(raw, f"*.{sublang}.json3"))):
    vid = os.path.basename(f).split(".")[0]
    if vid not in meta:
        continue
    data, titulo = meta[vid]
    base = f"{data}-{slug(titulo)}"
    if base in ja_tem:
        continue
    subprocess.run([sys.executable, os.path.join(raw, "conv.py"), vid],
                   check=True, capture_output=True)
    origem = os.path.join(texto, vid + ".txt")
    if os.path.exists(origem):
        os.rename(origem, os.path.join(texto, base + ".txt"))
        palavras = len(open(os.path.join(texto, base + ".txt"), encoding="utf-8").read().split())
        novos.append((data, base + ".txt", palavras))
        ja_tem.add(base)

if novos:
    print(f"\n{len(novos)} episódio(s) novo(s):\n")
    for data, nome, palavras in sorted(novos):
        d = f"{data[6:8]}/{data[4:6]}/{data[0:4]}"
        print(f"  {d}  {palavras:>6} palavras  {nome}")
else:
    print("\nNenhum episódio novo.")
PYEOF

DEPOIS="$(ls "$TEXTO"/*.txt 2>/dev/null | wc -l | tr -d ' ')"
echo
echo "Total de transcrições: $ANTES -> $DEPOIS"
