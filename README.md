# Telescope-kubectl.nvim

Edit k8s objects, view pod logs, etc...

## Requirements

* tmux
* neovim v0.5.1

## Install

```
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'frenchtoasters/telescope-kubectl.nvim'
```

## Setup

```
require('telescope').load_extension('k8s_commands')
```

### Configuraiton

```
require'telescope'.setup {
	...
	extensions = {
		k8s_commands = {
			kubeconfig = "/kube/configs", -- defaults to $HOME/.kube/config
			k8s_cmd = "k" -- defaults to kubectl
		}
	},
}
```

### Default key mappings

```
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
```

# Example keymap

```
Map("n","<leader>k", ":lua require('telescope').load_extension('k8s_commands').k8s(require('telescope.themes').get_ivy())<CR>", {noremap=true})
```
