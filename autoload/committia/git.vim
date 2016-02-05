let g:committia#git#cmd = get(g:, 'committia#git#cmd', 'git')
let g:committia#git#diff_cmd = get(g:, 'committia#git#diff_cmd', 'diff -u --cached --no-color')
let g:committia#git#status_cmd = get(g:, 'committia#git#status_cmd', 'status -b')

if ! executable(g:committia#git#cmd)
    echoerr g:committia#git#cmd . " command is not found"
endif

function! s:search_git_dir() abort
    " '/.git' is unnecessary under submodule directory.
    if expand('%:p') =~# '[\\/]\.git[\\/]\%(modules[\\/].\+[\\/]\)\?COMMIT_EDITMSG$'
        return expand('%:p:h')
    endif

    let root = matchstr(system(g:committia#git#cmd . ' rev-parse --show-cdup'),  '[^\n]\+')
    if v:shell_error
        throw "committia: git: Failed to execute 'git rev-parse'"
    endif

    if !isdirectory(root . $GIT_DIR)
        throw "committia: git: Failed to get git-dir from $GIT_DIR"
    endif

    return root . $GIT_DIR
endfunction

function! s:execute_git(cmd, git_dir) abort
    return system(printf('%s --git-dir="%s" --work-tree="%s" %s', g:committia#git#cmd, a:git_dir, fnamemodify(a:git_dir, ':h'), a:cmd))
endfunction

function! committia#git#diff(...) abort
    let git_dir = a:0 > 0 ? a:1 : s:search_git_dir()

    if git_dir ==# ''
        throw "committia: git: Failed to get git-dir"
    endif

    if $GIT_INDEX_FILE == ''
        let lock_file = git_dir . (has('win32') || has('win64') ? '\' : '/') . 'index.lock'
        if filereadable(lock_file)
            let $GIT_INDEX_FILE = lock_file
        else
            let $GIT_INDEX_FILE = git_dir . (has('win32') || has('win64') ? '\' : '/') . 'index'
        endif
        let index_file_was_not_found = 1
    endif

    let diff =  s:execute_git(g:committia#git#diff_cmd, git_dir)
    if v:shell_error
        throw "committia: git: Failed to execute diff command: " . diff
    endif

    if exists('l:index_file_was_not_found')
        let $GIT_INDEX_FILE = ''
    endif
    return split(diff, '\n')
endfunction

function! committia#git#status(...) abort
    let git_dir = a:0 > 0 ? a:1 : s:search_git_dir()
    if git_dir ==# ''
        return ''
    endif

    let status = s:execute_git(g:committia#git#status_cmd, git_dir)
    if v:shell_error
        throw "committia: git: Failed to execute status command: " . status
    endif
    return map(split(status, '\n'), 'substitute(v:val, "^", "# ", "g")')
endfunction

function! committia#git#search_end_of_edit_region() abort
    call search('\m\%(\_^\s*\_$\n\)*\_^\s*# Please enter the commit', 'cW')
endfunction
