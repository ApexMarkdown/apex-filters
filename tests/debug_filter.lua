#!/usr/bin/env lua
local s = io.read("a")
io.stderr:write(s)
io.stderr:write("\n---END---\n")
os.exit(1)
