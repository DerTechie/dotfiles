local function variant()
  return vim.o.background == "dark" and "rose-pine" or "rose-pine-dawn"
end

return {
  { "rose-pine/neovim", name = "rose-pine" },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = variant() },
  },
}
