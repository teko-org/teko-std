#!/bin/sh
# check-language.sh -- this repository is English-only, and this is the check that
# proves it. It is teko-lang's own `scripts/check-docs.sh` § 3, copied here with
# nothing else of that script: documentation, code comments, commit messages and
# workflow comments are written in English, and Portuguese belongs in chat with
# the owner or in the private history repository.
#
# Two rules. A Portuguese diacritic is decisive on its own -- no English word in
# this tree carries one. The ASCII list catches Portuguese written without
# accents; every word on it is matched whole, and none of them is an English word
# (`state` is not `esta`).
#
# The accents are spelled as an ALTERNATION of whole characters, never as a
# bracket class: outside a UTF-8 locale a bracket class matches single BYTES, and
# the continuation bytes of `a` are also the continuation bytes of an em dash, a
# checkmark and a curly quote.
set -eu

cd "$(dirname "$0")/.."

tmp="${TMPDIR:-/tmp}/check-language.$$"
mkdir -p "$tmp"
cleanup() { rm -rf "$tmp"; return 0; }
trap cleanup EXIT INT TERM

if git rev-parse --git-dir >/dev/null 2>&1; then
    git ls-files > "$tmp/all_tracked"
else
    find . -type f | sed 's#^\./##' | sort > "$tmp/all_tracked"
fi
grep -E '\.(md|tk|mc|sh|yml|yaml|toml|lock)$|^(MC_VERSION|LICENSE.*)$|^\.git(ignore|attributes)$' \
    "$tmp/all_tracked" | grep -v -E '^scripts/check-language\.sh$' > "$tmp/english_files"

pt_accents='á|à|â|ã|é|ê|í|ó|ô|õ|ú|ü|ç|Á|À|Â|Ã|É|Ê|Í|Ó|Ô|Õ|Ú|Ü|Ç'
pt_words='nao|entao|sao|voce|esta|estao|tambem|atraves|divida|dono|dona|arquivo|arquivos|ficheiro|entrega|entregas|escada|primitivas|superficie|nivel|codigo|funcao|porque|quando|isso|dele|dela'

: > "$tmp/pt"
while read -r f; do
    [ -f "$f" ] || continue
    grep -n -E "($pt_accents)" "$f" 2>/dev/null | sed "s#^#$f:#" >> "$tmp/pt"
    grep -n -w -E "($pt_words)" "$f" 2>/dev/null | sed "s#^#$f:#" >> "$tmp/pt"
done < "$tmp/english_files"

nfiles=$(grep -c . "$tmp/english_files")
if [ -s "$tmp/pt" ]; then
    echo "FAIL language: Portuguese in an English-only repository"
    cut -c1-140 "$tmp/pt"
    exit 1
fi
echo "ok language: $nfiles tracked sources carry no Portuguese"
