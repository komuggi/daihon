local config = require("daihon.config")
local parse = require("daihon.parse")
local complete = require("daihon.complete")

local cfg = config.merge(config.defaults, {})

local function words(items)
  return vim.tbl_map(function(it)
    return it.word
  end, items)
end

test("候補：▼ のあとは、使ったラベル（多い順）→ 位置×距離", function()
  local above = parse.parse({ "// ▼右・近", "// ▲右・近", "// ▼ささやき", "// ▼右・近" }, cfg)
  local c = complete.at("// ▼", above, cfg)
  eq(true, c.auto)
  eq(#"// ▼", c.col)
  eq({ "右・近", "ささやき", "前・遠", "前・中" }, vim.list_slice(words(c.items), 1, 4))
  eq(2 + 5 * 4 - 1, #c.items) -- 右・近 は位置×距離にもあるので1つにまとまる
end)

test("候補：▼ のあと打った分で絞る。打ちかけなら自動では出さない", function()
  local c = complete.at("// ▼右", {}, cfg)
  eq(false, c.auto)
  eq(#"// ▼", c.col)
  local want = { "右前・遠", "右前・中", "右前・近", "右前・密" }
  vim.list_extend(want, { "右・遠", "右・中", "右・近", "右・密" })
  eq(want, words(complete.filter(c.items, "右")))
end)

test("候補：▲ のあとは、まだ閉じていない ▼（新しい順）", function()
  local above = parse.parse({ "## Track 01", "// ▼前・中", "// ▼ささやき", "// ▲前・中" }, cfg)
  local c = complete.at("(▲", above, cfg)
  eq({ "ささやき" }, words(c.items))
  eq("3行目", c.items[1].menu)
end)

test("候補：位置と距離は設定で変えられる。▼▲ の行でなければ出さない", function()
  local c2 =
    config.merge(cfg, { ranges = { position = { "正面" }, distance = { "密着" }, words = { "無声音" } } })
  eq({ "正面・密着", "無声音" }, words(complete.at("// ▼", {}, c2).items))
  eq(nil, complete.at("おかえり", {}, cfg))
  eq(nil, complete.at("// SE", {}, cfg))
end)
