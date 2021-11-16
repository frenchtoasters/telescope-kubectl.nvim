local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
	error("This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values

local Job = require'plenary.job'
local M = {}
local kubeconfig = ""
local k8s_cmd = ""
local exec_cmd = ""

M.base_directory=""

function M.k8s(opts)
	local k8s_commands = {
		kubectl = {
			'kubectl',
		},
	}

	if not vim.fn.executable(k8s_cmd) then
		error("You don't have "..k8s_cmd.."! Install it first.")
		return
		end

	if not k8s_commands[k8s_cmd] then
		error(k8s_cmd.." is not supported!")
		return
	end

	local sourced_file = require('plenary.debug_utils').sourced_filepath()
	M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h:h:h")
	opts = opts or {}
	local popup_opts={}
	opts.get_preview_window=function ()
		return popup_opts.preview
	end

	local results = {}
	Job:new({
		command = 'kubectl',
		args = {'get', 'all', '--show-kind','--all-namespaces', '--no-headers=true'},
		env = {
			PATH = vim.env.PATH,
			['KUBECONFIG'] = kubeconfig,
			HOME = vim.env.HOME
		},
		on_stdout = function(_, data)
			table.insert(results, data)
		end,
	}):sync()

	Job:new({
		command = 'kubectl',
		args = {'get', 'secrets', '--show-kind','--all-namespaces', '--no-headers=true'},
		env = {
			PATH = vim.env.PATH,
			['KUBECONFIG'] = kubeconfig,
			HOME = vim.env.HOME
		},
		on_stdout = function(_, data)
			table.insert(results, data)
		end,
	}):sync()

	Job:new({
		command = 'kubectl',
		args = {'get', 'configmaps', '--show-kind','--all-namespaces', '--no-headers=true'},
		env = {
			PATH = vim.env.PATH,
			['KUBECONFIG'] = kubeconfig,
			HOME = vim.env.HOME
		},
		on_stdout = function(_, data)
			table.insert(results, data)
		end,
	}):sync()

	opts = opts or {}
	local picker=pickers.new(opts, {
		prompt_title = kubeconfig,
		finder = finders.new_table({
			results = results,
			opts = opts,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(pbfr, map)
			map("i", "<CR>", function()
				local choice = action_state.get_selected_entry(pbfr)
				local choice_ns = string.match(choice.value, "^[^ ]+")
				local choice_obj = string.match(choice.value, "[ ]+[^ ]+"):gsub("%s", "")
				vim.cmd('! tmux neww kubectl edit --kubeconfig=' .. kubeconfig .. ' ' .. choice_obj .. ' -n ' .. choice_ns)
			end)
			map("i", "<S-e>", function ()
				local choice = action_state.get_selected_entry(pbfr)
				local choice_ns = string.match(choice.value, "^[^ ]+")
				local choice_obj = string.match(choice.value, "[ ]+[^ ]+"):gsub("%s", "")
				vim.cmd('! tmux neww kubectl exec --kubeconfig=' .. kubeconfig .. ' --tty --stdin ' .. choice_obj .. ' -n ' .. choice_ns .. ' -- ' .. exec_cmd)
				end)
			map("i", "<S-l>", function()
				local choice = action_state.get_selected_entry(pbfr)
				local ns = string.match(choice.value, "^[^ ]+")
				local obj = string.match(choice.value, "[ ]+[^ ]+"):gsub("%s", "")
				local contents = {}
				Job:new({
					command = 'kubectl',
					args = {'logs','-n', ns, obj},
					env = {
						PATH = vim.env.PATH,
						['KUBECONFIG'] = kubeconfig,
						HOME = vim.env.HOME
					},
					on_stdout = function(_, data)
						table.insert(contents, data)
					end
				}):sync()
				local logger = pickers.new(opts, {
					prompt_title = "Logs for pod: " .. obj,
					finder = finders.new_table({
						results = contents,
						opts = opts,
					}),
					sorter = conf.generic_sorter(opts),
				})
				local line_count = vim.o.lines - vim.o.cmdheight
				if vim.o.laststatus ~= 0 then
					line_count = line_count - 1
				end
				popup_opts = logger:get_window_options(vim.o.columns, line_count)
				logger:find()
			end)
			return true
		end,
	})

	local line_count = vim.o.lines - vim.o.cmdheight
	if vim.o.laststatus ~= 0 then
		line_count = line_count - 1
	end
	popup_opts = picker:get_window_options(vim.o.columns, line_count)
	picker:find()
end

return require('telescope').register_extension {
	setup = function(ext_config)
		kubeconfig = ext_config.kubeconfig or os.getenv("HOME") .. "/.kube/config"
		k8s_cmd = ext_config.k8s_cmd or "kubectl"
		exec_cmd = ext_config.k8s_exec_cmd or "/bin/sh"
	end,
	exports = {
		k8s = M.k8s,
	},
}

