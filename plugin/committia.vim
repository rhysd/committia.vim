if (exists('g:loaded_committia') && g:loaded_committia) || &cp
    finish
endif

augroup plugin-committia
    autocmd!
    autocmd FileType gitcommit echomsg "hi!"
augroup END

let g:loaded_committia = 1
