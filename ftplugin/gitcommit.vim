let s:show_committia = get(g:, 'committia_show', 0)

if (exists('g:loaded_committia') && g:loaded_committia) ||  s:show_committia == 0 || &cp
    finish
endif

let g:loaded_committia = 1
call committia#open('git')

