" vim:sw=2:
" ============================================================================
" FileName: floatwin.vim
" Author: voldikss <dyzplus@gmail.com>
" GitHub: https://github.com/voldikss
" ============================================================================

" winid: floaterm window id
function! s:add_border(winid, title) abort
  let win_opts = nvim_win_get_config(a:winid)
  let top = g:floaterm_borderchars[4] .
          \ repeat(g:floaterm_borderchars[0], win_opts.width) .
          \ g:floaterm_borderchars[5]
  let mid = g:floaterm_borderchars[3] .
          \ repeat(' ', win_opts.width) .
          \ g:floaterm_borderchars[1]
  let bot = g:floaterm_borderchars[7] .
          \ repeat(g:floaterm_borderchars[2], win_opts.width) .
          \ g:floaterm_borderchars[6]
  let top = floaterm#util#string_compose(top, 1, a:title)
  let lines = [top] + repeat([mid], win_opts.height) + [bot]
  let buf_opts = {}
  let buf_opts.synmaxcol = 3000 " #17
  let buf_opts.filetype = 'floaterm_border'
  let border_bufnr = floaterm#buffer#create(lines, buf_opts)
  call nvim_buf_set_option(border_bufnr, 'bufhidden', 'wipe')
  let win_opts.row -= (win_opts.anchor[0] == 'N' ? 1 : -1)
  " adjust offset
  if win_opts.row < 0
    let win_opts.row = 1
    call nvim_win_set_config(a:winid, win_opts)
    let win_opts.row = 0
  endif
  let win_opts.col -= (win_opts.anchor[1] == 'W' ? 1 : -1)
  let win_opts.width += 2
  let win_opts.height += 2
  let win_opts.style = 'minimal'
  let win_opts.focusable = v:false
  let border_winid = nvim_open_win(border_bufnr, v:false, win_opts)
  call nvim_win_set_option(border_winid, 'winhl', 'NormalFloat:FloatermBorder')
  return border_winid
endfunction

function! s:build_title(bufnr) abort
  let buffers = floaterm#buflist#gather()
  let cnt = len(buffers)
  let idx = index(buffers, a:bufnr) + 1
  return printf(' floaterm: %s/%s ', idx, cnt)
endfunction

function! s:floatwin_pos(width, height, pos) abort
  if a:pos == 'topright'
    let row = 2
    let col = &columns - 1
    let anchor = 'NE'
  elseif a:pos == 'topleft'
    let row = 2
    let col = 1
    let anchor = 'NW'
  elseif a:pos == 'bottomright'
    let row = &lines - 3
    let col = &columns - 1
    let anchor = 'SE'
  elseif a:pos == 'bottomleft'
    let row = &lines - 3
    let col = 1
    let anchor = 'SW'
  elseif a:pos == 'top'
    let row = 2
    let col = (&columns - a:width)/2
    let anchor = 'NW'
  elseif a:pos == 'right'
    let row = (&lines - a:height)/2
    let col = &columns - 1
    let anchor = 'NE'
  elseif a:pos == 'bottom'
    let row = &lines - 3
    let col = (&columns - a:width)/2
    let anchor = 'SW'
  elseif a:pos == 'left'
    let row = (&lines - a:height)/2
    let col = 1
    let anchor = 'NW'
  elseif a:pos == 'center'
    let row = (&lines - a:height)/2
    let col = (&columns - a:width)/2
    let anchor = 'NW'
    if row < 0
      let row = 0
    endif
    if col < 0
      let col = 0
    endif
  else " at the cursor place
    let curr_pos = getpos('.')
    let row = curr_pos[1] - line('w0')
    let col = curr_pos[2]
    if row + a:height <= &lines
      let vert = 'N'
    else
      let vert = 'S'
    endif
    if col + a:width <= &columns
      let hor = 'W'
    else
      let hor = 'E'
    endif
    let anchor = vert . hor
  endif
  if !has('nvim')
    let anchor = substitute(anchor, '\CN', 'top', '')
    let anchor = substitute(anchor, '\CS', 'bot', '')
    let anchor = substitute(anchor, '\CW', 'left', '')
    let anchor = substitute(anchor, '\CE', 'right', '')
  endif
  return [row, col, anchor]
endfunction

function! s:winexists(winid) abort
  return !empty(getwininfo(a:winid))
endfunction

function! floaterm#window#open_floating(bufnr, width, height, pos) abort
  let [row, col, anchor] = s:floatwin_pos(a:width, a:height, a:pos)
  let opts = {
    \ 'relative': 'editor',
    \ 'anchor': anchor,
    \ 'row': row,
    \ 'col': col,
    \ 'width': a:width,
    \ 'height': a:height,
    \ 'style':'minimal'
    \ }
  let winid = nvim_open_win(a:bufnr, v:true, opts)
  let border_winid = getbufvar(a:bufnr, 'floaterm_border_winid', v:null)
  if border_winid == v:null || !s:winexists(border_winid)
    let title = s:build_title(a:bufnr)
    let border_winid = s:add_border(winid, title)
    call setbufvar(a:bufnr, 'floaterm_border_winid', border_winid)
  endif
  call setbufvar(a:bufnr, 'floaterm_window_type', 'floating')
  return winid
endfunction

function! floaterm#window#open_popup(bufnr, width, height, pos) abort
  let [row, col, anchor] = s:floatwin_pos(a:width, a:height, a:pos)
  let width =  a:width
  let height =  a:height
  let opts = {
    \ 'pos': anchor,
    \ 'line': row,
    \ 'col': col,
    \ 'maxwidth': width,
    \ 'minwidth': width,
    \ 'maxheight': height,
    \ 'minheight': height,
    \ 'border': [1, 1, 1, 1],
    \ 'borderchars': g:floaterm_borderchars,
    \ 'borderhighlight': ['FloatermBorder'],
    \ 'padding': [0,1,0,1],
    \ 'highlight': 'Floaterm'
    \ }
  let opts.title = s:build_title(a:bufnr)
  let opts.zindex = len(floaterm#buflist#gather()) + 1
  let winid = popup_create(a:bufnr, opts)
  call setbufvar(winbufnr(winid), '&filetype', 'floaterm')
  " refer: floaterm#window#hide_floaterm()
  call setbufvar(a:bufnr, 'floaterm_window_type', 'popup')
  return winid
endfunction

function! floaterm#window#open_split(bufnr, height, width, pos) abort
  if a:pos == 'top'
    execute 'topleft' . a:height . 'split'
  elseif a:pos == 'left'
    execute 'topleft' . a:width . 'vsplit'
  elseif a:pos == 'right'
    execute 'botright' . a:width . 'vsplit'
  else " default position: bottom
    execute 'botright' . a:height . 'split'
  endif
  wincmd J
  enew
  call setbufvar(a:bufnr, 'floaterm_window_type', 'normal')
  return win_getid()
endfunction

function! floaterm#window#hide_floaterm_border(bufnr, ...) abort
  let winid = getbufvar(a:bufnr, 'floaterm_border_winid', v:null)
  if winid != v:null && s:winexists(winid)
    call nvim_win_close(winid, v:true)
  endif
  call setbufvar(a:bufnr, 'floaterm_border_winid', v:null)
endfunction

function! floaterm#window#hide_floaterm(bufnr) abort
  let winid = getbufvar(a:bufnr, 'floaterm_window_id')
  if has('nvim')
    if !s:winexists(winid)
      return
    endif
    call nvim_win_close(winid, v:true)
  elseif getbufvar(a:bufnr, 'floaterm_window_type', '') == 'popup'
    call popup_close(winid)
  else
    hide
  endif
endfunction

" Find **one** floaterm window
function! floaterm#window#find_floaterm_winnr() abort
  let found_winnr = 0
  for winnr in range(1, winnr('$'))
    if getbufvar(winbufnr(winnr), '&filetype') ==# 'floaterm'
      let found_winnr = winnr
      break
    endif
  endfor
  return found_winnr
endfunction
