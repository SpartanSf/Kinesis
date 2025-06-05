local shiftMap = {
    ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$",
    ["5"] = "%", ["6"] = "^", ["7"] = "&", ["8"] = "*",
    ["9"] = "(", ["0"] = ")", ["-"] = "_", ["="] = "+",
    ["["] = "{", ["]"] = "}", ["\\"] = "|",[";"] = ":",
    ["'"] = "\"", [","] = "<", ["."] = ">", ["/"] = "?",
    ["`"] = "~",
}
  
function term.input(replace, newline)
  local chars = {}
  local lShiftDown = false
  local rShiftDown = false
  local capsDown = false
  local raiseKey = false
  local shiftsDown = false
  local running = true
  local len = 0
  local function callbackIn(char)
    if not (char and type(char) == "number" and char == bit.band(char, 0xFFFF)) then return end
    if char == 0xFF00 then
      lShiftDown = true
      return
    elseif char == 0xFF01 then
      rShiftDown = true
      return
    elseif char == 0xFF34 then
      capsDown = not capsDown
      return
    elseif char == 0xFF32 then
      running = false
      if newline then ioControl.put(0, string.byte("\n")) end
      return
    end

    if char == 0xFF33 and len > 0 then 
      len = len - 1
      ioControl.put(0, char) 
      table.remove(chars)
      return
    elseif char ~= 0xFF33 then
      len = len + 1
    else
      return
    end

    shiftsDown = lShiftDown or rShiftDown
    raiseKey = shiftsDown ~= capsDown

    if char >= 97 and char <= 122 then
        if raiseKey then
            table.insert(chars, string.char(char - 32))
            if replace then ioControl.put(0, string.byte(replace)) else ioControl.put(0, char - 32) end
            return
        else
            table.insert(chars, string.char(char))
            if replace then ioControl.put(0, string.byte(replace)) else ioControl.put(0, char) end
            return
        end
    end

    if pcall(string.char, char) then
      if shiftsDown and shiftMap[string.char(char)] then
          table.insert(chars, shiftMap[string.char(char)])
          if replace then ioControl.put(0, string.byte(replace)) else ioControl.put(0, string.byte(shiftMap[string.char(char)])) end
          return
      end

      table.insert(chars, string.char(char))
      if replace then ioControl.put(0, string.byte(replace)) else ioControl.put(0, char) end
      return
    end
  end

  local function callbackOut(char)
    if char == 0xFF00 then
      lShiftDown = false
      return
    elseif char == 0xFF01 then
      rShiftDown = false
      return
    end
  end

  ioControl.listen(2, callbackIn)
  ioControl.listen(3, callbackOut)
  while running do coroutine.yield() end
  ioControl.unListen(2, callbackIn)
  ioControl.unListen(3, callbackOut)
  return table.concat(chars)
end

function term.setCursor(x, y)
  ioControl.put(0, 0xFF80)
  ioControl.put(0, x)
  ioControl.put(0, 0xFF81)
  ioControl.put(0, y)
end

function term.getSize()
  local width, height
  local function callbackIn(data)
    if not width then width = data else height = data end
  end

  ioControl.listen(1, callbackIn)

  ioControl.put(0, 0xFF82)
  ioControl.put(0, 0xFF83)
  while not height do coroutine.yield() end

  ioControl.unListen(1, callbackIn)
  return width, height
end

--[[
function print(...)
  local args = {...}
  for i, arg in ipairs(args) do
    term.write(arg)
    if #args - i > 0 then
      term.write(" ")
    end
  end
  term.write("\n")
end
]]
