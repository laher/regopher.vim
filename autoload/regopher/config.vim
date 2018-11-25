function! regopher#config#AutodetectGopath() abort
	return get(g:, 'regopher_autodetect_gopath', 0)
endfunction

function! regopher#config#ListTypeCommands() abort
  return get(g:, 'regopher_list_type_commands', {})
endfunction

function! regopher#config#VersionWarning() abort
  return get(g:, 'regopher_version_warning', 1)
endfunction

function! regopher#config#TestTimeout() abort
 return get(g:, 'regopher_test_timeout', '10s')
endfunction

function! regopher#config#TestShowName() abort
  return get(g:, 'regopher_test_show_name', 0)
endfunction

function! regopher#config#TermHeight() abort
  return get(g:, 'regopher_term_height', winheight(0))
endfunction

function! regopher#config#TermWidth() abort
  return get(g:, 'regopher_term_width', winwidth(0))
endfunction

function! regopher#config#TermMode() abort
  return get(g:, 'regopher_term_mode', 'vsplit')
endfunction

function! regopher#config#TermEnabled() abort
  return get(g:, 'regopher_term_enabled', 0)
endfunction

function! regopher#config#SetTermEnabled(value) abort
  let g:regopher_term_enabled = a:value
endfunction

function! regopher#config#EchoCommandInfo() abort
  return get(g:, 'regopher_echo_command_info', 1)
endfunction

function! regopher#config#Debug() abort
  return get(g:, 'regopher_debug', [])
endfunction

function! regopher#config#ListHeight() abort
  return get(g:, "regopher_list_height", 0)
endfunction

function! regopher#config#ListType() abort
  return get(g:, 'regopher_list_type', '')
endfunction

function! regopher#config#ListAutoclose() abort
  return get(g:, 'regopher_list_autoclose', 1)
endfunction

function! regopher#config#RegopherBin() abort
  return get(g:, "regopher_bin", "regopher")
endfunction

function! regopher#config#RegopherPrefill() abort
  return get(g:, "regopher_prefill", 'expand("<cword>") =~# "^[A-Z]"' .
          \ '? regopher#util#pascalcase(expand("<cword>"))' .
          \ ': regopher#util#camelcase(expand("<cword>"))')
endfunction

function! regopher#config#BinPath() abort
  return get(g:, "regopher_bin_path", "")
endfunction

function! regopher#config#SearchBinPathFirst() abort
  return get(g:, 'regopher_search_bin_path_first', 1)
endfunction

" Set the default value. A value of "1" is a shortcut for this, for
" compatibility reasons.
if exists("g:regopher_prefill") && g:regopher_prefill == 1
  unlet g:regopher_prefill
endif

" vim: sw=2 ts=2 et
