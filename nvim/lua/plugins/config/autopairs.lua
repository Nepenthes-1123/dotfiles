local setup = require("plugins.config.utils").setup

setup("nvim-autopairs", function(m)
	m.setup({
		check_ts = true,
		map_cr = false,
		disable_filetype = {
			"TelescopePrompt",
			"snacks_picker_input",
			"spectre_panel",
			"octo",
		},
	})
end)
