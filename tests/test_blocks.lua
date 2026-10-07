local config = require("daihon.config")
local parse = require("daihon.parse")
local blocks = require("daihon.blocks")

local cfg = config.merge(config.defaults, {})

test("塊：名前に使えるか", function()
  eq(true, blocks.valid_name("あいさつ1"))
  eq(false, blocks.valid_name("../外"))
  eq(false, blocks.valid_name(".隠し"))
  eq(false, blocks.valid_name(""))
end)

test("塊：その行を囲んでいる {{ }} を探す", function()
  local r = parse.parse({ "前", "{{A", "中", "}}", "後", "{{B", "閉じていない" }, cfg)
  eq(nil, blocks.block_at(r, 1))
  eq({ name = "A", first = 2, last = 4 }, blocks.block_at(r, 3))
  eq({ name = "A", first = 2, last = 4 }, blocks.block_at(r, 4))
  eq(nil, blocks.block_at(r, 5))
  eq({ name = "B", first = 6 }, blocks.block_at(r, 7))
end)

test("塊：カーソルの {名前}", function()
  local r = parse.parse({ "{A} と {B}" }, cfg)[1]
  eq("A", blocks.ref_at(r, 0).name)
  eq("B", blocks.ref_at(r, #"{A} と {").name)
  eq("A", blocks.ref_at(r, 4).name) -- 塊の外なら最初の塊
end)
