" =============================================================================
" Filename: plugin/unite-preview.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2014/04/25 10:32:48.
" =============================================================================

if exists('g:loaded_unite_preview')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:preview = { 'description': 'auto preview', 'is_quit': 1 }

function! s:preview.func(candidate)
  call unite_preview#func(a:candidate)
endfunction

augroup UnitePreview
  autocmd!
  autocmd BufNewFile,BufReadPost *.cam setlocal filetype=cam
  autocmd BufNewFile,BufReadPost *.xxd setlocal filetype=xxd
augroup END

call unite#custom_action('file', 'auto_preview', s:preview)
let g:vimfiler_preview_action = 'auto_preview'

let g:loaded_unite_preview = 1

let &cpo = s:save_cpo
unlet s:save_cpo
