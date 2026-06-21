local setup = require("plugins.config.utils").setup

setup("nvim-autopairs", function(m)
	m.setup({

		event = "InsertEnter",
		config = true,
	})
end)
