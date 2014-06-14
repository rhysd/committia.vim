if (exists('g:loaded_committia') && g:loaded_committia) || &cp
    finish
endif

let g:committia_diff_window_opencmd = get(g:, 'committia_diff_window_opencmd', 'botright vsplit')
let g:committia_status_window_opencmd = get(g:, 'committia_status_window_opencmd', 'belowright split')
let g:committia_hooks = get(g:, 'committia_status_hooks', {})

augroup plugin-committia
    autocmd!
    autocmd BufReadPost COMMIT_EDITMSG if &ft ==# 'gitcommit' | call committia#open('git') | endif
    " ... Add other VCSs' commit editor filetypes
augroup END

let g:loaded_committia = 1
