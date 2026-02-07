#!/usr/bin/env lua
-- code-includes: include code from a separate file (Apex stdin/stdout JSON filter)
-- Based on https://github.com/averms/pandoc-filters (code-includes.lua). © 2020 Aman Verma. MIT.
-- This version reads Pandoc JSON from stdin and writes JSON to stdout for Apex.

local ok, json = pcall(require, "dkjson")
if not ok then
  io.stderr:write("code-includes: missing Lua dependency 'dkjson'. Install: luarocks install dkjson\n")
  os.exit(1)
end

local function read_all()
  local chunks = {}
  while true do
    local chunk = io.read(4096)
    if not chunk then break end
    table.insert(chunks, chunk)
  end
  return table.concat(chunks)
end

-- Read file and return contents (strip trailing newline like original)
local function read_populated_lines(fpth)
  local f, err = io.open(fpth, "r")
  if not f then
    io.stderr:write("code-includes: could not open ", fpth, ": ", tostring(err), "\n")
    return nil
  end
  local contents = f:read("a")
  f:close()
  if contents then
    contents = contents:gsub("\n$", "")
  end
  return contents
end

-- Pandoc/Apex CodeBlock c = [Attr, content]; Attr = [id, classes, keyvals].
local function has_inc_attr(attr)
  if type(attr) ~= "table" or type(attr[3]) ~= "table" then return false end
  for _, kv in ipairs(attr[3]) do
    if type(kv) == "table" and kv[1] == "inc" then return true end
  end
  return false
end

local function remove_inc_attr(attr)
  if type(attr) ~= "table" or type(attr[3]) ~= "table" then return end
  local new_kv = {}
  for _, kv in ipairs(attr[3]) do
    if type(kv) ~= "table" or kv[1] ~= "inc" then table.insert(new_kv, kv) end
  end
  attr[3] = new_kv
end

local function walk_blocks(blocks)
  local out = {}
  for _, blk in ipairs(blocks or {}) do
    if blk.t == "CodeBlock" and type(blk.c) == "table" and #blk.c >= 2 then
      local attr, content = blk.c[1], blk.c[2]
      if has_inc_attr(attr) and type(content) == "string" then
        local filename = content:match("^%s*(.-)%s*$")
        if filename == "" then
          io.stderr:write("code-includes: no filename inside the code block.\n")
          table.insert(out, blk)
        else
          local new_content = read_populated_lines(filename)
          if new_content then
            remove_inc_attr(attr)
            table.insert(out, { t = "CodeBlock", c = { attr, new_content } })
          else
            table.insert(out, blk)
          end
        end
      else
        table.insert(out, blk)
      end
    else
      table.insert(out, blk)
    end
  end
  return out
end

local input = read_all()
local doc, pos, err = json.decode(input, 1, nil)
if not doc then
  io.stderr:write("code-includes: JSON decode error: ", tostring(err), "\n")
  if pos and pos > 0 then
    local snippet = input:sub(math.max(1, pos - 40), math.min(#input, pos + 40))
    io.stderr:write("code-includes: around position ", pos, ": ", snippet:gsub("\n", "\\n"), "\n")
  end
  os.exit(1)
end

if doc.blocks then
  doc.blocks = walk_blocks(doc.blocks)
end

io.write(json.encode(doc, { indent = false }))
io.output():flush()
