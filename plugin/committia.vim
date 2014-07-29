if (exists('g:loaded_committia') && g:loaded_committia) || &cp
    finish
endif

let g:committia_use_singlecolumn = get(g:, 'committia_use_singlecolumn', 'fallback')
let g:committia_min_window_width = get(g:, 'committia_min_window_width', 160)
let g:committia_diff_window_opencmd = get(g:, 'committia_diff_window_opencmd', 'botright vsplit')
let g:committia_status_window_opencmd = get(g:, 'committia_status_window_opencmd', 'belowright split')
let g:committia_singlecolumn_diff_window_opencmd = get(g:, 'committia_singlecolumn_diff_window_opencmd', 'belowright split')
let g:committia_hooks = get(g:, 'committia_hooks', {})

inoremap <silent> <Plug>(committia-scroll-diff-down-half) <C-o>:call committia#scroll_window('diff', 'C-d')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-up-half) <C-o>:call committia#scroll_window('diff', 'C-u')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-down-page) <C-o>:call committia#scroll_window('diff', 'C-f')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-up-page) <C-o>:call committia#scroll_window('diff', 'C-b')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-down) <C-o>:call committia#scroll_window('diff', 'j')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-up) <C-o>:call committia#scroll_window('diff', 'k')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-down-half) :<C-u>call committia#scroll_window('diff', 'C-d')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-up-half) :<C-u>call committia#scroll_window('diff', 'C-u')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-down-page) :<C-u>call committia#scroll_window('diff', 'C-f')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-up-page) :<C-u>call committia#scroll_window('diff', 'C-b')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-down) :<C-u>call committia#scroll_window('diff', 'j')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-up) :<C-u>call committia#scroll_window('diff', 'k')<CR>


augroup plugin-committia
    autocmd!
    autocmd BufReadPost COMMIT_EDITMSG if &ft ==# 'gitcommit' | call committia#open('git') | endif

    " ... Add other VCSs' commit editor filetypes
augroup END

let g:loaded_committia = 1
