
function! regopher#ParamsToStruct(bang, ...) abort
  " return with a warning if the bin doesn't exist
  let bin_path = regopher#path#CheckBinPath(regopher#config#RegopherBin())
  if empty(bin_path)
    return
  endif

  let fname = expand('%:p')
  let pos = regopher#util#OffsetCursor()
  let offset = printf('%s:#%d', fname, pos)
  let cmd = [bin_path, "-write", "params-to-struct", offset]

  if regopher#util#has_job()
    call s:params_job({
          \ 'cmd': cmd,
          \ 'bang': a:bang,
          \})
    return
  endif

  let [l:out, l:err] = regopher#tool#ExecuteInDir(l:cmd)
  call s:parse_errors(l:err, a:bang, split(l:out, '\n'), "ReGoParamsToStruct")
endfunction

function! regopher#ResultsToStruct(bang, ...) abort
  " return with a warning if the bin doesn't exist
  let bin_path = regopher#path#CheckBinPath(regopher#config#RegopherBin())
  if empty(bin_path)
    return
  endif

  let fname = expand('%:p')
  let pos = regopher#util#OffsetCursor()
  let offset = printf('%s:#%d', fname, pos)
  let cmd = [bin_path, "-write", "results-to-struct", offset]

  if regopher#util#has_job()
    call s:results_job({
          \ 'cmd': cmd,
          \ 'bang': a:bang,
          \})
    return
  endif

  let [l:out, l:err] = regopher#tool#ExecuteInDir(l:cmd)
  call s:parse_errors(l:err, a:bang, split(l:out, '\n'), "ReGoResultsToStruct")
endfunction

function s:params_job(args)
  let l:job_opts = {
        \ 'bang': a:args.bang,
        \ 'for': 'Regopher',
        \ 'statustype': 'regopher',
        \ }

  " autowrite is not enabled for jobs
  call regopher#cmd#autowrite()
  let l:cbs = regopher#job#Options(l:job_opts)

  " wrap l:cbs.exit_cb in s:exit_cb.
  let l:cbs.exit_cb = funcref('s:exit_cb', [l:cbs.exit_cb])

  call regopher#job#Start(a:args.cmd, l:cbs)
endfunction

function s:results_job(args)
  let l:job_opts = {
        \ 'bang': a:args.bang,
        \ 'for': 'Regopher',
        \ 'statustype': 'regopher',
        \ }

  " autowrite is not enabled for jobs
  call regopher#cmd#autowrite()
  let l:cbs = regopher#job#Options(l:job_opts)

  " wrap l:cbs.exit_cb in s:exit_cb.
  let l:cbs.exit_cb = funcref('s:exit_cb', [l:cbs.exit_cb])

  call regopher#job#Start(a:args.cmd, l:cbs)
endfunction

function! s:reload_changed() abort
  " reload all files to reflect the new changes. We explicitly call
  " checktime to trigger a reload of all files. See
  " http://www.mail-archive.com/vim@vim.org/msg05900.html for more info
  " about the autoread bug
  let current_autoread = &autoread
  set autoread
  silent! checktime
  let &autoread = current_autoread
endfunction

" s:exit_cb reloads any changed buffers and then calls next.
function! s:exit_cb(next, job, exitval) abort
  call s:reload_changed()
  call call(a:next, [a:job, a:exitval])
endfunction

function s:parse_errors(exit_val, bang, out, list_type)
  " reload all files to reflect the new changes. We explicitly call
  " checktime to trigger a reload of all files. See
  " http://www.mail-archive.com/vim@vim.org/msg05900.html for more info
  " about the autoread bug
  let current_autoread = &autoread
  set autoread
  silent! checktime
  let &autoread = current_autoread

  let l:listtype = regopher#list#Type(list_type)
  if a:exit_val != 0
    call regopher#util#EchoError("FAILED")
    let errors = regopher#tool#ParseErrors(a:out)
    call regopher#list#Populate(l:listtype, errors, 'Regopher')
    call regopher#list#Window(l:listtype, len(errors))
    if !empty(errors) && !a:bang
      call regopher#list#JumpToFirst(l:listtype)
    elseif empty(errors)
      " failed to parse errors, output the original content
      call regopher#util#EchoError(a:out)
    endif

    return
  endif

  " strip out newline on the end that gorename puts. If we don't remove, it
  " will trigger the 'Hit ENTER to continue' prompt
  call regopher#list#Clean(l:listtype)
  call regopher#util#EchoSuccess(a:out[0])

  " refresh the buffer so we can see the new content
  silent execute ":e"
endfunction

" Commandline completion: original, unexported camelCase, and exported
" CamelCase.
function! regopher#Complete(lead, cmdline, cursor)
  let l:word = expand('<cword>')
  return filter(uniq(sort(
        \ [l:word, regopher#util#camelcase(l:word), regopher#util#pascalcase(l:word)])),
        \ 'strpart(v:val, 0, len(a:lead)) == a:lead')
endfunction

" vim: sw=2 ts=2 et
