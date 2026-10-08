-- 候補を決める。ファイルや画面には触らない
local parse = require("daihon.parse")

local M = {}

local function push(items, seen, word, menu)
  if word ~= "" and not seen[word] then
    seen[word] = true
    items[#items + 1] = { word = word, menu = menu }
  end
end

--- ▼ のあとに出すラベル：この台本で使ったもの（多い順）→ 位置×距離 → そのほかの言葉
function M.open_labels(records, cfg)
  local r = cfg.ranges or {}
  local used, order = {}, {}
  for _, rec in ipairs(records) do
    local label = rec.range and rec.range.op == "open" and rec.range.label
    if label and label ~= "" then
      if not used[label] then
        order[#order + 1] = label
      end
      used[label] = (used[label] or 0) + 1
    end
  end
  table.sort(order, function(a, b)
    return used[a] > used[b]
  end)

  local items, seen = {}, {}
  for _, label in ipairs(order) do
    push(items, seen, label, "使った")
  end
  local sep = r.sep or "・"
  for _, p in ipairs(r.position or {}) do
    for _, d in ipairs(r.distance or {}) do
      push(items, seen, p .. sep .. d, "位置")
    end
  end
  for _, w in ipairs(r.words or {}) do
    push(items, seen, w, "言葉")
  end
  return items
end

--- ▲ のあとに出すラベル：まだ閉じていない ▼（新しく開いた順）
local function close_labels(records, cfg)
  local items = {}
  local open = parse.open_ranges_at(records, cfg, #records + 1)
  for k = #open, 1, -1 do
    items[#items + 1] = { word = open[k].label, menu = ("%d行目"):format(open[k].lnum) }
  end
  return items
end

--- カーソルより前の文字（before）から、候補を出す場所と候補を決める
--- records はその行より上の台本（使った言葉と、閉じていない ▼ を拾う）
--- 返す表：{ col = 置き換えを始める位置（0 始まり）, items, auto = 打った直後に出すか }。出さないなら nil
function M.at(before, records, cfg)
  local rec = parse.parse({ before }, cfg)[1]
  if not (rec and rec.range) then
    return nil
  end
  local label = rec.range.label
  local items = rec.range.op == "open" and M.open_labels(records, cfg) or close_labels(records, cfg)
  return { col = #before - #label, items = items, auto = label == "" }
end

--- 打った分（base）で絞る
function M.filter(items, base)
  if base == "" then
    return items
  end
  return vim.tbl_filter(function(it)
    return vim.startswith(it.word, base)
  end, items)
end

return M
