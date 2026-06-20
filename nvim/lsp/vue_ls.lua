-- =============================================================================
-- lsp/vue_ls.lua  –  Vue LSP サーバー設定 (Volar v2)
-- VSCode: vue.volar 拡張
-- =============================================================================
-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

return {
	cmd = { "vue-language-server", "--stdio" },
	filetypes = { "vue" },
	root_markers = { "vue.config.js", "vue.config.ts", "nuxt.config.ts", "package.json", ".git" },
	capabilities = capabilities,
	on_init = function(client)
		client.handlers["tsserver/request"] = function(_, result, context)
			local ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })
			local vtsls_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
			local clients = {}

			vim.list_extend(clients, ts_clients)
			vim.list_extend(clients, vtsls_clients)

			if #clients == 0 then
				vim.notify(
					"Could not find `vtsls` or `ts_ls` lsp client, `vue_ls` would not work without it.",
					vim.log.levels.ERROR
				)
				return
			end
			local ts_client = clients[1]

			local param = unpack(result)
			local id, command, payload = unpack(param)
			ts_client:exec_cmd({
				title = "vue_request_forward", -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
				command = "typescript.tsserverRequest",
				arguments = {
					command,
					payload,
				},
			}, { bufnr = context.bufnr }, function(_, r)
				local response = r and r.body
				-- TODO: handle error or response nil here, e.g. logging
				-- NOTE: Do NOT return if there's an error or no response, just return nil back to the vue_ls to prevent memory leak
				local response_data = { { id, response } }

				---@diagnostic disable-next-line: param-type-mismatch
				client:notify("tsserver/response", response_data)
			end)
		end
	end,
}
