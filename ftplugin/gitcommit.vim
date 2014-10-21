if !(bufname('%') =~ 'COMMIT_EDITMSG$')
    finish
endif

if (exists('g:loaded_committia') && g:loaded_committia) || &cp
    finish
endif

let g:loaded_committia = 1
call committia#open('git')

