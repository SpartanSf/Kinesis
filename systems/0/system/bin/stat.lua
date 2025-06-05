local arg1dir = kFs.join(kFs.currentdir(), args[1])
if kFs.exists(arg1dir) then
    term.write("Size:          "..kFs.getSize(arg1dir).."\n")
    local cdate, mdate, adate = kFs.times(arg1dir)
    term.write("Creation date: "..getDate(cdate).."\n")
    term.write("Modified date: "..getDate(mdate).."\n")
    term.write("Access date:   "..getDate(adate).."\n")
else term.write("Invalid path") end
