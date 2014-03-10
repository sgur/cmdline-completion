let s:save_cpo = &cpo
set cpo&vim


function! cmdline_completion#complete_backword()
  return s:CmdlineCompletion(1)
endfunction


function! cmdline_completion#complete_forward()
  return s:CmdlineCompletion(0)
endfunction


"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
" auto completion function ,
" return new cmdline with matched word
function! s:CmdlineCompletion(backword)

  let cmdline = getcmdline()
  let cmdpos = getcmdpos() - 1

  let cmdline_tail = strpart(cmdline, cmdpos)
  let cmdline = strpart(cmdline,0,cmdpos)

  let index = match(cmdline, '\w\+$')
  let cmd = strpart(cmdline, 0, index)

  " Not a word , skip completion
  if index < 0
    return cmdline . cmdline_tail
  endif

  " s:vars initial if first time or changed cmdline.
  if !exists("b:cmdline_complete") || cmdline != b:cmdline_complete.newcmdline
    let b:cmdline_complete = {}
    let b:cmdline_complete.word_prefix = strpart(cmdline, index)
    let b:cmdline_complete.word_list = [b:cmdline_complete.word_prefix]
    let b:cmdline_complete.word_index = 0
    let b:cmdline_complete.newcmdline = ""
    let b:cmdline_complete.pos_forward = [0,0]
    let b:cmdline_complete.pos_backward = [0,0]
    let b:cmdline_complete.search_status = 0
    let b:cmdline_complete.search_time = ''
    let b:cmdline_complete.buffer_index = 1
    let b:cmdline_complete.buffer_pos = [1,0]
    let b:cmdline_complete.search_status_current = 1
    if version >= 702
      let b:cmdline_complete.search_total_time = 0
    endif
  endif

  "
  if a:backword
    let b:cmdline_complete.word_index -= 1
  else
    let b:cmdline_complete.word_index += 1
  endif

  " try to search new word if index out of list range
  if ( b:cmdline_complete.word_index < 0 || b:cmdline_complete.word_index >= len(b:cmdline_complete.word_list))
        \ && b:cmdline_complete.buffer_index <= bufnr('$')

    let start = reltime()

    while b:cmdline_complete.buffer_index <= bufnr('$')

      " search current first .
      if b:cmdline_complete.search_status_current
        let save_cursor = getpos('.')
        let b:cmdline_complete.search_status_current = s:SearchCurrent(a:backword)
        call setpos('.', save_cursor)
        if  b:cmdline_complete.search_status_current
          break
        endif

        "
        " search other buffers .
      else
        if b:cmdline_complete.buffer_index == bufnr('%')
          let b:cmdline_complete.buffer_index += 1
          continue
        endif
        let b:cmdline_complete.search_status =
              \ s:SearchBuffer(a:backword,b:cmdline_complete.buffer_index)
        if b:cmdline_complete.search_status
          break
        else
          let b:cmdline_complete.buffer_index += 1
          let b:cmdline_complete.buffer_pos = [1,0]
        endif
      endif

    endwhile


    let b:cmdline_complete.search_time = reltimestr(reltime(start))
    if version >= 702
      let b:cmdline_complete.search_total_time += str2float(b:cmdline_complete.search_time)
    endif
  endif

  " correct index
  if b:cmdline_complete.search_status || b:cmdline_complete.search_status_current
    if b:cmdline_complete.word_index < 0
      let b:cmdline_complete.word_index = 0
    endif
  else
    if b:cmdline_complete.word_index < 0
      let b:cmdline_complete.word_index = len(b:cmdline_complete.word_list) - 1
    elseif b:cmdline_complete.word_index >= len(b:cmdline_complete.word_list)
      let b:cmdline_complete.word_index = 0
    endif
  endif

  " get word from list
  let word = get(b:cmdline_complete.word_list, b:cmdline_complete.word_index, b:cmdline_complete.word_prefix)

  " new cmdline
  let b:cmdline_complete.newcmdline = cmd . word

  " overcome map silent
  call feedkeys(" \<bs>")

  " set new cmdline cursor postion
  call setcmdpos(len(b:cmdline_complete.newcmdline)+1)

  return  b:cmdline_complete.newcmdline . cmdline_tail

endfunction


"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
" search completion matched word,
" return 0 if match none, else return 1 .
function! s:SearchCurrent(backward)

  let position = a:backward ? b:cmdline_complete.pos_backward : b:cmdline_complete.pos_forward

  " set last search position
  call cursor(position)

  " search ...
  let pattern = '\<' . b:cmdline_complete.word_prefix . '\w\+\>'
  let flag = a:backward ? 'web' : 'we'

  " loop search until match unique or none
  let position = searchpos(pattern, flag)
  while position != [0,0]

    if a:backward
      let b:cmdline_complete.pos_backward = position
    else
      let b:cmdline_complete.pos_forward = position
    endif

    if b:cmdline_complete.pos_forward == [0,0] || b:cmdline_complete.pos_backward == [0,0]
      " store first match position
      let b:cmdline_complete.pos_forward = position
      let b:cmdline_complete.pos_backward = position
    elseif b:cmdline_complete.pos_forward == b:cmdline_complete.pos_backward
      " wrapscan around the whole file
      return 0
    endif

    " get matched word under cursor
    let word = expand("<cword>")

    " add to list if not exists
    if count(b:cmdline_complete.word_list, word) == 0
      if a:backward
        call insert(b:cmdline_complete.word_list, word)
      else
        call add(b:cmdline_complete.word_list, word)
      endif
      return 1
    endif

    " search again
    let position = searchpos(pattern, flag)

  endwhile

  return 0

endfunction

"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
" search other buffers
" return 0 if match none, else return 1 .
function! s:SearchBuffer(backward,bufindex)

  let pattern = '\<' . b:cmdline_complete.word_prefix . '\w\+\>'

  while 1

    " get one line at once
    let bufline = getbufline(a:bufindex, b:cmdline_complete.buffer_pos[0])

    " Eof detected !
    if len(bufline) == 0
      return 0
    endif

    " start @ last position
    let text = strpart(bufline[0],b:cmdline_complete.buffer_pos[1])
    let word = matchstr(text,pattern)

    if word == ""
      let b:cmdline_complete.buffer_pos = [b:cmdline_complete.buffer_pos[0]+1,0]
    else
      let b:cmdline_complete.buffer_pos[1] += matchend(text,pattern)
      " add to list if not exists
      if count(b:cmdline_complete.word_list, word) == 0
        if a:backward
          call insert(b:cmdline_complete.word_list, word)
        else
          call add(b:cmdline_complete.word_list, word)
        endif
        return 1
      endif
    endif

  endwhile

  return 0

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
