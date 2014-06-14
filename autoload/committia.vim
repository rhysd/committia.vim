function! committia#open(vcs)
    let commit_bufnr = bufnr('%')

    execute g:committia_diff_window_opencmd '__committia_diff__'
    let diff_winnr = bufwinnr('__committia_diff__')
    execute diff_winnr . 'wincmd w'
    let status_bufnr = bufnr('%')
    call append(0, call('committia#' . a:vcs . '#diff', []))
    execute 0
    setlocal nonumber ft=diff bufhidden=wipe readonly nobuflisted noswapfile nomodifiable nomodified
    wincmd p

    execute g:committia_status_window_opencmd '__committia_status__'
    let status_winnr = bufwinnr('__committia_status__')
    execute status_winnr . 'wincmd w'
    let status_bufnr = bufnr('%')
    call append(0, call('committia#' . a:vcs . '#status', []))
    execute 0
    noautocmd setlocal ft=gitcommit
    syntax on
    setlocal nonumber bufhidden=wipe readonly nobuflisted noswapfile nomodifiable nomodified
    let status_winheight = winheight(status_bufnr)
    if line('$') < winheight(status_bufnr)
        execute 'resize' line('$')
    endif
    wincmd p

    normal! ggdG
    vertical resize 80
    startinsert
endfunction
