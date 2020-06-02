if (exists('g:loaded_committia') && g:loaded_committia) || &cp
    finish
endif

let g:committia_open_only_vim_starting = get(g:, 'committia_open_only_vim_starting', 1)

function! s:should_open(ft) abort
    return &ft ==# a:ft && (!g:committia_open_only_vim_starting || has('vim_starting')) && !exists('b:committia_opened')
endfunction

augroup plugin-committia
    autocmd!
    autocmd BufReadPost COMMIT_EDITMSG,MERGE_MSG if s:should_open('gitcommit') | call committia#open('git') | endif

    autocmd BufReadPost * if s:should_open('perforce') && get(g:, "committia_perforce_change_filetype", 0) | let g:committia_use_singlecolumn = 'always' | call committia#open('perforce') | endif

    " ... Add other VCSs' commit editor filetypes
augroup END

let g:loaded_committia = 1
