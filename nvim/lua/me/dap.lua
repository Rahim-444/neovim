local api = vim.api
local HOME = os.getenv("HOME")
local M = {}
local log_level = "INFO"

function M.visualize(opts)
	opts = opts or {}
	local varname = opts.varname or vim.fn.expand("<cexpr>")
	local child_names = (opts.child_names or vim.split(vim.fn.input({ prompt = "Child Properties: " }), " "))
	local property_names = (opts.property_names or vim.split(vim.fn.input({ prompt = "Properties: " }), " "))
	local session = require("dap").session() or {}
	local scopes = (session.current_frame or {}).scopes
	local variable = nil
	for _, scope in pairs(scopes or {}) do
		variable = scope.variables[varname]
		if variable then
			break
		end
	end
	if not variable then
		return
	end
	variable = variable --[[@as dap.Variable]]
	local f = assert(io.open("/tmp/dap.gv", "w"), "Must be able to open file")
	coroutine.wrap(function()
		f:write("digraph G {\n")
		f:write("  graph [\n")
		f:write("     layout=dot\n")
		f:write("     labelloc=t\n")
		f:write("  ]\n")

		---@param v dap.Variable
		---@return dap.Variable[]
		local function get_children(v)
			if v.variablesReference == 0 then
				return {}
			end
			local params = {
				variablesReference = v.variablesReference,
			}
			local err, result = session:request("variables", params)
			assert(not err, err and require("dap.utils").fmt_error(err))
			return result.variables
		end

		---@param v dap.Variable
		---@return dap.Variable
		local function resolve_lazy(v)
			if (v.presentationHint or {}).lazy then
				local resolved = get_children(v)[1]
				resolved.name = v.name
				return resolved
			end
			return v
		end

		---@param parent dap.Variable
		local function add_children(parent, parent_name)
			local children = get_children(parent)
			parent_name = parent_name or parent.name
			local property_values = {}
			for _, var in pairs(children) do
				if vim.tbl_contains(property_names, var.name) then
					if var.variablesReference > 0 then
						for _, child_var in pairs(get_children(var)) do
							table.insert(property_values, var.name .. ": " .. resolve_lazy(child_var).value)
						end
					else
						table.insert(property_values, var.value)
					end
				end
			end
			for _, var in pairs(children) do
				local name = parent_name .. "." .. var.name
				var = resolve_lazy(var)
				if vim.tbl_contains(child_names, var.name) or tonumber(var.name) then
					if var.value ~= "" then
						f:write(
							string.format(
								'  "%s" [label=<<b>%s</b><br/>%s>]\n',
								name,
								name,
								table.concat(property_values, "<br/>")
							)
						)
					else
						f:write(string.format('  "%s"\n', name))
					end
					f:write(string.format('  "%s" -> "%s"\n', parent_name, name))
					add_children(var, name)
				end
			end
		end

		variable = resolve_lazy(variable)
		f:write(string.format('  "%s"\n', variable.name))
		add_children(variable)
		f:write("}")
		f:close()
		vim.fn.system("dot -Txlib /tmp/dap.gv")
	end)()
end

local function add_tagfunc(widget)
	local orig_new_buf = widget.new_buf
	widget.new_buf = function(...)
		local bufnr = orig_new_buf(...)
		api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.require'me.lsp.ext'.symbol_tagfunc")
		return bufnr
	end
end

local function reload()
	local m = require("me")
	require("dap.repl").close()
	m.reload("dap", true)
	m.reload("me.dap").setup()
	vim.cmd("set ft=" .. vim.bo.filetype)
	require("dap").set_log_level(log_level)
end

function M.setup()
	local dap = require("dap")

	api.nvim_create_autocmd("WinEnter", {
		callback = function()
			local win = api.nvim_get_current_win()
			local value = (
				(vim.bo.buftype == "" and package.loaded.dap and require("dap").session()) and "yes:1" or "auto"
			)
			vim.wo[win].signcolumn = value
		end,
	})
	api.nvim_create_autocmd("User", {
		group = api.nvim_create_augroup("dap", { clear = true }),
		pattern = "DapProgressUpdate",
		command = "redrawstatus",
	})

	local orig_set_log_level = dap.set_log_level
	---@diagnostic disable-next-line: duplicate-set-field
	function dap.set_log_level(level)
		orig_set_log_level(level)
		log_level = level
	end

	local widgets = require("dap.ui.widgets")
	add_tagfunc(widgets.expression)
	add_tagfunc(widgets.scopes)
	local keymap = vim.keymap
	local function set(mode, lhs, rhs)
		keymap.set(mode, lhs, rhs, { silent = true })
	end
	vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "🟢", texthl = "", linehl = "", numhl = "" })

	set({ "n", "t" }, "<F3>", dap.terminate)
	set("n", "<leader>b", dap.toggle_breakpoint)
	set("n", "<leader>B", function()
		dap.toggle_breakpoint(vim.fn.input({ prompt = "Breakpoint Condition: " }), nil, nil, true)
	end)
	set("n", "<leader>lp", function()
		dap.toggle_breakpoint(nil, nil, vim.fn.input({ prompt = "Log point message: " }), true)
	end)
	set("n", "<leader>dr", function()
		dap.repl.toggle({ height = 15 })
	end)
	set("n", "<leader>dR", dap.restart_frame)
	set("n", "<leader>dl", function()
		if vim.bo.modified and vim.bo.buftype == "" then
			vim.cmd.w()
		end
		dap.run_last()
	end)
	set("n", "<leader>dj", dap.down)
	set("n", "<leader>dk", dap.up)
	set("n", "<leader>dc", dap.run_to_cursor)
	set("n", "<leader>dg", dap.goto_)
	set("n", "<leader>dS", function()
		widgets.centered_float(widgets.frames)
	end)
	set("n", "<leader>dt", function()
		widgets.centered_float(widgets.threads)
	end)
	set("n", "<leader>ds", function()
		widgets.centered_float(widgets.scopes)
	end)
	set({ "n", "v" }, "<leader>dh", widgets.hover)
	set({ "n", "v" }, "<leader>dp", widgets.preview)

	dap.listeners.after.event_initialized["me.dap"] = function()
		set("n", "<up>", dap.restart_frame)
		set("n", "<down>", dap.step_over)
		set("n", "<left>", dap.step_out)
		set("n", "<right>", dap.step_into)
		for _, win in ipairs(api.nvim_list_wins()) do
			if vim.bo[api.nvim_win_get_buf(win)].buftype == "" then
				vim.wo[win].signcolumn = "yes:1"
			end
		end
	end
	local after_session = function()
		if not next(dap.sessions()) then
			pcall(keymap.del, "n", "<up>")
			pcall(keymap.del, "n", "<down>")
			pcall(keymap.del, "n", "<left>")
			pcall(keymap.del, "n", "<right>")
			for _, win in ipairs(api.nvim_list_wins()) do
				vim.wo[win].signcolumn = "auto"
			end
		end
	end
	dap.listeners.after.event_terminated["me.dap"] = after_session
	dap.listeners.after.disconnect["me.dap"] = after_session

	local sidebar = widgets.sidebar(widgets.scopes)
	local create_command = api.nvim_create_user_command
	create_command("DapSidebar", sidebar.toggle, { nargs = 0 })
	create_command("DapReload", reload, { nargs = 0 })
	create_command("DapBreakpoints", function()
		dap.list_breakpoints(true)
	end, { nargs = 0 })
	create_command("DapVisualize", function()
		M.visualize()
	end, { nargs = 0 })
	create_command("DapNew", function()
		dap.continue({ new = true })
	end, { nargs = 0 })

	local sessions_bar = widgets.sidebar(widgets.sessions, {}, "5 sp")
	create_command("DapSessions", sessions_bar.toggle, { nargs = 0 })

	dap.defaults.fallback.switchbuf = "usetab,uselast"
	dap.defaults.fallback.terminal_win_cmd = "tabnew"
	dap.defaults.python.terminal_win_cmd = "belowright new"
	-- dap.defaults.fallback.external_terminal = {
	-- 	command = "/mnt/c/Users/maison/AppData/Local/Microsoft/WindowsApps/wt.exe",
	-- 	-- args = { "--hold", "-e" },
	-- }
	dap.adapters.cppdbg = {
		id = "cppdbg",
		type = "executable",
		command = HOME .. "/apps/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
		attach = {
			pidProperty = "pid",
			pidSelect = "ask",
		},
		env = {
			LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
		},
	}
	dap.adapters.codelldb = {
		type = "server",
		port = "${port}",
		executable = {
			command = HOME .. "/apps/codelldb/extension/adapter/codelldb",
			args = { "--port", "${port}" },
		},
	}
	dap.adapters.c = {
		type = "executable",
		attach = {
			pidProperty = "pid",
			pidSelect = "ask",
		},
		command = "lldb-vscode-11", -- my binary was called 'lldb-vscode-11'
		env = {
			LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
		},
		name = "lldb",
	}

	local function program()
		return vim.fn.input({
			prompt = "Path to executable: ",
			default = vim.fn.getcwd() .. "/",
			completion = "file",
		})
	end

	-- Dont forget, attach needs permission:
	--  echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
	local configs = {
		{
			name = "cppdbg: Launch",
			type = "cppdbg",
			request = "launch",
			program = program,
			cwd = "${workspaceFolder}",
			externalConsole = false,
			args = {},
		},
		-- {
		-- 	name = "cppdbg: Attach",
		-- 	type = "cppdbg",
		-- 	request = "Attach",
		-- 	processId = function()
		-- 		return tonumber(vim.fn.input({ prompt = "Pid: " }))
		-- 	end,
		-- 	program = program,
		-- 	cwd = "${workspaceFolder}",
		-- 	args = {},
		-- },
		-- {
		-- 	name = "codelldb: Launch",
		-- 	type = "codelldb",
		-- 	request = "launch",
		-- 	program = program,
		-- 	cwd = "${workspaceFolder}",
		-- 	args = {},
		-- },
		-- {
		-- 	name = "codelldb: Launch external",
		-- 	type = "codelldb",
		-- 	request = "launch",
		-- 	program = program,
		-- 	cwd = "${workspaceFolder}",
		-- 	args = {},
		-- 	terminal = "external",
		-- },
		-- {
		-- 	name = "codelldb: Attach (select process)",
		-- 	type = "codelldb",
		-- 	request = "attach",
		-- 	pid = require("dap.utils").pick_process,
		-- 	args = {},
		-- },
		-- {
		-- 	name = "codelldb: Attach (input pid)",
		-- 	type = "codelldb",
		-- 	request = "attach",
		-- 	pid = function()
		-- 		return tonumber(vim.fn.input({ prompt = "pid: " }))
		-- 	end,
		-- 	args = {},
		-- },
		-- {
		-- 	name = "lldb: Launch (integratedTerminal)",
		-- 	type = "lldb",
		-- 	request = "launch",
		-- 	program = program,
		-- 	cwd = "${workspaceFolder}",
		-- 	stopOnEntry = false,
		-- 	args = {},
		-- 	runInTerminal = true,
		-- },
		-- {
		-- 	name = "lldb: Launch (console)",
		-- 	type = "lldb",
		-- 	request = "launch",
		-- 	program = program,
		-- 	cwd = "${workspaceFolder}",
		-- 	stopOnEntry = false,
		-- 	args = {},
		-- 	runInTerminal = false,
		-- },
		-- {
		-- 	name = "lldb",
		-- 	type = "c",
		-- 	request = "launch",
		-- 	program = program,
		-- 	cwd = "${workspaceFolder}",
		-- 	externalTerminal = false,
		-- 	stopOnEntry = false,
		-- 	args = {},
		-- },
		setmetatable({
			name = "Neovim",
			type = "cppdbg",
			request = "launch",
			program = program,
			cwd = "${workspaceFolder}",
			--program = os.getenv("HOME") .. "/nvim/bin/nvim",
			--cwd = os.getenv("HOME") .. "/nvim/",
			externalTerminal = false,
			stopOnEntry = false,
			-- args = {
			-- 	"--clean",
			-- 	"--cmd",
			-- 	"call getchar()",
			-- },
		}, {
			__index = function(_, key)
				if key == "runInTerminal" then
					return false
				end
			end,
		}),
	}
	dap.configurations.c = configs
	dap.configurations.rust = configs
	dap.configurations.cpp = configs
	dap.configurations.zig = {
		{
			name = "Zig run",
			type = "cppdbg",
			request = "launch",
			program = "/usr/bin/zig",
			args = { "run", "${file}" },
			cwd = "${workspaceFolder}",
		},
		{
			name = "Program",
			type = "cppdbg",
			request = "launch",
			program = program,
			args = {},
			cwd = "${workspaceFolder}",
		},
		{
			name = "Test (No breakpoints 😢)",
			type = "cppdbg",
			request = "launch",
			program = "/usr/bin/zig",
			args = { "test", "-fno-strip", "${file}" },
			cwd = "${workspaceFolder}",
			setupCommands = {
				{
					text = "set follow-fork-mode child",
				},
				{
					text = "set detach-on-fork off",
				},
			},
		},
	}
	require("dap.ext.vscode").type_to_filetypes = {
		lldb = { "rust", "c", "cpp" },
	}
	pcall(require("dap.ext.vscode").load_launchjs)
end

return M
