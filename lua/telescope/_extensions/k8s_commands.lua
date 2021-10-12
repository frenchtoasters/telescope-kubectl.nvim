local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
	error("This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end


local utils = require('telescope.utils')
local defaulter = utils.make_default_callable
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values

local Job = require'plenary.job'
local M = {}
local kubeconfig = ""
local k8s_cmd = ""

M.base_directory=""
M.k8s_preview = defaulter(function(opts)
	return previewers.new_termopen_previewer {
		get_command = opts.get_command or function(entry)
			local preview = opts.get_preview_window()
			local choice = entry[1]
			local choice_ns = string.match(choice, "^[^ ]+")
			local choice_obj = string.match(choice, "[ ]+[^ ]+"):gsub("%s", "")
			if vim.tbl_isempty(entry) then
				return {"echo", ""}
			end
			return {
				'kubectl',
				string.format("logs"),
				string.format("--kubeconfig=%s", kubeconfig),
				string.format("%s", choice_obj),
				string.format("-n=%s", choice_ns),
				string.format("--tail=30")
			}
		end
	}
end, {})

function M.k8s_edits(opts)
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

function M.k8s_logs(opts)
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
		args = {'get', 'pods', '--all-namespaces', '--no-headers=true'},
		env = {
			PATH = vim.env.PATH,
			['KUBECONFIG'] = kubeconfig,
			HOME = vim.env.HOME
		},
		on_stdout = function(_, data)
			table.insert(results, data)
		end,
	}):sync()

	local picker=pickers.new(opts, {
		prompt_title = kubeconfig,
		finder = finders.new_table({
			results = results,
			opts = opts,
		}),
		previewer = M.k8s_preview.new(opts),
		sorter = conf.generic_sorter(opts),
	})


	local line_count = vim.o.lines - vim.o.cmdheight
	if vim.o.laststatus ~= 0 then
		line_count = line_count - 1
	end
	popup_opts = picker:get_window_options(vim.o.columns, line_count)
	picker:find()
end

function M.k8sexec(opts)
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
		args = {'get', 'pods', '--show-kind','--all-namespaces', '--no-headers=true'},
		env = {
			PATH = vim.env.PATH,
			['KUBECONFIG'] = kubeconfig
		},
		on_stdout = function(_, data)
			table.insert(results, data)
		end,
	}):sync()

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
				vim.cmd('! tmux neww kubectl exec --kubeconfig=' .. kubeconfig .. ' --tty --stdin ' .. choice_obj .. ' -n ' .. choice_ns .. ' -- ' .. exec_cmd)
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
	end,
	exports = {
		k8s_logs = M.k8s_logs,
		k8s_edits = M.k8s_edits,
		k8s_exec = M.k8s_exec
	},
}

