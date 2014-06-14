function! s:open_window(vcs, type)
    let bufname = '__committia_' . a:type . '__'
    execute g:committia_{a:type}_window_opencmd bufname
    let winnr = bufwinnr(bufname)
    let bufnr = bufnr('%')
    call append(0, call('committia#' . a:vcs . '#' . a:type, []))
    execute 0
    setlocal nonumber bufhidden=wipe readonly nobuflisted noswapfile nomodifiable nomodified

    return [winnr, bufnr]
endfunction

function! s:open_diff_window(vcs)
    let window_info = s:open_window(a:vcs, 'diff')
    setlocal ft=diff
    return window_info
endfunction

function! s:open_status_window(vcs)
    let [status_winnr, status_bufnr] = s:open_window(a:vcs, 'status')
    noautocmd setlocal ft=gitcommit
    syntax on
    let status_winheight = winheight(status_bufnr)
    if line('$') < winheight(status_bufnr)
        execute 'resize' line('$')
    endif

    return [status_winnr, status_bufnr]
endfunction

function! committia#open(vcs)
    let commit_bufnr = bufnr('%')

    let [diff_winnr, diff_bufnr] = s:open_diff_window(a:vcs)
    wincmd p
    let [status_winnr, status_bufnr] = s:open_status_window(a:vcs)
    wincmd p

    execute 0
    call search('^\%(\s*$\|\s*#\)', 'cW')
    undojoin | normal! dG
    execute 0
    vertical resize 80
    normal! $
    startinsert!
endfunction
