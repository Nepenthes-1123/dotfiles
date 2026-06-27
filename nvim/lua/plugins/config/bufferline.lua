local setup = require("plugins.config.utils").setup

setup("bufferline", function(m)
	m.setup({
		options = {
			mode = "buffers", -- タブではなくバッファを表示
			style_preset = m.style_preset.default,
			numbers = "none",
			close_command = "bdelete! %d",
			right_mouse_command = "bdelete! %d",
			left_mouse_command = "buffer %d",
			indicator = {
				style = "underline",
			},
			buffer_close_icon = "󰅖",
			modified_icon = "●",
			close_icon = "",
			left_trunc_marker = "",
			right_trunc_marker = "",
			max_name_length = 18,
			tab_size = 18,
			diagnostics = "nvim_lsp",
			diagnostics_update_in_insert = false,
			offsets = {
				{
					filetype = "NvimTree",
					text = "File Explorer",
					text_align = "left",
					separator = true,
				},
				{
					filetype = "snacks_layout_box",
					text = "File Explorer",
					text_align = "left",
					separator = true,
				},
			},
			color_icons = true,
			show_buffer_icons = true,
			show_buffer_close_icons = true,
			show_close_icon = false,
			show_tab_indicators = true,
			persist_buffer_sort = true,
			separator_style = "slope",
			enforce_regular_tabs = false,
			always_show_bufferline = true,
		},
	})
end)
