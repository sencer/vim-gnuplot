if exists('*s:ShowGPDoc') && g:gpdoc_perform_mappings
    call s:PerformMappings()
    finish
endif

if !exists('g:gpdoc_perform_mappings')
    let g:gpdoc_perform_mappings = 1
endif

if !exists('g:gpdoc_highlight')
    let g:gpdoc_highlight = 1
endif

if !exists('g:gpdoc_cmd')
    let g:gpdoc_cmd = 'PAGER=cat gnuplot -e help '
endif

if !exists('g:gpdoc_open_cmd')
    let g:gpdoc_open_cmd = 'split'
endif

setlocal switchbuf=useopen
highlight gpdoc cterm=reverse gui=reverse

function! s:GetWindowLine(value)
    if a:value < 1
        return float2nr(winheight(0)*a:value)
    else
        return a:value
    endif
endfunction

function! s:ShowGPDoc(name)
    if a:name == ''
        return
    endif

    if g:gpdoc_open_cmd == 'split'
        if exists('g:gpdoc_window_lines')
            let l:gpdoc_wh = s:GetWindowLine(g:gpdoc_window_lines)
        else
            let l:gpdoc_wh = 20
        endif
    endif

    if bufloaded("__doc__")
        let l:buf_is_new = 0
        if bufname("%") == "__doc__"
            " The current buffer is __doc__, thus do not
            " recreate nor resize it
            let l:gpdoc_wh = -1
        else
            " If the __doc__ buffer is open, jump to it
            if exists("g:gpdoc_use_drop")
                execute "drop" "__doc__"
            else
                execute "sbuffer" bufnr("__doc__")
            endif
            let l:gpdoc_wh = -1
        endif
    else
        let l:buf_is_new = 1
        execute g:gpdoc_open_cmd '__doc__'
        if g:gpdoc_perform_mappings
            call s:PerformMappings()
        endif
    endif

    setlocal modifiable
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal syntax=man
    setlocal nolist

    normal ggdG
    " Remove function/method arguments
    let s:name2 = substitute(a:name, '(.*', '', 'g' )
    " Remove all colons
    let s:name2 = substitute(s:name2, ':', '', 'g' )
    let s:cmd = g:gpdoc_cmd . shellescape(s:name2)
    if &verbose
        echomsg "gpdoc: calling " s:cmd
    endif
    execute  "silent read !" s:cmd
    normal 1G

    if exists('l:gpdoc_wh') && l:gpdoc_wh != -1
        execute "resize" l:gpdoc_wh
    end

    if g:gpdoc_highlight == 1
        execute 'syntax match gpdoc' "'" . s:name2 . "'"
    endif

    let l:line = getline(2)
    if l:line =~ "^no Gnuplot documentation found for.*$"
        if l:buf_is_new
            execute "bdelete!"
        else
            normal u
            setlocal nomodified
            setlocal nomodifiable
        endif
        redraw
        echohl WarningMsg | echo l:line | echohl None
    else
        setlocal nomodified
        setlocal nomodifiable
    endif
endfunction

" Mappings
function! s:PerformMappings()
    " remap the K (or 'help') key
    nnoremap <silent> <buffer> K :call <SID>ShowGPDoc(expand('<cword>'))<CR>
endfunction

if g:gpdoc_perform_mappings
    call s:PerformMappings()
endif
