if ! executable('git')
    echoerr "'git' command not found"
endif

let g:committia#git#cmd = get(g:, 'committia#git#cmd', 'git')
let g:committia#git#diff_cmd = get(g:, 'committia#git#diff_cmd', 'diff -u --cached')
let g:committia#git#status_cmd = get(g:, 'committia#git#status_cmd', 'status -b')

function! s:search_git_root()
    if expand('%:p') =~# '\/.git\/COMMIT_EDITMSG'
        return expand('%:p:h')
    endif

    let root = matchstr(system(g:committia#git#cmd . ' rev-parse --show-cdup'),  '[^\n]\+')
    if v:shell_error
        throw "committia: git: Failed to execute 'git rev-parse'"
    endif
    return root
endfunction

function! committia#git#diff(...)
    let git_dir = a:0 > 0 ? a:1 : s:search_git_root()

    if git_dir ==# ''
        throw "committia: git: Failed to get git-dir"
    endif

    let diff = system(printf('%s --git-dir=%s %s', g:committia#git#cmd, git_dir, g:committia#git#diff_cmd))
    if v:shell_error
        throw "committia: git: Failed to execute diff command"
    endif
    return split(diff, '\n')
endfunction

function! committia#git#status(...)
    let git_dir = a:0 > 0 ? a:1 : s:search_git_root()
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
