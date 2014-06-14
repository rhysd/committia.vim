let s:save_cpo = &cpo
set cpo&vim

function! s:open_window(vcs, type, info)
    let bufname = '__committia_' . a:type . '__'
    execute 'silent' g:committia_{a:type}_window_opencmd bufname
    let a:info[a:type . '_winnr'] = bufwinnr(bufname)
    let a:info[a:type . '_bufnr'] = bufnr('%')
    call append(0, call('committia#' . a:vcs . '#' . a:type, []))
    execute 0
    setlocal nonumber bufhidden=wipe readonly nobuflisted noswapfile nomodifiable nomodified
endfunction

function! s:open_diff_window(vcs, info)
    call s:open_window(a:vcs, 'diff', a:info)
    setlocal ft=diff
endfunction

function! s:open_status_window(vcs, info)
    call s:open_window(a:vcs, 'status', a:info)
    set ft=gitcommit
    let status_winheight = winheight(a:info.status_bufnr)
    if line('$') < winheight(a:info.status_bufnr)
        execute 'resize' line('$')
    endif
endfunction

function! s:execute_hook(name, info)
    if has_key(g:committia_hooks, a:name)
        call call(g:committia_hooks[a:name], [], a:info)
    endif
endfunction

function! s:remove_all_except_for_commit_message()
    execute 0
    call search('^\%(\s*$\|\s*#\)', 'cW')
    normal! dG
    execute 0
    vertical resize 80
endfunction

function! committia#open(vcs)
    if winwidth(0) < g:committia_min_window_width
        call s:execute_hook('edit_open', {'vcs' : a:vcs})
        return
    endif

    let info = {'vcs' : a:vcs, 'edit_winnr' : winnr(), 'edit_bufnr' : bufnr('%')}

    call s:open_diff_window(a:vcs, info)
    if getline(1, '$') ==# ['']
        execute info.diff_winnr . 'wincmd c'
        wincmd p
        return
    endif
    call s:execute_hook('diff_open', info)
    wincmd p

    call s:open_status_window(a:vcs, info)
    call s:execute_hook('status_open', info)
    wincmd p

    silent call s:remove_all_except_for_commit_message()
    call s:execute_hook('edit_open', info)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
