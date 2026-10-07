local config = require("daihon.config")
local parse = require("daihon.parse")
local count = require("daihon.count")
local export = require("daihon.export")

local function build(lines, togaki, over)
  local cfg = config.merge(config.defaults, over)
  local parts = { ["あいさつ"] = { "// ▼右・近", "おかえり" }, ["短い"] = { "またね" } }
  local get = function(n)
    return parts[n]
  end
  local records = parse.parse(lines, cfg)
  local summary = count.summary(records, count.context(cfg, get))
  return export.build(records, cfg, { togaki = togaki, get_part = get, summary = summary, title = "t" })
end

local function has(html, s)
  if not html:find(s, 1, true) then
    error("ない: " .. s, 2)
  end
end

local function hasnt(html, s)
  if html:find(s, 1, true) then
    error("あってはいけない: " .. s, 2)
  end
end

test("書き出し：ト書きあり／なし。メモと塊の目印は出さない", function()
  local lines =
    { "## Track 01", "(玄関)", "// SE : 足音", "ただいま", "¥ メモ", "{{短い", "またね", "}}" }
  local a = build(lines, true)
  has(a, '<p class="t-場面">(玄関)</p>')
  has(a, '<p class="t-指示">// SE : 足音</p>')
  has(a, '<p class="serifu">ただいま</p>')
  hasnt(a, "メモ")
  hasnt(a, "{{")
  local b = build(lines, false)
  hasnt(b, "玄関")
  hasnt(b, "足音")
  has(b, '<p class="serifu">ただいま</p>')
end)

test("書き出し：見出しに文字数。{@文字数一覧}", function()
  local html =
    build({ "{@文字数一覧}", "# 本編", "## Track 01", "ただいま", "## Track 02", "{短い}" }, true)
  has(html, 'Track <span class="tcy">01</span> : <span class="tcy">4</span>文字')
  has(html, '<p class="count-total">合計 : <span class="tcy">7</span>文字</p>')
  has(html, '<h2 class="new-page">')
end)

test("書き出し：塊は中身に置き換える。1行なら行ごと、途中なら文の中に", function()
  local a = build({ "{あいさつ}", "また{短い}" }, true)
  has(a, '<p class="t-指示">// ◀右・近</p>')
  has(a, '<p class="serifu">おかえり</p>')
  has(a, '<p class="serifu">またまたね</p>')
  local b = build({ "{あいさつ}" }, false)
  hasnt(b, "右・近")
  local _, missing = build({ "{ない}" }, true)
  eq({ "ない" }, missing)
end)

test("書き出し：HTML の記号は逃がす。横書きにもできる", function()
  local html = build({ "<b>&" }, true, { export = { pdf = { vertical = false } } })
  has(html, "&lt;b&gt;&amp;")
  hasnt(html, "vertical-rl")
  has(build({ "あ" }, true), "writing-mode: vertical-rl")
end)

test("書き出し：空行は続けても1つ", function()
  local html = build({ "あ", "", "", "// 指示", "", "い" }, false)
  local _, n = html:gsub('class="gap"', "")
  eq(1, n)
end)

test("書き出し：見出しの前と最後には空きを入れない", function()
  local html = build({ "あ", "", "## Track 01", "", "い", "" }, true)
  local _, n = html:gsub('class="gap"', "")
  eq(0, n)
end)

test(
  "書き出し：縦書きでは ▼▲ を ◀▶ にする（始まり ◀・終わり ▶）。横書きと設定で外したときはそのまま",
  function()
    local lines = { "// ▼前・中", "おかえり", "// ▲前・中", "// ▼と書いた文の中の▼" }
    local v = build(lines, true)
    has(v, "// ◀前・中")
    has(v, "// ▶前・中")
    has(v, "// ◀と書いた文の中の▼")
    local h = build(lines, true, { export = { pdf = { vertical = false } } })
    has(h, "// ▼前・中")
    local off = build(lines, true, { export = { pdf = { vertical_marks = false } } })
    has(off, "// ▼前・中")
  end
)

test("書き出し：セリフは字下げ、ト書きは行の頭", function()
  local html = build({ "あ" }, true)
  has(html, ".serifu { padding-inline-start: 3em; }")
  hasnt(html, ".t-指示 { padding-inline-start")
end)
