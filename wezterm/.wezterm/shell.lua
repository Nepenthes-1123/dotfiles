-- zsh を起動する場所の決定と、zsh 経由でコマンドを実行するための共通処理
--
-- Windows では zsh・herdr などの CLI ツールを WSL の中で使う。
-- WezTerm 自体は Windows 側で動くため、次のように扱いを分ける。
--   - タブ・ウィンドウ: WSL ドメインを既定にし、WSL の中で zsh を起動する
--   - WezTerm から直接実行するコマンド (run_child_process): wsl.exe 経由で WSL の中の zsh に渡す
-- WSL が見つからない場合は、従来どおり Windows 側の zsh (MSYS2 など) を探して使う。
local wezterm = require("wezterm")

local M = {}

M.is_windows = wezterm.target_triple:find("windows") ~= nil

local function file_exists(filepath)
	local f = io.open(filepath, "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

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

-- Windows 側の zsh (MSYS2 / Git for Windows) を探す。WSL が無い場合のフォールバック
local function find_windows_zsh()
	-- 1. ユーザーが明示的に指定した場合
	local custom_zsh = os.getenv("ZSH_CUSTOM_PATH")
	if custom_zsh and file_exists(custom_zsh) then
		return custom_zsh
	end

	-- 2. MSYS2_HOME環境変数から推測
	local msys2_home = os.getenv("MSYS2_HOME")
	if msys2_home then
		local msys2_zsh = msys2_home .. "\\usr\\bin\\zsh.exe"
		if file_exists(msys2_zsh) then
			return msys2_zsh
		end
	end

	-- 3. よくあるデフォルト候補を試す
	local candidates = {
		"C:\\msys64\\usr\\bin\\zsh.exe",
		"C:\\tools\\msys64\\usr\\bin\\zsh.exe",
		"C:\\Program Files\\Git\\usr\\bin\\zsh.exe",
		"C:\\cygwin64\\bin\\zsh.exe",
	}
	for _, candidate in ipairs(candidates) do
		if file_exists(candidate) then
			return candidate
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

-- Windows 側の zsh (WSL が無い場合のみ)
M.windows_zsh = nil
if M.is_windows and not M.wsl_domain then
	M.windows_zsh = find_windows_zsh()
end

-- config に zsh の起動先を設定する
function M.setup(config)
	if M.wsl_domain then
		config.wsl_domains = M.wsl_domains
		config.default_domain = M.wsl_domain.name
	elseif M.windows_zsh then
		config.default_prog = { M.windows_zsh, "-l" }
		config.set_environment_variables = config.set_environment_variables or {}
		config.set_environment_variables.MSYSTEM = "MINGW64"
		config.set_environment_variables.MSYS2_PATH_TYPE = "inherit"
		config.set_environment_variables.MSYS = "winsymlinks:nativestrict"
		-- herdr が Windows 側の zsh を引き継ぐようにする
		config.set_environment_variables.SHELL = M.windows_zsh
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

-- 今のペインと同じドメインで新しいタブ・ペイン・ウィンドウを開くときの SpawnCommand。
-- WSL のペインでは、シェルが OSC 7 (zsh/.zsh.d/wezterm.zsh) でカレントディレクトリを知らせていれば
-- それを引き継ぐ。知らせていない (herdr の中など) と WezTerm には wsl.exe の
-- カレントディレクトリ (C:/Users/...) しか見えず、/mnt/c/... で開いてしまうため、WSL のホームで開く
function M.spawn_command(pane)
	local command = { domain = "CurrentPaneDomain" }
	if M.wsl_domain and pane:get_domain_name() == M.wsl_domain.name then
		local path = pane_cwd_path(pane)
		-- /C:/Users/... のような Windows のパスは WSL の中のパスではない
		if not path or path:match("^/%a:") then
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
		window:perform_action(wezterm.action.SpawnCommandInNewWindow(M.spawn_command(pane)), pane)
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
	elseif M.windows_zsh then
		return { M.windows_zsh, "-l", "-c", command }
	end
	return { "zsh", "-l", "-c", command }
end

return M
