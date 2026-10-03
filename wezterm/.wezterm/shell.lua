-- zsh を起動する場所の決定と、zsh 経由でコマンドを実行するための共通処理
--
-- Windows では zsh・herdr などの CLI ツールを WSL の中で使う。
-- WezTerm 自体は Windows 側で動くため、次のように扱いを分ける。
--   - タブ・ウィンドウ: WSL ドメインを既定にし、WSL の中で zsh を起動する
--   - WezTerm から直接実行するコマンド (run_child_process): wsl.exe 経由で WSL の中の zsh に渡す
-- WSL が見つからない場合は WezTerm の既定のシェルを使う。zsh の設定は Windows 側にリンクしないため、
-- Windows 側の zsh (MSYS2 など) を起動しても dotfiles の設定が効かない。
local wezterm = require("wezterm")

local M = {}

M.is_windows = wezterm.target_triple:find("windows") ~= nil

-- 使う WSL ドメインを探す。環境変数 WEZTERM_WSL_DISTRO でディストリビューション名を指定できる
local function find_wsl_domain(domains)
	local want = os.getenv("WEZTERM_WSL_DISTRO")
	for _, domain in ipairs(domains) do
		local distro = domain.distribution or ""
		-- Docker Desktop が作るディストリビューションはシェル用ではないため除外する
		if (want and distro == want) or (not want and not distro:find("^docker%-desktop")) then
			return domain
		end
	end
	return nil
end

-- WSL ドメイン (Windows で WSL がある場合のみ)
M.wsl_domains = {}
M.wsl_domain = nil
if M.is_windows then
	local ok, domains = pcall(wezterm.default_wsl_domains)
	if ok and domains then
		M.wsl_domains = domains
		M.wsl_domain = find_wsl_domain(domains)
		if M.wsl_domain then
			-- 既定では Windows 側のカレントディレクトリ (/mnt/c/...) で開くため、WSL のホームで開く
			M.wsl_domain.default_cwd = "~"
		end
	end
end

-- config に zsh の起動先を設定する
function M.setup(config)
	if M.wsl_domain then
		config.wsl_domains = M.wsl_domains
		config.default_domain = M.wsl_domain.name
	end
end

-- 既定のドメインでタブ・ウィンドウを開くときの引数 (spawn_tab / spawn_window 用)
-- WSL ドメインでも mac / Linux でも、そのドメインの zsh で実行される
function M.spawn_args(command)
	return { "zsh", "-l", "-c", command }
end

-- タブを開くときのカレントディレクトリ。WSL ドメインでは default_cwd (~) に任せる
function M.spawn_cwd()
	if M.wsl_domain then
		return nil
	end
	return wezterm.home_dir
end

-- ペインのカレントディレクトリのパス部分 (file://host/path の path)。分からなければ nil
local function pane_cwd_path(pane)
	local ok, cwd = pcall(function()
		return pane:get_current_working_dir()
	end)
	if not ok or not cwd then
		return nil
	end
	-- 新しい WezTerm は Url オブジェクト、古い WezTerm は文字列を返す
	if type(cwd) ~= "string" then
		return cwd.path
	end
	return cwd:match("^file://[^/]*(/.*)$")
end

-- 新しいタブ・ペイン・ウィンドウを開くときの SpawnCommand。domain の既定は今のペインと同じドメイン。
-- WSL のペインでは、WezTerm が URL (file://<WSL のホスト名>/path) から Windows のパスに変換すると
-- 正しい場所にならないため、パスを取り出して明示的に渡す。
-- シェルが OSC 7 (zsh/.zsh.d/wezterm.zsh) で知らせていればその場所、知らせていない (herdr の中など) と
-- WezTerm には wsl.exe のカレントディレクトリ (C:/Users/...) しか見えないため、WSL のホームで開く
function M.spawn_command(pane, domain)
	local command = { domain = domain or "CurrentPaneDomain" }
	if M.wsl_domain and pane:get_domain_name() == M.wsl_domain.name then
		local path = pane_cwd_path(pane)
		-- /C:/Users/... のような Windows のパスは WSL の中のパスではない
		if path and path:sub(1, 1) == "/" and not path:match("^/%a:") then
			command.cwd = path:gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)
		else
			command.cwd = "~"
		end
	end
	return command
end

-- 新しいタブ・ウィンドウ・分割ペインを開くアクション (spawn_command を使う)
function M.spawn_tab_action()
	return wezterm.action_callback(function(window, pane)
		window:perform_action(wezterm.action.SpawnCommandInNewTab(M.spawn_command(pane)), pane)
	end)
end

function M.spawn_window_action()
	return wezterm.action_callback(function(window, pane)
		-- 新しいウィンドウは従来の SpawnWindow と同じく既定のドメインで開く
		window:perform_action(wezterm.action.SpawnCommandInNewWindow(M.spawn_command(pane, "DefaultDomain")), pane)
	end)
end

-- direction は "Vertical" (下に開く) か "Horizontal" (右に開く)
function M.split_action(direction)
	return wezterm.action_callback(function(window, pane)
		window:perform_action(wezterm.action["Split" .. direction](M.spawn_command(pane)), pane)
	end)
end

-- WezTerm から直接コマンドを実行するときの引数 (run_child_process 用)
-- run_child_process は Windows 側で実行されるため、WSL がある場合は wsl.exe 経由にする
function M.run_args(command)
	if M.wsl_domain then
		return { "wsl.exe", "-d", M.wsl_domain.distribution, "-e", "zsh", "-l", "-c", command }
	end
	return { "zsh", "-l", "-c", command }
end

return M
