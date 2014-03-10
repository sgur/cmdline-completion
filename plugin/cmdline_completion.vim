" File:        cmdline_completion.vim
" Author:      kin9 <ljh575@gmail.com>
" Last Change: March 10, 2014
"
" Version:     0.04
"              ----- Add search in loaded buffers support .
"
"              0.03
"              ----- Add support cursor at anywhere of cmdline.
"
"
" Description: This script let you can use CTRL-P/N to complete
"              word in cmdline mode just like in insert mode.
"
"              You can use other keys instead of <C-P/N> like
"              this :
"                  cmap <C-J> <Plug>CmdlineCompletionBackward
"                  cmap <C-K> <Plug>CmdlineCompletionForward
"
" Install:     Drag this file into vim plugin directory.
"
"

if exists("g:loaded_cmdline_completion") || &cp || version < 700
  finish
endif

let g:loaded_cmdline_completion = 1

"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
" map key
"
if !hasmapto('<Plug>CmdlineCompletionBackward','c')
  cmap <unique> <silent> <C-P> <Plug>CmdlineCompletionBackward
endif

if !hasmapto('<Plug>CmdlineCompletionForward','c')
  cmap <unique> <silent> <C-N> <Plug>CmdlineCompletionForward
endif

cnoremap <silent> <Plug>CmdlineCompletionBackward
      \ <C-\>ecmdline_completion#complete_backword()<CR>
cnoremap <silent> <Plug>CmdlineCompletionForward
      \ <C-\>ecmdline_completion#complete_forward()<CR>


"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
