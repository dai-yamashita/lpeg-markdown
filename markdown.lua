#!/usr/bin/env lua
-- vim: tabstop=2 shiftwidth=2 expandtab

lpeg = require "lpeg"

local R = lpeg.R
local P = lpeg.P
local V = lpeg.V
local S = lpeg.S
local C = lpeg.C
local Cc = lpeg.Cc
local Ct = lpeg.Ct
local Cmt = lpeg.Cmt

local function markdown_grammar()
  local trim = function(str)
    res = str:gsub("^%s*(.-)%s*$", "%1")
    return res
  end

  local header_grammar = function(n)
    prefix = string.rep("#",n)
    return P(prefix)*(((1-V"NL")^0)/function(str)
          return string.format("<h%d>%s</h%d>", n, trim(str), n)
        end) * (V"NL" + -1)
  end

  local li = function(str)
    return string.format("<li>%s</li>", trim(str))
  end

  local concat_link = function(s, i, name, href)
    return true, string.format("<a href=\"%s\">%s</a>", href, name)
  end

  local concat_matches = function(s, i, vals)
    return i, table.concat(vals)
  end

  return P{
    "markdown";
    NL = (P"\r"^-1 * P"\n")+-1,
    WS = S"\t ",
    OPTWS = V"WS"^0,
    linkname = (1-P"]")^0,
    linkref = (1-P")")^0,
    link = Cmt(P"[" * C(V"linkname") * P"]" * P"(" * C(V"linkref") * P")", concat_link),
    line = Cmt(Ct((V"link" + C((1-V"NL")))^1), concat_matches),
    lines = ((V"line")*V"NL")^1,
    paragraph = Cc"<p>" * V"lines" * V"NL" * Cc"</p>",
    ulli = P"*" * V"OPTWS" * ((1-V"NL")^0/li) * V"NL",
    ul = Cc"<ul>" * V"ulli"^1 * Cc"</ul>",
    olli = R"09"^1 * P"." * V"OPTWS"* ((1-V"NL")^0/li) * V"NL",
    ol = Cc"<ol>" * V"olli"^1 * Cc"</ol>",
    content = V"ul" + V"ol" + V"paragraph",
    h1 = header_grammar(1),
    h2 = header_grammar(2),
    h3 = header_grammar(3),
    h4 = header_grammar(4),
    h5 = header_grammar(5),
    h6 = header_grammar(6),
    header = V"h6" + V"h5" + V"h4" + V"h3" + V"h2" + V"h1",
    markdown = (S"\r\n\t "^1 + V"header" + V"content")^0
  }
end

local markdown = {}
local parser = Ct(markdown_grammar())
markdown.markdown = function(str)
  local res = parser:match(str)
  if type(res) == "table" then
    return table.concat(res)
  end
end

return markdown

