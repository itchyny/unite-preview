" =============================================================================
" Filename: autoload/unite_preview.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/02/26 00:11:30.
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

if executable('cam')
  let s:image = {
        \ 'match': '\c\.\(jpe\?g\|png\|bmp\|ico\)$',
        \ 'extension': 'cam',
        \ }
  function! s:image.func() abort
    let width = winwidth(0) * 9 / 10
    let height = winheight(0) * 9 / 10
    " TODO: -C (center)
    let command = printf('cam -W %d -H %d', width, height)
    return command . ' %s > %s'
  endfunction
  call s:new_preview_type(s:image)
endif

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
          \ 'command': 'xxd %s > %s'
          \ }
    function! s:executable.matcher(candidate) abort
      let command = printf('file -b %s',
            \ escape(vimfiler#util#escape_file_searching(a:candidate.word), "`%'"))
      let fileb = system(command)
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
      \ 'match': 'makefile',
      \ 'filetype': 'make',
      \ }
call s:new_preview_type(s:make)

let s:make_am = {
      \ 'match': 'Makefile\.am',
      \ 'filetype': 'automake',
      \ }
call s:new_preview_type(s:make_am)

let s:config = {
      \ 'match': 'configure',
      \ 'filetype': 'config',
      \ }
call s:new_preview_type(s:config)

let s:config_h = {
      \ 'match': 'config\.h\.',
      \ 'extension': 'h',
      \ }
call s:new_preview_type(s:config_h)

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

function! s:preview_buffer() abort
  for i in tabpagebuflist()
    if bufexists(i) && bufloaded(i) && bufname(i) =~? '\[preview'
      return i
    endif
  endfor
  return -1
endfunction

function! s:preview_read(path, type, extension) abort
  let winnr = winnr()
  let col = col('.')
  let line = line('.')
  call s:preview_window(a:extension)
  setlocal modifiable noreadonly
  silent execute '0r' escape(vimfiler#util#escape_file_searching(a:path), "`%'")
  silent $ delete _
  if has_key(a:type, 'filetype')
    try
      silent execute 'setlocal filetype=' . a:type.filetype
    catch
    endtry
  endif
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
      let command = printf(command,
            \ vimfiler#util#escape_file_searching(a:path), fname)
    elseif c == 1
      let command = printf(command,
            \ vimfiler#util#escape_file_searching(a:path))
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
  let shebang = system(printf('cat %s | head -n 1 | tr -d "\n"',
        \ escape(vimfiler#util#escape_file_searching(a:candidate.word), "`%'")))
  if shebang =~? '^#!'
    let ext = substitute(substitute(shebang, '^#!.*\/', '', 'g'),
          \ '^[a-z]\+ ', '', '')
    let extnonum = substitute(ext, '\d\|\.', '', 'g')
    if has_key(s:extensionmap, ext)
      let ext = s:extensionmap[ext]
    elseif has_key(s:extensionmap, extnonum)
      let ext = s:extensionmap[extnonum]
    endif
  elseif shebang =~? '^#compdef '
    let ext = 'zsh'
  elseif shebang =~? '\<xml\>'
    let ext = 'xml'
  elseif shebang =~? '^{ '
    let lastline = system(printf('cat %s | tail -n 1 | tr -d "\n"',
          \ escape(vimfiler#util#escape_file_searching(a:candidate.word), "`%'")))
    if lastline =~? '}$'
      let ext = 'vim'
    endif
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
  " redraw
endfunction

function! s:preview_window(type) abort
  let bufnum = s:preview_buffer()
  if bufnum == -1
    silent execute 'rightb vnew'
  else
    silent execute bufwinnr(bufnum) 'wincmd w'
    silent edit `=expand('~/[preview].')`
    setlocal buftype=nofile noswapfile nobuflisted bufhidden=hide
  endif
  let buflist = []
  for i in range(tabpagenr('$'))
    call extend(buflist, tabpagebuflist(i + 1))
  endfor
  let i = 0
  let prefix = expand('~/[preview')
  let postfix = a:type ==# '' ? '' : '.' . a:type
  let name = prefix . ']' . postfix
  if index(buflist, bufnr(escape(name, '[] '))) > -1
    let template = prefix . ' %d]' . postfix
    let i += 1
    let name = printf(template, i)
    while index(buflist, bufnr(escape(name, '[] '))) > -1
      let i += 1
      let name = printf(template, i)
    endwhile
  endif
  setlocal buftype=nofile noswapfile
  try
    silent edit `=name`
  catch
  endtry
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
