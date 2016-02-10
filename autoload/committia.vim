let s:save_cpo = &cpo
set cpo&vim

let g:committia_use_singlecolumn = get(g:, 'committia_use_singlecolumn', 'fallback')
let g:committia_min_window_width = get(g:, 'committia_min_window_width', 160)
let g:committia_diff_window_opencmd = get(g:, 'committia_diff_window_opencmd', 'botright vsplit')
let g:committia_status_window_opencmd = get(g:, 'committia_status_window_opencmd', 'belowright split')
let g:committia_singlecolumn_diff_window_opencmd = get(g:, 'committia_singlecolumn_diff_window_opencmd', 'belowright split')
let g:committia_hooks = get(g:, 'committia_hooks', {})

inoremap <silent> <Plug>(committia-scroll-diff-down-half) <C-o>:call committia#scroll_window('diff', 'C-d')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-up-half) <C-o>:call committia#scroll_window('diff', 'C-u')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-down-page) <C-o>:call committia#scroll_window('diff', 'C-f')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-up-page) <C-o>:call committia#scroll_window('diff', 'C-b')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-down) <C-o>:call committia#scroll_window('diff', 'j')<CR>
inoremap <silent> <Plug>(committia-scroll-diff-up) <C-o>:call committia#scroll_window('diff', 'k')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-down-half) :<C-u>call committia#scroll_window('diff', 'C-d')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-up-half) :<C-u>call committia#scroll_window('diff', 'C-u')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-down-page) :<C-u>call committia#scroll_window('diff', 'C-f')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-up-page) :<C-u>call committia#scroll_window('diff', 'C-b')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-down) :<C-u>call committia#scroll_window('diff', 'j')<CR>
nnoremap <silent> <Plug>(committia-scroll-diff-up) :<C-u>call committia#scroll_window('diff', 'k')<CR>

let s:current_info = {}

function! s:open_window(vcs, type, info, ft) abort
    let content = call('committia#' . a:vcs . '#' . a:type, [])

    let bufname = '__committia_' . a:type . '__'
    let coltype = a:info['singlecolumn'] ? 'singlecolumn_' : ''
    execute 'silent' g:committia_{coltype}{a:type}_window_opencmd bufname
    let a:info[a:type . '_winnr'] = bufwinnr(bufname)
    let a:info[a:type . '_bufnr'] = bufnr('%')
    call append(0, content)
    execute 0
    execute 'setlocal ft=' . a:ft
    setlocal nonumber bufhidden=wipe buftype=nofile readonly nolist nobuflisted noswapfile nomodifiable nomodified
endfunction


" Open diff window.  If no diff is detected, close the window and return to
" the original window.
" It returns 0 if the window is not open, othewise 1
function! s:open_diff_window(vcs, info) abort
    call s:open_window(a:vcs, 'diff', a:info, 'diff')
    if getline(1, '$') ==# ['']
        execute a:info.diff_winnr . 'wincmd c'
        wincmd p
        return 0
    endif
    return 1
endfunction

function! s:open_status_window(vcs, info) abort
    call s:open_window(a:vcs, 'status', a:info, 'gitcommit')
    let status_winheight = winheight(a:info.status_bufnr)
    if line('$') < winheight(a:info.status_bufnr)
        execute 'resize' line('$')
    endif
    return 1
endfunction

function! s:execute_hook(name, info) abort
    if has_key(g:committia_hooks, a:name)
        call call(g:committia_hooks[a:name], [a:info], g:committia_hooks)
    endif
endfunction

function! s:remove_all_contents_except_for_commit_message(vcs) abort
    execute 1
    " Handle squash message
    call call('committia#' . a:vcs . '#search_end_of_edit_region', [])
    silent normal! "_dG
    execute 1
    vertical resize 80
endfunction

function! s:callback_on_window_closed() abort
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

function! s:callback_on_window_closed_workaround() abort
    let edit_winnr = bufwinnr(s:current_info.edit_bufnr)
    if edit_winnr == -1
        quit!
    endif
endfunction

function! s:get_map_of(cmd) abort
    return eval('"\<' . a:cmd . '>"')
endfunction

function! committia#scroll_window(type, cmd) abort
    let target_winnr = bufwinnr(s:current_info[a:type . '_bufnr'])
    if target_winnr == -1
        return
    endif
    execute target_winnr . 'wincmd w'
    execute 'normal!' s:get_map_of(a:cmd)
    wincmd p
endfunction

function! s:set_callback_on_closed() abort
    augroup plugin-committia-winclosed
        if exists('##QuitPre')
            autocmd QuitPre COMMIT_EDITMSG,MERGE_MSG call s:callback_on_window_closed()
        else
            autocmd WinEnter __committia_diff__,__committia_status__ nested call s:callback_on_window_closed_workaround()
        end
    augroup END
endfunction

function! s:open_multicolumn(vcs) abort
    let info = {'vcs' : a:vcs, 'edit_winnr' : winnr(), 'edit_bufnr' : bufnr('%'), 'singlecolumn' : 0}

    let diff_window_opened = s:open_diff_window(a:vcs, info)
    if !diff_window_opened
        return
    endif
    call s:execute_hook('diff_open', info)
    wincmd p

    call s:open_status_window(a:vcs, info)
    call s:execute_hook('status_open', info)
    wincmd p

    call s:remove_all_contents_except_for_commit_message(info.vcs)
    call s:execute_hook('edit_open', info)

    let s:current_info = info
    setlocal bufhidden=wipe
    let b:committia_opened = 1
    call s:set_callback_on_closed()
endfunction

function! s:open_singlecolumn(vcs) abort
    let info = {'vcs' : a:vcs, 'edit_winnr' : winnr(), 'edit_bufnr' : bufnr('%'), 'singlecolumn' : 1}

    let diff_window_opened = s:open_diff_window(a:vcs, info)
    if !diff_window_opened
        return
    endif
    call s:execute_hook('diff_open', info)
    wincmd p

    let height = min([line('$') + 3, get(g:, 'committia_singlecolumn_edit_max_winheight', 16)])
    execute 'resize' height
    call s:execute_hook('edit_open', info)

    let s:current_info = info
    setlocal bufhidden=wipe
    let b:committia_opened = 1
    call s:set_callback_on_closed()
endfunction

function! committia#open(vcs) abort
    let is_narrow = winwidth(0) < g:committia_min_window_width
    let use_singlecolumn
                \ = g:committia_use_singlecolumn ==# 'always'
                \ || (is_narrow && g:committia_use_singlecolumn ==# 'fallback')

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
