-- =============================================================================
-- lsp/bashls.lua  –  Bash LSP (bash-language-server)
-- =============================================================================
-- 整形と lint をこのサーバ 1 つで賄う。bash-language-server は shfmt と
-- shellcheck を外部バイナリとして呼ぶだけなので、本体は
-- plugins/config/lsp.lua の mason-tool-installer で別途インストールする。
--
-- shfmt のインデント幅を指定する設定項目は存在せず、Neovim の shiftwidth に
-- 従う。プロジェクトで固定したい場合は .editorconfig を置くこと
-- (ignoreEditorconfig = false なので .editorconfig が優先される)。
-- 設定キーは bash-language-server の server/src/config.ts に準拠。
-- =============================================================================

-- Windows の mason は bin/ にバッチの .cmd shim を置くが、Node 製である
-- bash-language-server はこれを spawn できず ENOENT になり、shellcheck も shfmt も
-- 黙って無効化される。そのため Windows では実体の .exe を直接指す。
-- 他プラットフォームでは shim が実行可能なので PATH 解決に任せる。
local function mason_exe(pkg, glob, fallback)
	if vim.fn.has("win32") == 0 then
		return fallback
	end
	local hits = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/" .. pkg .. "/" .. glob, false, true)
	return hits[1] or fallback
end

return {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "bash" },
	root_markers = { ".git" },
	settings = {
		bashIde = {
			shellcheckPath = mason_exe("shellcheck", "shellcheck*.exe", "shellcheck"),
			shfmt = {
				-- mason の shfmt はファイル名にバージョンを含む (shfmt_v3.14.1_windows_amd64.exe)
				path = mason_exe("shfmt", "shfmt*.exe", "shfmt"),
				caseIndent = true, -- case のパターンをインデントする (-ci)
				binaryNextLine = true, -- && / || を行頭に置く (-bn)
				ignoreEditorconfig = false,
			},
		},
	},
}
