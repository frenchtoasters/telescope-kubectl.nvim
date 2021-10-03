# Telescope-kubectl.nvim

Edit k8s objects, view pod logs, etc...

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
