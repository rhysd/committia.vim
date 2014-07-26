let s:save_cpo = &cpo
set cpo&vim

let s:current_info = {}

function! s:open_window(vcs, type, info)
    let bufname = '__committia_' . a:type . '__'
    let coltype = a:info['singlecolumn'] ? 'singlecolumn_' : ''
    execute 'silent' g:committia_{coltype}{a:type}_window_opencmd bufname
    let a:info[a:type . '_winnr'] = bufwinnr(bufname)
    let a:info[a:type . '_bufnr'] = bufnr('%')
    call append(0, call('committia#' . a:vcs . '#' . a:type, []))
    execute 0
    setlocal nonumber bufhidden=wipe buftype=nofile readonly nolist nobuflisted noswapfile nomodifiable nomodified
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
        call call(g:committia_hooks[a:name], [a:info], g:committia_hooks)
    endif
endfunction

function! s:remove_all_except_for_commit_message()
    execute 0
    call search('\m\%(\_^\s*\_$\n\)*\_^\s*#', 'cW')
    normal! "_dG
    execute 0
    vertical resize 80
endfunction

function! s:callback_on_window_closed()
    if bufnr('%') == s:current_info.edit_bufnr
        for n in ['diff', 'status']
            if has_key(s:current_info, n . '_bufnr')
                let winnr = bufwinnr(s:current_info[n . '_bufnr'])
                if winnr != -1
                    execute winnr . 'wincmd w'
                    wincmd c
                endif
            endif
        endfor
        let s:current_info = {}
        autocmd! plugin-committia-winclosed
    endif
endfunction

function! committia#scroll_window(type, cmd)
    let target_winnr = bufwinnr(s:current_info[a:type . '_bufnr'])
    execute target_winnr . 'wincmd w'
    execute 'normal!' a:cmd
    wincmd p
endfunction

function! s:open_multicolumn(vcs)
    let info = {'vcs' : a:vcs, 'edit_winnr' : winnr(), 'edit_bufnr' : bufnr('%'), 'singlecolumn' : 0}

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

    let s:current_info = info
    setlocal bufhidden=wipe
    augroup plugin-committia-winclosed
        autocmd QuitPre COMMIT_EDITMSG call s:callback_on_window_closed()
    augroup END
endfunction

function! s:open_singlecolumn(vcs)
    let info = {'vcs' : a:vcs, 'edit_winnr' : winnr(), 'edit_bufnr' : bufnr('%'), 'singlecolumn' : 1}

    call s:open_diff_window(a:vcs, info)
    if getline(1, '$') ==# ['']
        execute info.diff_winnr . 'wincmd c'
        wincmd p
        return
    endif
    call s:execute_hook('diff_open', info)
    wincmd p

    let height = min([line('$') + 3, get(g:, 'committia_singlecolumn_edit_max_winheight', 16)])
    execute 'resize' height
    call s:execute_hook('edit_open', info)

    let s:current_info = info
    setlocal bufhidden=wipe
    augroup plugin-committia-winclosed
        autocmd QuitPre COMMIT_EDITMSG call s:callback_on_window_closed()
    augroup END
endfunction

function! committia#open(vcs)
    let is_narrow = winwidth(0) < g:committia_min_window_width
    let use_singlecolumn = g:committia_use_singlecolumn ==# 'always' || (is_narrow && g:committia_use_singlecolumn ==# 'fallback')

    if is_narrow && !use_singlecolumn
        call s:execute_hook('edit_open', {'vcs' : a:vcs})
        return
    endif

    if use_singlecolumn
        call s:open_singlecolumn(a:vcs)
    else
        call s:open_multicolumn(a:vcs)
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
