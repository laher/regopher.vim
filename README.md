# regopher.vim

Experimental vim plugin for [regopher](https://github.com/laher/regopher).

It's extremely early so there's not much here and everything will change in future versions.

## Thanks

regopher.vim has been almost entirely lifted from [vim-go](https://github.com/fatih/vim-go).

I made it this way because vim-go is so good, but also because I hope one day that regopher might be adopted as part of vim-go. It might not happen or even need to happen, but it's a nice thought, and it should encourage adoption to play nicely.

I renamed all global functions and variables, to avoid interfering with vim-go itself.

## Installation

regopher.vim requires at least vim 8 or Neovim 0.3.1. (It might work on vim 7.4, but I figure vim 8 is established enough that I should focus on that)

regopher.vim follows the standard runtime path structure, and can be installed with plugin managers

I use `vim-plug`. Installation is as follows:

```
    Plug 'laher/regopher.vim', { 'do': ':ReGoUpdate' }
```

For other plugin managers, you should execute `:ReGoUpdate` after installation. This will `go get` the latest version of `regopher`.

## Usage

 * From any buffer, `:ReGoUpdate`
 * With cursor over a function definition, `:ReGoParamsToStruct`
 * With cursor over a function definition, `:ReGoResultsToStruct`

Please see [doc/regopher.txt](doc/regopher.txt) for instructions, or `:help regopher`

## License

This plugin is distributed with its own [MIT license](LICENSE) in keeping with `regopher`, plus a copy of [vim-go's BSD 3-clause license](LICENSE-vim-go) 
