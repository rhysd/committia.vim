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
    echoerr g:committia#git#cmd . ' command is not found. Please check g:committia#git#cmd'
endif

function! s:extract_first_line(str) abort
    let i = stridx(a:str, "\r")
    if i > 0
        return a:str[: i - 1]
    endif
    let i = stridx(a:str, "\n")
    if i > 0
        return a:str[: i - 1]
    endif
    return a:str
endfunction

function! s:search_git_dir_and_work_tree() abort
    " '/.git' is unnecessary under submodule directory.
    let matched = matchlist(expand('%:p'), '[\\/]\.git[\\/]\%(\(modules\|worktrees\)[\\/].\+[\\/]\)\?\%(COMMIT_EDITMSG\|MERGE_MSG\)$')
    if len(matched) > 1
        let git_dir = expand('%:p:h')
        if matched[1] ==# 'worktrees'
            " Note:
            " This was added in #31. I'm not sure that the format of gitdir file
            " is fixed. Anyway, it works for now.
            let work_tree = fnamemodify(readfile(git_dir . '/gitdir')[0], ':h')
        else
            let work_tree = s:extract_first_line(s:system(printf('%s --git-dir="%s" rev-parse --show-toplevel', g:committia#git#cmd, git_dir)))
        endif
        return [git_dir, work_tree]
    endif

    let output = s:system(g:committia#git#cmd . ' rev-parse --show-cdup')
    if s:error_occurred()
        throw "committia: git: Failed to execute 'git rev-parse': " . output
    endif
    let root = s:extract_first_line(output)

    let git_dir = root . $GIT_DIR
    if !isdirectory(git_dir)
        throw "committia: git: Failed to get git-dir from $GIT_DIR"
    endif

    return [git_dir, fnamemodify(git_dir, ':h')]
endfunction

function! s:execute_git(cmd, git_dir, work_tree) abort
    return s:system(printf('%s --git-dir="%s" --work-tree="%s" %s', g:committia#git#cmd, a:git_dir, a:work_tree, a:cmd))
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

function! committia#git#diff() abort
    let [git_dir, work_tree] = s:search_git_dir_and_work_tree()

    if git_dir ==# '' || work_tree ==# ''
        throw "committia: git: Failed to get git-dir or work-tree"
    endif

    let index_file_was_not_found = s:ensure_index_file(git_dir)

    try
        let diff = s:execute_git(g:committia#git#diff_cmd, git_dir, work_tree)
        if s:error_occurred()
            throw "committia: git: Failed to execute diff command: " . diff
        endif
    finally
        if index_file_was_not_found
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

function! committia#git#status() abort
    let [git_dir, work_tree] = s:search_git_dir_and_work_tree()

    if git_dir ==# '' || work_tree ==# ''
        return ''
    endif

    let index_file_was_not_found = s:ensure_index_file(git_dir)

    try
        let status = s:execute_git(g:committia#git#status_cmd, git_dir, work_tree)
    finally
        if index_file_was_not_found
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
