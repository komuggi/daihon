-- テストの実行：nvim --headless -l tests/run.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, "S").source:sub(2))))
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local failed, passed = 0, 0

_G.test = function(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    io.stdout:write("✗ " .. name .. "\n  " .. tostring(err) .. "\n")
  end
end

_G.eq = function(want, got, msg)
  if not vim.deep_equal(want, got) then
    error(
      ("%sほしい: %s\n  実際: %s"):format(msg and (msg .. "\n  ") or "", vim.inspect(want), vim.inspect(got)),
      2
    )
  end
end

for _, f in ipairs(vim.fn.glob(root .. "/tests/test_*.lua", false, true)) do
  dofile(f)
end

io.stdout:write(("%d 件 OK / %d 件 NG\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
