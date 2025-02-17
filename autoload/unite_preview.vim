" =============================================================================
" Filename: autoload/unite_preview.vim
" Author: itchyny
" License: MIT License
" Last Change: 2025/02/17 21:46:21.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:preview_type = []

function! s:new_preview_type(dict) abort
  if !has_key(a:dict, 'match') && !has_key(a:dict, 'matcher')
    echoerr 'unite-preview: specify match or matcher'
    echo a:dict
    return
  endif
  call add(s:preview_type, a:dict)
endfunction

if executable('xxd')
  let s:binary = {
        \ 'match': '\.\(hi\)$',
        \ 'extension': 'xxd',
        \ 'command': 'xxd %s > %s'
        \ }
  call s:new_preview_type(s:binary)
  if executable('file')
    let s:executable = {
          \ 'extension': 'xxd',
          \ 'command': 'xxd %s > %s',
          \ 'filetype': 'xxd'
          \ }
    function! s:executable.matcher(candidate) abort
      let fileb = system('file -b ' . shellescape(a:candidate.action__path))
      let istext = fileb =~# 'text'
      let isexec = fileb =~# 'exec'
      let isregexec = fileb =~# 'regexec'
      let isobject = fileb =~# 'object'
      return !istext && (isexec && !isregexec || isobject)
    endfunction
    call s:new_preview_type(s:executable)
  endif
endif

let s:make = {
      \ 'match': 'Makefile',
      \ 'extension': 'Makefile',
      \ }
call s:new_preview_type(s:make)

let s:make_am = {
      \ 'match': 'Makefile\.am',
      \ 'extension': '',
      \ 'filetype': 'automake',
      \ }
call s:new_preview_type(s:make_am)

let s:configure = {
      \ 'match': 'configure',
      \ 'filetype': 'sh',
      \ }
call s:new_preview_type(s:configure)

let s:dockerfile = {
      \ 'match': 'Dockerfile',
      \ 'filetype': 'dockerfile',
      \ }
call s:new_preview_type(s:dockerfile)

let s:gomod = {
      \ 'match': 'go\.\(.\+\.\)\?mod$',
      \ 'filetype': 'gomod',
      \ }
call s:new_preview_type(s:gomod)

let s:vimrc = {
      \ 'match': 'vimrc$',
      \ 'extension': 'vim',
      \ }
call s:new_preview_type(s:vimrc)

let s:viminfo = {
      \ 'match': 'viminfo',
      \ 'extension': 'viminfo',
      \ 'filetype': 'viminfo',
      \ }
call s:new_preview_type(s:viminfo)

let s:zshrc = {
      \ 'match': 'zshrc$',
      \ 'extension': 'zsh',
      \ }
call s:new_preview_type(s:zshrc)

let s:nroff = {
      \ 'match': '\.1$',
      \ 'filetype': 'nroff',
      \ }
call s:new_preview_type(s:nroff)

let s:zip = {
      \ 'match': '\.\(zip\)$',
      \ 'extension': 'zip',
      \ 'funconly': 1
      \ }
function! s:zip.vimfunc(path) abort
  call zip#Browse(a:path)
  call cursor(1, 1)
  call s:preview_setlocal()
endfunction
call s:new_preview_type(s:zip)

let s:tar = {
      \ 'match': '\.\(tar\|tgz\)',
      \ 'extension': 'tar',
      \ 'funconly': 1
      \ }
function! s:tar.vimfunc(path) abort
  call tar#Browse(a:path)
  call cursor(1, 1)
  call s:preview_setlocal()
endfunction
call s:new_preview_type(s:tar)

if executable('pdftotext')
  let s:pdf = {
        \ 'match': '\.\(pdf\)$',
        \ 'command': 'pdftotext -enc ASCII7 -q -eol unix -nopgbrk -raw -layout %s %s'
        \ }
  call s:new_preview_type(s:pdf)
endif

function! unite_preview#func(candidate) abort
  if filereadable(a:candidate.action__path)
    for i in range(len(s:preview_type) - 1, 0, -1)
      let type = s:preview_type[i]
      if (has_key(type, 'match') && a:candidate.word =~? type.match)
            \ || (has_key(type, 'matcher') && type.matcher(a:candidate))
        if has_key(type, 'extension')
          let extension = type.extension
        else
          let extension = s:extract_extension(a:candidate)
        endif
        call s:preview(a:candidate.action__path, type, extension)
        return
      endif
    endfor
    let extension = s:extract_extension(a:candidate)
    call s:preview_read(a:candidate.action__path, {}, extension)
  endif
endfunction

function! s:preview_read(path, type, extension) abort
  let winnr = winnr()
  let col = col('.')
  let line = line('.')
  call s:preview_window(a:extension)
  setlocal modifiable noreadonly
  silent 0r `=a:path`
  silent $ delete _
  execute 'setlocal filetype=' . get(a:type, 'filetype', '')
  doautocmd BufNewFile
  call s:set_mode_line()
  call cursor(1, 1)
  call s:preview_setlocal()
  call s:preview_restore(winnr, line, col)
endfunction

let s:preview_temp_file = tempname()
function! s:preview(path, type, extension) abort
  let fname = s:preview_temp_file
  let winnr = winnr()
  let col = col('.')
  let line = line('.')
  if has_key(a:type, 'command')
    let command = a:type.command
  elseif has_key(a:type, 'func')
    call s:preview_window(a:type.extension)
    let command = a:type.func()
    call s:preview_restore(winnr, line, col)
  elseif has_key(a:type, 'vimfunc')
    call s:preview_window(a:type.extension)
    call a:type.vimfunc(a:path)
    call s:preview_restore(winnr, line, col)
    let command = ''
  else
    let command = ''
    let fname = a:path
  endif
  if len(command)
    let c = (len(command) - len(substitute(command, '%s', '', 'g'))) / 2
    if c == 2
      let command = printf(command, shellescape(a:path), fname)
    elseif c == 1
      let command = printf(command, shellescape(a:path))
    endif
    silent! call system(command)
  endif
  if !has_key(a:type, 'funconly') || a:type.funconly == 0
    call s:preview_read(fname, a:type, a:extension)
  endif
endfunction

let s:extensionmap = {
      \ 'python': 'py',
      \ 'perl': 'pl'
      \ }

function! s:extract_extension(candidate) abort
  let ext = ''
  let firstline = join(readfile(a:candidate.action__path, '', 1), '')
  if firstline =~? '^#!'
    let ext = substitute(substitute(firstline, '^#!.*\/', '', 'g'),
          \ '^[a-z]\+ ', '', '')
    let extnonum = substitute(ext, '\d\|\.', '', 'g')
    if has_key(s:extensionmap, ext)
      let ext = s:extensionmap[ext]
    elseif has_key(s:extensionmap, extnonum)
      let ext = s:extensionmap[extnonum]
    endif
  elseif firstline =~? '^#compdef '
    let ext = 'zsh'
  elseif firstline =~? '\<xml\>'
    let ext = 'xml'
  endif
  if ext ==# ''
    let ext = has_key(a:candidate, 'vimfiler__extension')
          \ ? a:candidate.vimfiler__extension
          \ : substitute(a:candidate.word, '.*\.', '', 'g')
  endif
  return ext
endfunction

function! s:preview_setlocal() abort
  setlocal nomodifiable buftype=nofile noswapfile readonly
        \ bufhidden=hide nobuflisted
endfunction

function! s:preview_window(type) abort
  let buf = get(filter(tabpagebuflist(), 'bufname(v:val) =~? "[preview"'), 0)
  if buf == 0
    rightbelow vnew
  else
    execute bufwinnr(buf) 'wincmd w'
  endif
  let bufs = filter(flatten(map(range(1, tabpagenr('$')),
        \ 'tabpagebuflist(v:val)')), 'v:val != bufnr()')
  let i = 0
  while 1
    let name = expand('~/') . printf(
          \ '[preview%s]%s', i == 0 ? '' : ' ' . i,
          \ a:type ==# '' ? '' : '.' . a:type)
    if index(bufs, bufnr(name)) == -1 | break | endif
    let i += 1
  endwhile
  setlocal buftype=nofile noswapfile
  silent edit `=name`
  call s:preview_setlocal()
  nnoremap <buffer><silent> q :<C-u>bdelete!<CR>
  setlocal modifiable noreadonly
  silent % delete _
endfunction

function! s:preview_restore(winnr, line, col) abort
  silent execute a:winnr 'wincmd w'
  call cursor(a:line, a:col)
endfunction

function! s:set_mode_line() abort
  let end = line('$')
  let tail = getline(max([end - &modelines + 1, 1]), end)
  for line in tail
    let mlist = matchlist(line, '\%(^.*[ \t]\|^\)\%(vim\?\|ex\):[ \t]\?\(.*\)')
    if len(mlist) > 1
      let modeline = substitute(mlist[1], ':[^:]*$', '', '')
      if modeline =~? '^set\? .*'
        let command = modeline
      else
        let command = 'set ' . modeline
      endif
      try
        silent execute substitute(command, ':', ' ', 'g')
      catch
      endtry
    endif
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
