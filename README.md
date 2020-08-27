More Pleasant Editing on Commit Message
=======================================

When you type `git commit`, Vim starts and opens a commit buffer. This plugin improves
the commit buffer.

committia.vim splits the buffer into 3 windows; edit window, status window and diff window.
You no longer need to repeat moving to another window, scrolling and backing to the former
position in order to see a long commit diff.

If the width of Vim window is too narrow (160 characters by default), committia.vim falls back
to single column mode, which has 2 windows; edit window and diff window.

For wide window:

![double column mode](https://github.com/rhysd/ss/blob/master/committia.vim/main.jpg?raw=true)

For narrow window:

![single column mode](https://github.com/rhysd/ss/blob/master/committia.vim/narrow.jpg?raw=true)

## Hooks

You can hook on opening the windows.

Available hooks are:

- `edit_open`: When opening a commit message window, this hook is called from the window.
- `diff_open`: When opening a diff window, this hook is called from the window.
- `status_open`: When opening a status window, this hook is called from the window.
  Please note that this hook is not called on single-column mode since it does not have a dedicated
  window for status.

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
    endif

    " Scroll the diff window from insert mode
    " Map <C-n> and <C-p>
    imap <buffer><C-n> <Plug>(committia-scroll-diff-down-half)
    imap <buffer><C-p> <Plug>(committia-scroll-diff-up-half)
endfunction
```

## Mappings

Mappings to scroll diff window for insert mode are available.

| Mapping                                   | Description                                   |
|-------------------------------------------|-----------------------------------------------|
| `<Plug>(committia-scroll-diff-down-half)` | Scroll down the diff window by half a screen. |
| `<Plug>(committia-scroll-diff-up-half)`   | Scroll up the diff window by half a screen.   |
| `<Plug>(committia-scroll-diff-down-page)` | Scroll down the diff window by a screen.      |
| `<Plug>(committia-scroll-diff-up-page)`   | Scroll up the diff window by a screen.        |
| `<Plug>(committia-scroll-diff-down)`      | Scroll down the diff window by one line.      |
| `<Plug>(committia-scroll-diff-up)`        | Scroll up the diff window by one line.        |

## Variables

Some variables are available to control the behavior of committia.vim.

### `g:committia_open_only_vim_starting` (default: `1`)

If the value is `0`, committia.vim always attempts to open committia's buffer when `COMMIT_EDITMSG`
buffer is opened. If you use [vim-fugitive](https://github.com/tpope/vim-fugitive), I recommend to
set this value to `1`.

### `g:committia_use_singlecolumn` (default: `'fallback'`)

If the value is `'always'`, committia.vim always employs single column mode.

### `g:committia_min_window_width` (default: `160`)

If the width of window is narrower than the value, committia.vim employs single column mode.

### `g:committia_status_window_opencmd` (default: `'belowright split'`)

Vim command which opens a status window in multi-columns mode.

### `g:committia_diff_window_opencmd` (default: `'botright vsplit'`)

Vim command which opens a diff window in multi-columns mode.

### `g:committia_singlecolumn_diff_window_opencmd` (default: `'belowright split'`)

Vim command which opens a diff window in single-column mode.

### `g:committia_edit_window_width` (default: `80`)

If committia.vim is in multi-columns mode, specifies the width of the edit window.

## Future

- Cooperate with [vim-fugitive](https://github.com/tpope/vim-fugitive).
- Add more VCS supports
- Test all features

## Contribution

- [@uasi](https://github.com/uasi) : single column mode
- [@anekos](https://github.com/uasi) : submodule and worktree support
- [and more contributors who sent a patch](https://github.com/rhysd/committia.vim/graphs/contributors)

## License

[Distributed under the MIT license](LICENSE)
