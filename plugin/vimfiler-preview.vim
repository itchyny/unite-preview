" =============================================================================
" Filename: plugin/vimfiler-preview.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/31 15:10:50.
" =============================================================================

if exists('g:loaded_vimfiler_preview')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:preview = {
      \ 'description': 'auto preview',
      \ 'is_quit': 1
      \ }

function! s:preview.func(candidate)
  call vimfiler_preview#func(a:candidate)
endfunction

augroup VimfilerPreview
  autocmd!
  autocmd FileType vimfiler nnoremap <buffer><silent>
        \ <Plug>(vimfiler_auto_preview_file)
        \ :<C-u>call vimfiler#mappings#do_action('auto_preview')<CR>
  autocmd BufNewFile,BufReadPost *.cam setlocal filetype=cam
  autocmd BufNewFile,BufReadPost *.xxd setlocal filetype=xxd
augroup END

if exists('*unite#custom_action')
  call unite#custom_action('file', 'auto_preview', s:preview)
endif

let g:vimfiler_preview = s:preview

let g:loaded_vimfiler_preview = 1

let &cpo = s:save_cpo
unlet s:save_cpo
