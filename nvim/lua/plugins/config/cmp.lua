local setup = require("plugins.config.utils").setup

-- ── nvim-cmp ──────────────────────────────────────────────────────────────────
setup("cmp", function(cmp)
	local luasnip_ok, luasnip = pcall(require, "luasnip")
	if luasnip_ok then
		pcall(require, "luasnip.loaders.from_vscode")
	end

	cmp.setup({
		enable = function()
			local disabled_filetypes = {
				"Pager",
			}
			local ft = vim.bo.filetype
			for _, disabled_ft in ipairs(disabled_filetypes) do
				if ft == disabled_ft then
					return false
				end
			end
			return true
		end,
		snippet = {
			expand = function(args)
				if luasnip_ok then
					luasnip.lsp_expand(args.body)
				end
			end,
		},
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},
		mapping = cmp.mapping.preset.insert({
			["<C-b>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(),
			["<C-e>"] = cmp.mapping.abort(),
			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip_ok and luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				else
					fallback()
				end
			end, { "i", "s" }),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip_ok and luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
		}),
		sources = cmp.config.sources({
			{ name = "nvim_lsp", priority = 1000 },
			{ name = "luasnip", priority = 750 },
			{ name = "buffer", priority = 500, option = { keyword_length = 3 } },
			{ name = "path", priority = 250 },
		}),
		formatting = {
			format = function(entry, item)
				local labels = { nvim_lsp = "[LSP]", luasnip = "[Snip]", buffer = "[Buf]", path = "[Path]" }
				item.menu = labels[entry.source.name] or ""
				return item
			end,
		},
		completion = { completeopt = "menu,menuone,noinsert" },
		experimental = { ghost_text = true },
	})

	cmp.setup.cmdline({ "/", "?" }, {
		mapping = cmp.mapping.preset.cmdline(),
		sources = { { name = "buffer" } },
	})

	cmp.setup.cmdline(":", {
		mapping = cmp.mapping.preset.cmdline(),
		sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
	})

	-- nvim-autopairs との連携
	local ap_ok, ap_cmp = pcall(require, "nvim-autopairs.completion.cmp")
	if ap_ok then
		cmp.event:on("confirm_done", ap_cmp.on_confirm_done())
	end
end)
