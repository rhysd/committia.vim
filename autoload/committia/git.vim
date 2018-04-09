if has('win32') || has('win64')
    let s:PATH_SEP =  '\'
    function! s:is_absolute_path(path) abort
        return a:path =~# '^[a-zA-Z]:[/\\]'
    endfunction
else
    let s:PATH_SEP =  '/'
    function! s:is_absolute_path(path) abort
        return a:path[0] ==# '/'
    endfunction
endif

let g:committia#git#cmd = get(g:, 'committia#git#cmd', 'git')
let g:committia#git#diff_cmd = get(g:, 'committia#git#diff_cmd', 'diff -u --cached --no-color --no-ext-diff')
let g:committia#git#status_cmd = get(g:, 'committia#git#status_cmd', '-c color.status=false status -b')

try
    silent call vimproc#version()

    " Note: vimproc exists
    function! s:system(cmd) abort
        let out = vimproc#system(a:cmd)
        if vimproc#get_last_status()
            throw printf("Failed to execute command '%s': %s", a:cmd, out)
        endif
        return out
    endfunction
catch /^Vim\%((\a\+)\)\=:E117/
    function! s:system(cmd) abort
        let out = system(a:cmd)
        if v:shell_error
            throw printf("Failed to execute command '%s': %s", a:cmd, out)
        endif
        return out
    endfunction
endtry

if !executable(g:committia#git#cmd)
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
    " Use environment variables if set
    if !empty($GIT_DIR) && !empty($GIT_WORK_TREE)
        if !isdirectory($GIT_WORK_TREE)
            throw 'Directory specified with $GIT_WORK_TREE does not exist: ' . $GIT_WORK_TREE
        endif
        return [$GIT_DIR, $GIT_WORK_TREE]
    endif

    " '/.git' is unnecessary under submodule directory.
    let matched = matchlist(expand('%:p'), '[\\/]\.git[\\/]\%(\(modules\|worktrees\)[\\/].\+[\\/]\)\?\%(COMMIT_EDITMSG\|MERGE_MSG\)$')
    if len(matched) > 1
        let git_dir = expand('%:p:h')

        if matched[1] ==# 'worktrees'
            " Note:
            " This was added in #31. I'm not sure that the format of gitdir file
            " is fixed. Anyway, it works for now.
            let work_tree = fnamemodify(readfile(git_dir . '/gitdir')[0], ':h')
            return [git_dir, work_tree]
        endif

        " Avoid executing Git command in git-dir because `git rev-parse --show-toplevel`
        " does not return the repository root. To handle work-tree properly,
        " set $CWD to the parent of git-dir, which is outside of the
        " git-dir. (#39)
        let cwd_saved = getcwd()
        let cwd = fnamemodify(git_dir, ':h')
        if cwd_saved !=# cwd
            execute 'lcd' cwd
        endif
        try
            let cmd = printf('%s --git-dir="%s" rev-parse --show-toplevel', g:committia#git#cmd, escape(git_dir, '\'))
            let out = s:system(cmd)
        finally
            if cwd_saved !=# getcwd()
                execute 'lcd' cwd_saved
            endif
        endtry

        let work_tree = s:extract_first_line(out)
        return [git_dir, work_tree]
    endif

    if s:is_absolute_path($GIT_DIR) && isdirectory($GIT_DIR)
        let git_dir = $GIT_DIR
    else
        let root = s:extract_first_line(s:system(g:committia#git#cmd . ' rev-parse --show-cdup'))

        let git_dir = root . $GIT_DIR
        if !isdirectory(git_dir)
            throw 'Failed to get git-dir from $GIT_DIR'
        endif
    endif

    return [git_dir, fnamemodify(git_dir, ':h')]
endfunction

function! s:execute_git(cmd) abort
    try
        let [git_dir, work_tree] = s:search_git_dir_and_work_tree()
    catch
        throw 'committia: git: Failed to retrieve git-dir or work-tree: ' . v:exception
    endtry

    if git_dir ==# '' || work_tree ==# ''
        throw 'committia: git: Failed to retrieve git-dir or work-tree'
    endif

    let index_file_was_set = s:ensure_index_file(git_dir)
    try
        let cmd = printf('%s --git-dir="%s" --work-tree="%s" %s', g:committia#git#cmd, escape(git_dir, '\'), escape(work_tree, '\'), a:cmd)
        try
            return s:system(cmd)
        catch
            throw 'committia: git: ' . v:exception
        endtry
    finally
        if index_file_was_set
            call s:unset_index_file()
        endif
    endtry
endfunction

function! s:ensure_index_file(git_dir) abort
    if $GIT_INDEX_FILE !=# ''
        return 0
    endif

    let lock_file = s:PATH_SEP . 'index.lock'
    if filereadable(lock_file)
        let $GIT_INDEX_FILE = lock_file
    else
        let $GIT_INDEX_FILE = a:git_dir . s:PATH_SEP . 'index'
    endif

    return 1
endfunction

function! s:unset_index_file() abort
    let $GIT_INDEX_FILE = ''
endfunction

function! committia#git#diff() abort
    let diff = s:execute_git(g:committia#git#diff_cmd)

    if diff !=# ''
        return split(diff, '\n')
    endif

    let line = s:diff_start_line()
    if line == 0
        return ['']
    endif

    return getline(line, '$')
endfunction

function! s:diff_start_line() abort
    let re_start_diff_line = '# -\+ >8 -\+\n\%(#.*\n\)\+diff --git'
    return search(re_start_diff_line, 'cenW')
endfunction

function! committia#git#status() abort
    try
        let status = s:execute_git(g:committia#git#status_cmd)
    catch /^committia: git: Failed to retrieve git-dir or work-tree/
        " Leave status window empty when git-dir or work-tree not found
        return ''
    endtry
    return map(split(status, '\n'), 'substitute(v:val, "^", "# ", "g")')
endfunction

function! committia#git#end_of_edit_region_line() abort
    let line = s:diff_start_line()
    if line == 0
        " If diff is not contained, assumes that the buffer ends with comment
        " block which was automatically inserted by Git.
        " Only the comment block will be removed from edit buffer. (#41)
        let line = line('$') + 1
    endif
    while line > 1
        if stridx(getline(line - 1), '#') != 0
            break
        endif
        let line -= 1
    endwhile
    if line > 1 && empty(getline(line - 1))
        " Drop empty line before comment block.
        let line -= 1
    endif
    return line
endfunction
