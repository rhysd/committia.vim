if (exists('g:loaded_committia') && g:loaded_committia) || &cp
    finish
endif

augroup plugin-committia
    autocmd!
    autocmd BufReadPost COMMIT_EDITMSG if &ft ==# 'gitcommit' && has('vim_starting') | call committia#open('git') | endif

    " ... Add other VCSs' commit editor filetypes
augroup END

let g:loaded_committia = 1
