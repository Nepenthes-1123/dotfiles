-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end
-- =============================================================================
-- lsp/clangd.lua  –  C/C++ LSP サーバー設定
-- VSCode: ms-vscode.cpptools, jeff-hykin.better-cpp-syntax
-- =============================================================================
-- VSCode: "C_Cpp.clang_format_style": "{BasedOnStyle: Google, IndentWidth: 4}"

return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=Google", -- VSCode: BasedOnStyle: Google
	},
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
	root_markers = { ".clangd", "compile_commands.json", "CMakeLists.txt", ".git" },
	init_options = {
		usePlaceholders = true,
		completeUnimported = true,
		clangdFileStatus = true,
	},
	capabilities = capabilities,
}
