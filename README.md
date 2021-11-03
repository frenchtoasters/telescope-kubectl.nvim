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

```
nnoremap <leader>k <cmd>lua require('telescope').load_extension('k8s_commands').k8s_edits()<cr>
nnoremap <leader>kl <cmd>lua require('telescope').load_extension('k8s_commands').k8s_logs()<cr>
nnoremap <leader>ke <cmd>lua require('telescope').load_extension('k8s_commands').k8s_exec()<cr>
```
