if has('win32') || has('win64')
    let s:PATH_SEP =  '\'
    throw printf("committia: perforce: perforce version of this is not available for windows ") . v:exception
else
    let s:PATH_SEP =  '/'
    function! s:is_absolute_path(path) abort
        return a:path[0] ==# '/'
    endfunction
endif


let s:submit_window = {}
let g:committia#perforce#cmd = get(g:, 'committia#perforce#cmd', 'p4')
" let g:committia#perforce#diff_cmd = get(g:, 'committia#perforce#diff_cmd', 'diff -u --cached --no-color --no-ext-diff')
let g:committia#perforce#diff_cmd = get(g:, 'committia#perforce#diff_cmd', 'diff -dubw')
let g:committia#perforce#status_cmd = get(g:, 'committia#perforce#status_cmd', '-c color.status=false status -b')

try
    silent call vimproc#version()

    " Note: vimproc exists
    function! s:system(cmd) abort"{{{
        let out = vimproc#system2(a:cmd)
        if vimproc#get_last_status()
            throw printf("committia: perforce: Failed to execute command '%s': %s ", a:cmd, out) . v:exception
        endif
        return out
    endfunction"}}}
catch /^Vim\%((\a\+)\)\=:E117/
    function! s:system(cmd) abort"{{{
        let out = system(a:cmd)
        if v:shell_error
            throw printf("committia: perforce: Failed to execute command '%s': %s ", a:cmd, out) . v:exception
        endif
        return out
    endfunction"}}}
endtry

if !executable(g:committia#perforce#cmd)
    echoerr g:committia#perforce#cmd . ' command is not found. Please check g:committia#perforce#cmd'
endif

let s:p4diff = ''
function! s:set_p4diff() abort"{{{
    if !empty($P4DIFF)
    endif
    let $P4DIFF = 'diff -NaubB'
endfunction
function! s:unset_p4diff() abort
    let $P4DIFF = s:p4diff
endfunction"}}}

function! s:search_perforce_client_and_work_tree() abort"{{{
    " Use environment variables if set
    let cmd = printf('%s info', g:committia#perforce#cmd)
    try
        call s:set_p4diff()
        let out = s:system(cmd)
    catch
        throw printf("committia: perforce: Does not look like a valid perforce directory ") . v:exception
    finally
        call s:unset_p4diff()
    endtry
    let split_out = split(out, '\n')
    let s:client_name = ''
    let s:client_root = ''
    " loop optimization
    let s:client_name = split_out->copy()->map({k, v -> matchlist(v, '\m\<Client\>\s\+\<name\>\s*:\s\+\zs\(\w\+\)\ze\s*$')})->filter({k,v -> !empty(v)})->get(0)->get(0)
    let s:client_root = split_out->copy()->map({k, v -> matchlist(v, '\m\<Client\>\s\+\<root\>\s*:\s\+\zs\(.\+\)\ze\s*$')})->filter({k, v -> !empty(v)})->get(0)->get(0)->escape('\')
    " for i in split_out
    "     if i =~# '\m\<Client\>\s\+\<name\>\s*:\s\+\zs\(\w\+\)\ze\s*$'
    "         let s:client_name = get(matchlist(i, '\m\<Client\>\s\+\<name\>\s*:\s\+\zs\(\w\+\)\ze\s*$'), 0)
    "     endif
    "     if i =~# '\m\<Client\>\s\+\<root\>\s*:\s\+'
    "         let s:client_root = escape(get(matchlist(i, '\m\<Client\>\s\+\<root\>\s*:\s\+\zs\(.\+\)\ze\s*$'), 0), '\')
    "     endif
    " endfor
    if s:client_name ==# ''
        throw printf("committia: perforce: could not determine Client name with p4 info command ") . v:exception
    endif
    if s:client_root ==# ''
        throw printf("committia: perforce: could not determine Client root with p4 info command ") . v:exception
    endif
    if !isdirectory(s:client_root)
        throw printf("committia: perforce: the client root determined by p4 info command is not a directory ")  . v:exception
    endif
    return [s:client_name, s:client_root]
endfunction"}}}

function! s:perforce_remove_blank_lines(files) abort"{{{
    return a:files->copy()->map({k, v -> empty(matchlist(v, '\m^\s*$'))? v : []})->filter({k, v -> !empty(v)})
endfunction"}}}
function! s:perforce_remove_line_endings(files) abort"{{{
    return a:files->copy()->map({k, v -> substitute(v, '\s*#\s*\<\S\+\>\s*$', '', "g")})
endfunction"}}}
function! s:perforce_remove_line_beginnings(files) abort"{{{
    return a:files->copy()->map({k, v -> substitute(v, '^\s*\ze\S', '', "g")})
endfunction"}}}
function! s:perforce_escape_file_names(files) abort"{{{
    return a:files->copy()->map({k, v -> escape(v, '\')})
endfunction"}}}
function! s:perforce_cleanup_file_list(files) abort"{{{
    let l:files = a:files
    " lets get rid of blank lines
    let l:files = s:perforce_remove_blank_lines(l:files)
    if empty(l:files)
        throw printf("committia: perforce: no files files to diff in the perforce submission window after removing blank lines ") . v:exception
    endif
    let l:files = s:perforce_remove_line_endings(l:files)
    if empty(l:files)
        throw printf("committia: perforce: no files files to diff in the perforce submission window after removing line endings ") . v:exception
    endif
    let l:files = s:perforce_remove_line_beginnings(l:files)
    if empty(l:files)
        throw printf("committia: perforce: no files files to diff in the perforce submission window after removing line beginnings ") . v:exception
    endif
    let l:files = s:perforce_escape_file_names(l:files)
    if empty(l:files)
        throw printf("committia: perforce: the perforce submission window is empty after escaping files ") . v:exception
    endif
    return l:files
endfunction"}}}

function! s:perforce_list_of_files_to_diff() abort"{{{
    " lets get the list of files from the output window
    let l:match = s:submit_window.buf_lines->copy()->map({k, v -> !empty(matchlist(v, '\m\<Files\>\s*:\s*$'))})
    if l:match->index(1) ==# -1
        throw printf("committia: perforce: did not find files this is is not a p4 submit window ") . v:exception
    elseif (l:match->index(1)+1) >= l:match->len()
        throw printf("committia: perforce: dont see any files to diff from p4 submit window ") . v:exception
    endif
    let s:submit_window.files = s:submit_window.buf_lines[(l:match->index(1)+1):]
    let s:submit_window.files = s:perforce_cleanup_file_list(s:submit_window.files)
endfunction"}}}

function! s:execute_perforce(cmd) abort"{{{
    try
        let [s:perforce_client, s:work_tree] = s:search_perforce_client_and_work_tree()
    catch
        throw printf('committia: perforce: Failed to retrieve perforce-client, work-tree ') . v:exception
    endtry

    if s:perforce_client ==# '' || s:work_tree ==# ''
        throw printf('committia: perforce: Failed to retrieve perforce client or work-tree ') . v:excpetion
    endif

    try
        call s:perforce_list_of_files_to_diff()
    catch
        throw printf("committia: perforce: Failed to get the list of files to diff ") . v:exception
    endtry

    try
        call s:set_p4diff()
        let cmd = printf('%s -c %s %s %s', g:committia#perforce#cmd, s:perforce_client, a:cmd, join(s:submit_window.files, ' '))
        try
            return s:system(cmd)
        catch
            throw ('committia: perforce: %s threw and exception', cmd) . v:exception
        endtry
    finally
        call s:unset_p4diff()
    endtry
endfunction"}}}

function! committia#perforce#diff() abort"{{{
    let s:submit_window.bufnr = bufnr('%')
    let s:submit_window.bufname = bufname('%')
    let s:submit_window.buf_lines = getbufline(s:submit_window.bufnr, 1, '$')
    try
        let diff = s:execute_perforce(g:committia#perforce#diff_cmd)
    catch
        throw printf("committia: perforce: Failed to execute function s:execute_perforce ") . v:exception
    endtry

    if diff !=# ''
        return split(diff, '\n')
    endif

    let line = s:diff_start_line()
    if line == 0
        return ['']
    endif

    return getline(line, '$')
endfunction"}}}

" vim: filetype=vim:syntax=vim:ts=4:tw=0:sw=4:sts=4:expandtab:norl:foldmethod=marker:
