// 電子版ダウンロードカードを A4 に面付けする。
// 値は `typst compile --input key=value` で渡す（make-cards.sh が組み立てる）。
#import "@preview/tiaoma:0.4.0": qrcode

#let inputs = sys.inputs

#let required(key) = {
  let value = inputs.at(key, default: "")
  if value == "" { panic(key + " を指定してください（make-cards.sh では --" + key + "）") }
  value
}

#let positive-int(key, default) = {
  let raw = inputs.at(key, default: str(default))
  if raw.match(regex("^[0-9]+$")) == none or int(raw) < 1 {
    panic(key + " は 1 以上の整数にしてください: " + raw)
  }
  int(raw)
}

#let title = required("title")
#let url = required("url")
#let deadline = required("deadline")
#let circle = inputs.at("circle", default: "")
#let note = inputs.at("note", default: "")
#let cols = positive-int("cols", 3)
#let rows = positive-int("rows", 5)

// make-cards.sh は環境にある候補を1つ選んで渡す。直接 compile したときだけ候補リストを使う
#let fonts = if inputs.at("font", default: "") != "" {
  (inputs.font,)
} else {
  ("Hiragino Sans", "Noto Sans CJK JP", "Noto Sans JP", "Yu Gothic")
}
// DejaVu Sans Mono は Typst CLI に同梱されている
#let mono = ("DejaVu Sans Mono",)

#let margin = 10mm
#let paper-w = 210mm
#let paper-h = 297mm
#let card-w = (paper-w - 2 * margin) / cols
#let card-h = (paper-h - 2 * margin) / rows
#let pad = 3mm
#let qr-size = calc.max(15mm, calc.min(card-w * 0.36, card-h * 0.45))
// 読み取りに必要な白い余白（クワイエットゾーン）。URL の QR は一辺25モジュール以上なので、0.16 倍で4モジュール分以上になる
#let quiet = qr-size * 0.16
// 左側はカードの内側余白 pad も白いので、足りない分だけ足す
#let quiet-left = calc.max(0mm, quiet - pad)

#set page(paper: "a4", margin: margin)
#set text(font: fonts, lang: "ja", size: 7pt, cjk-latin-spacing: none)
#set par(leading: 0.4em, spacing: 0.5em)

// 長い URL をどこでも折り返せるよう、文字の間にゼロ幅スペースを挟む
#let breakable(s) = s.clusters().join("\u{200B}")

#let card = block(width: card-w, height: card-h, inset: pad, clip: false, {
  text(size: 10pt, weight: "bold", title)
  linebreak()
  text(size: 6.5pt, "電子版ダウンロードカード")
  grid(
    columns: (qr-size + quiet + quiet-left, 1fr),
    column-gutter: 1mm,
    box(inset: (left: quiet-left, rest: quiet), qrcode(url, width: qr-size)),
    {
      v(quiet)
      if circle != "" { [#circle] + parbreak() }
      [ダウンロード期限] + linebreak() + text(weight: "bold", deadline)
    },
  )
  text(font: mono, size: 6pt, breakable(url))
  if note != "" {
    parbreak()
    text(size: 5.5pt, note)
  }
})

#let cut-line = (paint: luma(150), thickness: 0.3pt, dash: "dashed")

#grid(
  columns: (card-w,) * cols,
  rows: (card-h,) * rows,
  stroke: cut-line,
  ..range(cols * rows).map(_ => card),
)
