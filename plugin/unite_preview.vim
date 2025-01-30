" =============================================================================
" Filename: plugin/unite_preview.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2025/01/30 15:21:16.
" =============================================================================

if exists('g:loaded_unite_preview') || v:version < 700
  finish
endif
let g:loaded_unite_preview = 1

let s:save_cpo = &cpo
set cpo&vim

let s:preview = { 'description': 'auto preview', 'is_quit': 1 }

function! s:preview.func(candidate)
  call unite_preview#func(a:candidate)
endfunction

call unite#custom_action('file', 'auto_preview', s:preview)
let g:vimfiler_preview_action = 'auto_preview'

let &cpo = s:save_cpo
unlet s:save_cpo
