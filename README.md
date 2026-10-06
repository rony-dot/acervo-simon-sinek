# Acervo Simon Sinek

Transcrições dos vídeos do [canal @simonsinek](https://www.youtube.com/@simonsinek), com a aba Vídeos de 2025 em diante e os Shorts do canal, mais um skill de Claude Code destilado a partir delas.

Acervo de estudo, irmão de [`acervo-rony`](https://github.com/rony-dot/acervo-rony), [`acervo-alfredo-soares`](https://github.com/rony-dot/acervo-alfredo-soares), [`acervo-alex-hormozi`](https://github.com/rony-dot/acervo-alex-hormozi) e [`acervo-codie-sanchez`](https://github.com/rony-dot/acervo-codie-sanchez). Mesma estrutura e mesmo pipeline.

**Repositório privado.** São transcrições integrais de conteúdo de terceiro, guardadas para estudo pessoal. Não publique.

---

## Para que serve

1. **Estudar e aplicar**: frameworks, histórias e princípios, sobretudo sobre liderança, propósito (Start With Why), Infinite Game, confiança e cultura, conversas difíceis e amizade.
2. **Matéria-prima para roteiro**: ganchos, frases e histórias, **sempre com a fonte marcada** (vídeo e data), para citar e creditar, nunca para reproduzir.
3. **Inteligência de conteúdo**: as teses que ele defende, como as embala e quem ele leva ao podcast.

O skill é **síntese**, não transcrição colada. As ideias estão destiladas com atribuição, em português, e os termos que ele cunhou ficam em inglês.

---

## O canal e o recorte

Medido em 05/10/2026:

| Aba | Vídeos | Formato |
|---|---|---|
| Vídeos | ~909 | clipes solo de 1 a 5 min e podcast *A Bit of Optimism* de ~1 h |
| Shorts | 416 | menos de 1 min |
| Lives | 14 | book clubs e lives antigas |

**Aba Vídeos, de 2025 em diante:** 193 vídeos, ~78 horas, de 02/01/2025 a 02/10/2026. São cerca de 80 episódios longos (podcast com convidado, séries como *Doing Business in a Chaotic World* e *Feelings at Work*, palestras com perguntas da plateia) e uns 110 clipes curtos em que o Simon fala sozinho.

**Atenção à autoria.** Nos episódios longos, boa parte da fala é do convidado. O skill marca sempre quem disse o quê, e nada de convidado é atribuído ao Simon.

**Shorts:** todos, de qualquer ano. Servem para garimpar ganchos e ficam numa pasta separada para não contaminar o skill. A maioria é trecho recortado dos vídeos, então é esperado que se repitam.

---

## Estrutura

| Pasta | O quê |
|---|---|
| `transcricoes/texto/` | Vídeos da aba Vídeos, texto limpo com timestamp a cada minuto, nome `AAAAMMDD-slug.txt`. |
| `transcricoes/shorts/` | Shorts, um arquivo por short, com o título na primeira linha. |
| `transcricoes/raw/` | Legendas dos vídeos (fora do git), o conversor e `episodios.txt`. |
| `transcricoes/raw-shorts/` | Legendas dos shorts (fora do git) e `shorts.txt`. |
| `skill/` | O skill destilado: referências temáticas, ganchos e fichas de pergunta e resposta. |
| `ganchos/` | Banco completo de ganchos por tema, com versão em português, fala original, fonte e força. |
| `perguntas/fichas.jsonl` | As fichas de pergunta e resposta, uma por linha, para uso por script. |
| `atualizar-acervo.sh` | **Uso normal.** Baixa os vídeos novos desde a última transcrição. |
| `baixar-shorts.sh` | Baixa os shorts novos (ou todos). Roda em rodadas, resistente a bloqueio. |

---

## Atualizar

```bash
./atualizar-acervo.sh
./baixar-shorts.sh 20261001
```

O primeiro descobre sozinho a data do último vídeo e busca daí em diante. O segundo recebe a data inicial dos shorts; sem data, varre o canal inteiro.

Depois, no Claude Code, dentro desta pasta:

> lê as transcrições novas e atualiza o skill

---

## Notas

- Legenda: faixa **`en-orig`**, o ASR original em inglês do YouTube. Nunca faixa traduzida.
- **O YouTube bloqueia IPs de nuvem** com "Sign in to confirm you're not a bot". Os scripts usam `player_client=web_embedded`, que contorna o bloqueio para legendas. Avisos de `HTTP Error 429` no carregamento da página **não** significam falha: o que vale é se o `.json3` foi gravado.
- Os scripts usam `date -j` (macOS). Num Linux, troque por `date -d`.
- Nunca combine `--break-on-reject` com `--match-filter` de duração: ele para de varrer no primeiro vídeo rejeitado.
- A transcrição vem de legenda automática: boa para extrair conhecimento, **imprecisa em números falados, nomes próprios e cifras**. Confira no vídeo antes de citar publicamente.
- Conteúdo de terceiro, para uso pessoal, de estudo e referência. Ao usar como matéria-prima, cite a fonte.
