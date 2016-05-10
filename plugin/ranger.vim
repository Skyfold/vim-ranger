" forked from 
" https://github.com/hut/ranger/blob/master/examples/vim_file_chooser.vim
"
function! s:RangerChooserForAncientVim(dirname)
    let temp = tempname()
    if has("gui_running")
        exec 'silent !xterm -e ranger --choosefiles=' . shellescape(temp) . ' ' . a:dirname
    else
        exec 'silent !ranger --choosefiles=' . shellescape(temp) . ' ' . a:dirname
    endif
    if !filereadable(temp)
        " close window if nothing to read, probably user closed ranger
        close
        redraw!
        return
    endif
    let names = readfile(temp)
    if empty(names)
        " close window if nothing to open.
        close
        redraw!
        return
    endif
    " Edit the first item.
    exec 'edit ' . fnameescape(names[0])
    filetype detect
    " open any remaning items in new tabs
    for name in names[1:]
        exec 'tabe ' . fnameescape(name)
        filetype detect
    endfor
    redraw!
endfunction

"here is a more exotic version of my original Kwbd script
"delete the buffer; keep windows; create a scratch buffer if no buffers left
function! s:Kwbd(kwbdStage)
  if(a:kwbdStage == 1)
    if(!buflisted(winbufnr(0)))
      bd!
      return
    endif
    let s:kwbdBufNum = bufnr("%")
    let s:kwbdWinNum = winnr()
    windo call s:Kwbd(2)
    execute s:kwbdWinNum . 'wincmd w'
    let s:buflistedLeft = 0
    let s:bufFinalJump = 0
    let l:nBufs = bufnr("$")
    let l:i = 1
    while(l:i <= l:nBufs)
      if(l:i != s:kwbdBufNum)
        if(buflisted(l:i))
          let s:buflistedLeft = s:buflistedLeft + 1
        else
          if(bufexists(l:i) && !strlen(bufname(l:i)) && !s:bufFinalJump)
            let s:bufFinalJump = l:i
          endif
        endif
      endif
      let l:i = l:i + 1
    endwhile
    if(!s:buflistedLeft)
      if(s:bufFinalJump)
        windo if(buflisted(winbufnr(0))) | execute "b! " . s:bufFinalJump | endif
      else
        enew
        let l:newBuf = bufnr("%")
        windo if(buflisted(winbufnr(0))) | execute "b! " . l:newBuf | endif
      endif
      execute s:kwbdWinNum . 'wincmd w'
    endif
    if(buflisted(s:kwbdBufNum) || s:kwbdBufNum == bufnr("%"))
      execute "bd! " . s:kwbdBufNum
    endif
    if(!s:buflistedLeft)
      set buflisted
      set bufhidden=delete
      set buftype=
      setlocal noswapfile
    endif
  else
    if(bufnr("%") == s:kwbdBufNum)
      let prevbufvar = bufnr("#")
      if(prevbufvar > 0 && buflisted(prevbufvar) && prevbufvar != s:kwbdBufNum)
        b #
      else
        bn
      endif
    endif
  endif
endfunction

function! s:RangerChooserForNeoVim(dirname)
    let callback = {'tempname': tempname()}
    function! callback.on_exit()
    exec s:Kwbd(1)
        try
            if filereadable(self.tempname)
                let names = readfile(self.tempname)
                exec 'edit ' . fnameescape(names[0])
                for name in names[1:]
                    exec 'tabe ' . fnameescape(name)
                endfor
            endif
        endtry
    endfunction
    let cmd = 'ranger --choosefiles='.callback.tempname.' '.shellescape(a:dirname)
    call termopen(cmd, callback)
    startinsert
endfunction

function! s:RangerChooser(dirname)
    if isdirectory(a:dirname)
        if has('nvim')
            call s:RangerChooserForNeoVim(a:dirname)
        else
            call s:RangerChooserForAncientVim(a:dirname)
        endif
    endif
endfunction

au BufEnter * silent call s:RangerChooser(expand("<amatch>"))
let g:loaded_netrwPlugin = 'disable'
