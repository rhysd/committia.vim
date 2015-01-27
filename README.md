More Pleasant Editing on Commit Message
=======================================

When you type `git commit`, Vim starts and opens a commit buffer.  This plugin improves
the commit buffer.

committia.vim splits the buffer into 3 windows; edit window, status window and diff window.
You no longer need to repeat scroll and back to the former position in order to see a long
commit diff.  If the width of Vim window is too narrow (160 characters by default), committia.vim
falls back to single column mode, which has 2 windows; edit window and diff window.

For wide window:

![double column mode](https://dl.dropboxusercontent.com/u/2753138/screenshot_committia.jpg)

For narrow window:

![single column mode](https://dl.dropboxusercontent.com/u/2753138/screenshot_committia_narrow.jpg)

## Hooks

You can hook on opening the windows.

Available hooks are:

- `edit_open`
- `diff_open`
- `status_open`

A vimrc example is below.

```vim
" You can get the information about the windows with first argument as a dictionary.
"
"   KEY              VALUE                      AVAILABILITY
"-----------------------------------------------------------------------------------
"   vcs            : vcs type (e.g. 'git')   -> all hooks
"   edit_winnr     : winnr of edit window    -> ditto
"   edit_bufnr     : bufnr of edit window    -> ditto
"   diff_winnr     : winnr of diff window    -> ditto
"   diff_bufnr     : bufnr of diff window    -> ditto
"   status_winnr   : winnr of status window  -> all hooks except for 'diff_open' hook
"   status_bufnr   : bufnr of status window  -> ditto

let g:committia_hooks = {}
function! g:committia_hooks.edit_open(info)
    " Additional settings
    setlocal spell

    " If no commit message, start with insert mode
    if a:info.vcs ==# 'git' && getline(1) ==# ''
        startinsert
    end

    " Scroll the diff window from insert mode
    " Map <C-n> and <C-p>
    imap <buffer><C-n> <Plug>(committia-scroll-diff-down-half)
    imap <buffer><C-p> <Plug>(committia-scroll-diff-up-half)

endfunction
```

## Mappings

Scroll mappings for insert mode are available.

- `<Plug>(committia-scroll-diff-down-half)`

Scroll down the diff window by half a screen.

- `<Plug>(committia-scroll-diff-up-half)`

Scroll up the diff window by half a screen.

- `<Plug>(committia-scroll-diff-down-page)`

Scroll down the diff window by a screen.

- `<Plug>(committia-scroll-diff-up-page)`

Scroll up the diff window by a screen.

## Variables

Some variables are available to control the behavior of committia.vim.

- `g:committia_open_only_vim_starting`

If the value is `0`, committia.vim always attempts to open committia's buffer when `COMMIT_EDITMSG` buffer is opened.  If you use [vim-fugitive](https://github.com/tpope/vim-fugitive), I recommend to set this value to `1`.  The default value is `1`.

- `g:committia_use_singlecolumn`

If the value is `'always'`, committia.vim always employs single column mode.

- `g:committia_min_window_width`

If the width of window is narrower than the value, committia.vim employs single column mode.  The default value is `160`.

## Future

- Cooperate with [vim-fugitive](https://github.com/tpope/vim-fugitive).
- Add more VCS supports
- Test all features
- Support `git commit --amend` (now fallback to normal a commit buffer)

## Contribution

- [@uasi](https://github.com/uasi) : single column mode

## License

    Copyright (c) 2014 rhysd

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
    PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
    THE USE OR OTHER DEALINGS IN THE SOFTWARE.

