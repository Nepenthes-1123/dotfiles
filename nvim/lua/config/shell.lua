local os_name = vim.loop.os_uname().sysname
local opt = vim.opt

if os_name == "Windows_NT" then
  opt.shell = "C:/msys64/usr/bin/zsh.exe"

  opt.shellcmdflag = "-c"

  opt.shellquote = ""
  opt.shellxquote = ""

  opt.shellslash = true
else
  opt.shell = "/bin/zsh"
  opt.shellcmdflag = "-c"
end
