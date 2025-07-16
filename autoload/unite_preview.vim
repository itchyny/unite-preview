" =============================================================================
" Filename: autoload/unite_preview.vim
" Author: itchyny
" License: MIT License
" Last Change: 2025/07/17 08:34:06.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:preview_types = [
      \ {
      \   'match': function('isdirectory'),
      \   'command': 'ls -A -p %s > %s',
      \ },
      \ {
      \   'match': { path -> path =~# '\.zip$' },
      \   'func': function('zip#Browse'),
      \ },
      \ {
      \   'match': { path -> path =~# '\.\%(tar\%(\.gz\)\?\|tgz\)$' },
      \   'func': function('tar#Browse'),
      \ }]

if executable('xxd') && executable('file')
  let s:executable = {
        \ 'command': 'xxd %s > %s',
        \ 'filetype': 'xxd'
        \ }
  function! s:executable.match(path) abort
    let fileb = system('file -b ' . shellescape(a:path))
    let istext = fileb =~# 'text'
    let isexec = fileb =~# 'exec'
    let isregexec = fileb =~# 'regexec'
    let isobject = fileb =~# 'object'
    return !istext && (isexec && !isregexec || isobject)
  endfunction
  call add(s:preview_types, s:executable)
endif

if executable('pdftotext')
  let s:pdf = {
        \ 'match': { path -> path =~# '\.pdf$' },
        \ 'command': 'pdftotext -enc ASCII7 -q -eol unix -nopgbrk -raw -layout %s %s'
        \ }
  call add(s:preview_types, s:pdf)
endif

function! unite_preview#func(candidate) abort
  call s:preview(a:candidate.action__path,
        \ get(filter(copy(s:preview_types),
        \ 'v:val.match(a:candidate.action__path)'), 0, {}))
endfunction

function! s:preview(path, type) abort
  let buf = bufnr('')
  if has_key(a:type, 'func')
    call s:open(a:path)
    call a:type.func(a:path)
  elseif has_key(a:type, 'command')
    let fname = tempname()
    call system(printf(a:type.command, shellescape(a:path), shellescape(fname)))
    call s:read(fname, a:type)
  else
    call s:read(a:path, a:type)
  endif
  setlocal nomodifiable readonly
  call cursor(1, 1)
  execute bufwinnr(buf) 'wincmd w'
endfunction

function! s:read(path, type) abort
  call s:open(a:path)
  silent 0r `=a:path`
  silent $ delete _
  execute 'setlocal filetype=' . get(a:type, 'filetype', '')
  doautocmd BufNewFile
endfunction

function! s:open(path) abort
  let buf = get(filter(tabpagebuflist(),
        \ 'expand("#" . v:val . ":p") =~? "^preview://"'), 0)
  if buf == 0
    rightbelow vnew
  else
    execute bufwinnr(buf) 'wincmd w'
  endif
  silent edit `= 'preview://' . a:path`
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
        \ modifiable noreadonly
  silent % delete _
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
