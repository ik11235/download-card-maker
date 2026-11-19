#!/usr/bin/env bash
# 電子版ダウンロードカードの印刷用 PDF（A4）を作る。
set -euo pipefail

usage() {
  cat <<'EOF'
使い方: make-cards.sh --title 書籍名 --url URL --deadline 期限 [オプション]

必須:
  --title TEXT      書籍名
  --url URL         ダウンロード URL（QR コードと文字の両方で印字）
  --deadline TEXT   ダウンロード期限（自由な文字列。例: 2027年3月31日まで）

任意:
  --circle TEXT     サークル名
  --note TEXT       注意書き
  --cols N          横の枚数（既定: 3）
  --rows N          縦の枚数（既定: 5）
  --font NAME       日本語フォント名（既定: ヒラギノ → Noto Sans CJK JP → Noto Sans JP → 游ゴシックの順に探す）
  -o, --output PATH 出力先（既定: cards.pdf）
  -h, --help        このヘルプを表示
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output="cards.pdf"
inputs=()
font=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --font)
      [[ $# -ge 2 ]] || { echo "$1 に値がありません" >&2; exit 2; }
      font="$2"
      shift 2
      ;;
    --title|--url|--deadline|--circle|--note|--cols|--rows)
      [[ $# -ge 2 ]] || { echo "$1 に値がありません" >&2; exit 2; }
      inputs+=(--input "${1#--}=$2")
      shift 2
      ;;
    -o|--output)
      [[ $# -ge 2 ]] || { echo "$1 に値がありません" >&2; exit 2; }
      output="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "不明な引数: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v typst >/dev/null 2>&1; then
  echo "typst が見つかりません。mise を使う場合は mise install、使わない場合は brew install typst などで入れてください" >&2
  exit 1
fi

if [[ -z "$font" ]]; then
  available="$(typst fonts)"
  for candidate in "Hiragino Sans" "Noto Sans CJK JP" "Noto Sans JP" "Yu Gothic"; do
    if grep -qxF "$candidate" <<<"$available"; then
      font="$candidate"
      break
    fi
  done
  if [[ -z "$font" ]]; then
    echo "日本語フォントが見つかりません。Noto Sans CJK JP を入れるか、--font で指定してください（候補は typst fonts で確認できます）" >&2
    exit 1
  fi
fi
inputs+=(--input "font=$font")

typst compile "${inputs[@]}" "$script_dir/cards.typ" "$output"
echo "作成しました: $output"
