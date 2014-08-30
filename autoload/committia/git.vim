let g:committia#git#cmd = get(g:, 'committia#git#cmd', 'git')
let g:committia#git#diff_cmd = get(g:, 'committia#git#diff_cmd', 'diff -u --cached')
let g:committia#git#status_cmd = get(g:, 'committia#git#status_cmd', 'status -b')

if ! executable(g:committia#git#cmd)
    echoerr g:committia#git#cmd . " command is not found"
endif

function! s:search_git_dir()
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

function! committia#git#diff(...)
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

    let diff = system(printf('%s --git-dir=%s %s', g:committia#git#cmd, git_dir, g:committia#git#diff_cmd))
    if v:shell_error
        throw "committia: git: Failed to execute diff command"
    endif

    if exists('l:index_file_was_not_found')
        let $GIT_INDEX_FILE = ''
    endif
    return split(diff, '\n')
endfunction

function! committia#git#status(...)
    let git_dir = a:0 > 0 ? a:1 : s:search_git_dir()
    if git_dir ==# ''
        return ''
    endif

    let status = system(printf('%s --git-dir=%s %s', g:committia#git#cmd, git_dir, g:committia#git#status_cmd))
    if v:shell_error
        throw "committia: git: Failed to execute status command"
    endif
    return map(split(status, '\n'), 'substitute(v:val, "^", "# ", "g")')
endfunction

function! committia#git#search_end_of_edit_region()
    call search('\m\%(\_^\s*\_$\n\)*\_^\s*# Please enter the commit', 'cW')
endfunction
