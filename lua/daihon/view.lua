-- 画面への表示：色分け・見出しの文字数・▼▲ などの警告
local count = require("daihon.count")

local M = {}

M.ns = vim.api.nvim_create_namespace("daihon")
M.ns_diag = vim.api.nvim_create_namespace("daihon_diag")

-- 色は既存の色の名前につなぐ。自分で変えるときは :hi DaihonShiji guifg=... のように上書きする
local LINKS = {
  DaihonHeading = "Title",
  DaihonShiji = "Comment",
  DaihonIchi = "Type",
  DaihonBamen = "Special",
  DaihonMemo = "NonText",
  DaihonRange = "Keyword",
  DaihonSpeaker = "Identifier",
  DaihonBlock = "Constant",
  DaihonCount = "Comment",
  -- 範囲の縦の線（ラベルごとに色を変える）
  DaihonGuide1 = "DiagnosticInfo",
  DaihonGuide2 = "DiagnosticHint",
  DaihonGuide3 = "DiagnosticOk",
  DaihonGuide4 = "DiagnosticWarn",
  DaihonGuide5 = "Function",
  DaihonGuide6 = "Constant",
}

--- ラベルから線の色を決める（同じラベルはいつも同じ色）
local function guide_hl(key)
  local n = 0
  for i = 1, #key do
    n = n + key:byte(i)
  end
  return "DaihonGuide" .. (n % 6 + 1)
end

function M.define_highlights()
  for name, link in pairs(LINKS) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

local function mark(buf, row, s, e, group, priority)
  vim.api.nvim_buf_set_extmark(buf, M.ns, row, s, {
    end_row = row,
    end_col = e,
    hl_group = group,
    priority = priority or 100,
  })
end

--- 1行ずつ色と文字数を付け直す
function M.render(buf, records, summary, issues)
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  for _, r in ipairs(records) do
    local row, len = r.lnum - 1, #r.text
    if r.kind == "見出し" then
      mark(buf, row, 0, len, "DaihonHeading")
      local n = summary.headings[r.lnum]
      if n then
        vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
          virt_text = { { "  " .. count.format(n) .. "文字", "DaihonCount" } },
          virt_text_pos = "eol",
        })
      end
    elseif r.kind == "塊開始" or r.kind == "塊終了" then
      mark(buf, row, 0, len, "DaihonBlock")
      if summary.new_blocks and summary.new_blocks[r.lnum] then
        vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
          virt_text = { { "  新しい塊（保存すると作ります）", "DaihonCount" } },
          virt_text_pos = "eol",
        })
      end
    elseif r.kind == "範囲" then
      mark(buf, row, 0, len, "DaihonRange")
    elseif r.type then
      mark(buf, row, 0, len, r.type.hl or "DaihonShiji")
      if r.range then
        mark(buf, row, r.range.col, len, "DaihonRange", 110)
      end
    elseif r.speaker_col then
      mark(buf, row, r.speaker_col[1], r.speaker_col[2], "DaihonSpeaker")
    end
    for _, ref in ipairs(r.refs or {}) do
      mark(buf, row, ref.s - 1, ref.e, "DaihonBlock", 120)
    end
    local depth = summary.depths and summary.depths[r.lnum]
    if depth then
      local chunks = {}
      for _, o in ipairs(depth) do
        chunks[#chunks + 1] = { "│ ", guide_hl(o.key) }
      end
      vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, { virt_text = chunks, virt_text_pos = "inline", priority = 50 })
    end
  end

  local diags = {}
  for _, i in ipairs(issues) do
    diags[#diags + 1] = {
      lnum = i.lnum - 1,
      col = i.col or 0,
      end_col = i.end_col,
      severity = i.hint and vim.diagnostic.severity.HINT
        or i.warn and vim.diagnostic.severity.WARN
        or vim.diagnostic.severity.ERROR,
      message = i.msg,
      source = "daihon",
    }
  end
  vim.diagnostic.set(M.ns_diag, buf, diags)
end

return M
