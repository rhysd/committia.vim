if did_filetype() || &cp	" filetype already set..
  finish		" ..don't do these checks
endif

function! s:SetPerforceFt() abort
" Line continuation is used here, remove 'C' from 'cpoptions'
  let s:cpo_save = &cpo
  set cpo&vim

  let s:specPattern = '\m^# A Perforce Change Specification\.$'
  let s:line1 = getline(1)
  if s:line1 =~? s:specPattern
    setfiletype perforce
    let g:committia_perforce_change_filetype = 1
  endif

  " Restore 'cpoptions'
  let &cpo = s:cpo_save

  unlet s:line1 s:specPattern s:cpo_save
endfunction

au BufNewFile,BufRead * call s:SetPerforceFt()
