if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif


function! s:getguicolor(red, green, blue)
  return printf('\#%02x%02x%02x', a:red, a:green, a:blue)
endfunction

let s:table = [0x00, 0x5f, 0x87, 0xaf, 0xdf, 0xff]

for s:color in range(40, 47)
  let s:rgb = s:color - 40
  let s:ired = (s:rgb % 2) * 4
  let s:red = s:table[s:ired]
  let s:gb = s:rgb / 2
  let s:igreen = (s:gb % 2) * 4
  let s:green = s:table[s:igreen]
  let s:iblue = (s:gb / 2) * 4
  let s:blue = s:table[s:iblue]
  let s:guicolor = s:getguicolor(s:red, s:green, s:blue)
  execute 'syntax match Cam_'.s:color ' "\['.s:color.'m \+" contains=CamHidee'
  execute 'highlight Cam_'.s:color ' ctermbg='.s:rgb ' guibg='.s:guicolor
endfor

for s:color in range(16, 231)
  let s:rgb = s:color - 16
  let s:blue = s:table[s:rgb % 6]
  let s:rg = s:rgb / 6
  let s:green = s:table[s:rg % 6]
  let s:red = s:table[s:rg / 6]
  let s:guicolor = s:getguicolor(s:red, s:green, s:blue)
  execute 'syntax match Cam__'.s:color ' "\[48;5;'.s:color.'m \+" contains=CamHide'
  execute 'highlight Cam__'.s:color ' ctermbg='.s:color ' guibg='.s:guicolor
endfor

if has('conceal')
  syntax match CamHide '\[48;5;\d\+m' contained conceal
  syntax match CamHidee '\[\d\dm' contained conceal
  syntax match CamHideAll '\[0m' conceal
  syntax match CamHideAll '\[?25[lh]' conceal
  syntax match CamHideAll '\e' conceal
  setlocal conceallevel=3
else
  syntax match CamHide '\[48;5;\d\+m' contained
  syntax match CamHidee '\[\d\dm' contained
  syntax match CamHideAll '\[0m'
  syntax match CamHideAll '\[?25[lh]'
  syntax match CamHideAll '\e'
endif

highlight default link CamHide Ignore
highlight default link CamHideAll Ignore

setlocal nowrap
setlocal nocursorline
setlocal nocursorcolumn
setlocal synmaxcol=3000

let b:current_syntax = 'cam'

