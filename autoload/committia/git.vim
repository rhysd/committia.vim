let s:PATH_SEP = has('win32') || has('win64') ? '\' : '/'

let g:committia#git#cmd = get(g:, 'committia#git#cmd', 'git')
let g:committia#git#diff_cmd = get(g:, 'committia#git#diff_cmd', 'diff -u --cached --no-color --no-ext-diff')
let g:committia#git#status_cmd = get(g:, 'committia#git#status_cmd', '-c color.status=false status -b')

try
    silent call vimproc#version()

    " Note: vimproc exists
    function! s:system(cmd) abort
        return vimproc#system(a:cmd)
    endfunction
    function! s:error_occurred() abort
        return vimproc#get_last_status()
    endfunction
catch /^Vim\%((\a\+)\)\=:E117/
    function! s:system(cmd) abort
        return system(a:cmd)
    endfunction
    function! s:error_occurred() abort
        return v:shell_error
    endfunction
endtry

if ! executable(g:committia#git#cmd)
    echoerr g:committia#git#cmd . " command is not found"
endif

function! s:search_git_dir() abort
    " '/.git' is unnecessary under submodule directory.
    if expand('%:p') =~# '[\\/]\.git[\\/]\%(modules[\\/].\+[\\/]\)\?\%(COMMIT_EDITMSG\|MERGE_MSG\)$'
        return expand('%:p:h')
    endif

    let root = matchstr(s:system(g:committia#git#cmd . ' rev-parse --show-cdup'),  '[^\n]\+')
    if s:error_occurred()
        throw "committia: git: Failed to execute 'git rev-parse'"
    endif

    if !isdirectory(root . $GIT_DIR)
        throw "committia: git: Failed to get git-dir from $GIT_DIR"
    endif

    return root . $GIT_DIR
endfunction

function! s:execute_git(cmd, git_dir) abort
    return s:system(printf('%s --git-dir="%s" --work-tree="%s" %s', g:committia#git#cmd, a:git_dir, fnamemodify(a:git_dir, ':h'), a:cmd))
endfunction

function! s:ensure_index_file(git_dir) abort
    if $GIT_INDEX_FILE != ''
        return 0
    endif

    let s:lock_file = s:PATH_SEP . 'index.lock'
    if filereadable(s:lock_file)
        let $GIT_INDEX_FILE = s:lock_file
    else
        let $GIT_INDEX_FILE = a:git_dir . s:PATH_SEP . 'index'
    endif

    return 1
endfunction

function! s:unset_index_file() abort
    let $GIT_INDEX_FILE = ''
endfunction

function! committia#git#diff(...) abort
    let git_dir = a:0 > 0 ? a:1 : s:search_git_dir()

    if git_dir ==# ''
        throw "committia: git: Failed to get git-dir"
    endif

    let index_file_was_not_found = s:ensure_index_file(git_dir)

    try
        let diff =  s:execute_git(g:committia#git#diff_cmd, git_dir)
        if s:error_occurred()
            throw "committia: git: Failed to execute diff command: " . diff
        endif
    finally
        if l:index_file_was_not_found
            call s:unset_index_file()
        endif
    endtry

    if diff ==# ''
        let inline_diff_start_line = search('# Everything below will be removed.\ndiff ', 'cW') - 1
        if inline_diff_start_line ==# -1
            return ['']
        endif
        return getline(inline_diff_start_line, '$')
    else
        return split(diff, '\n')
    endif
endfunction

function! committia#git#status(...) abort
    let git_dir = a:0 > 0 ? a:1 : s:search_git_dir()
    if git_dir ==# ''
        return ''
    endif

    let index_file_was_not_found = s:ensure_index_file(git_dir)

    try
        let status = s:execute_git(g:committia#git#status_cmd, git_dir)
    finally
        if l:index_file_was_not_found
            call s:unset_index_file()
        endif
    endtry

    if s:error_occurred()
        throw "committia: git: Failed to execute status command: " . status
    endif
    return map(split(status, '\n'), 'substitute(v:val, "^", "# ", "g")')
endfunction

function! committia#git#search_end_of_edit_region() abort
    call search('\m\%(\_^\s*\_$\n\)*\_^\s*# Please enter \%(the\|a\) commit', 'cW')
endfunction
