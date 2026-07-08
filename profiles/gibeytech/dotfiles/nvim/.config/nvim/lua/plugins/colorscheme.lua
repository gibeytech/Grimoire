return {
  -- Dracula theme
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("dracula").setup({
        colors = {
          bg = "#221a1a",
          fg = "#f8f8f2",
          selection = "#2d2020",
          comment = "#6272a4",
          red = "#ff6e6e",
          orange = "#ffb86c",
          yellow = "#ffffa5",
          green = "#69ff94",
          purple = "#e0789a",
          cyan = "#a4ffff",
          pink = "#e0789a",
          bright_red = "#ff6e6e",
          bright_green = "#69ff94",
          bright_yellow = "#ffffa5",
          bright_blue = "#bd93f9",
          bright_magenta = "#e0789a",
          bright_cyan = "#a4ffff",
          bright_white = "#ffffff",
          menu = "#2d2020",
          visual = "#3d2f2f",
          gutter_fg = "#4b3b3b",
          nontext = "#3d2f2f",
          white = "#f8f8f2",
          black = "#221a1a",
        },
        show_end_of_buffer = false,
        transparent_bg = true,
        italic_comment = true,
      })
      vim.cmd("colorscheme dracula")
    end,
  },

  -- Désactive le colorscheme par défaut de LazyVim
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
