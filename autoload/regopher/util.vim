" PathSep returns the appropriate OS specific path separator.
function! regopher#util#PathSep() abort
  if regopher#util#IsWin()
    return '\'
  endif
  return '/'
endfunction

" PathListSep returns the appropriate OS specific path list separator.
function! regopher#util#PathListSep() abort
  if regopher#util#IsWin()
    return ";"
  endif
  return ":"
endfunction

" LineEnding returns the correct line ending, based on the current fileformat
function! regopher#util#LineEnding() abort
  if &fileformat == 'dos'
    return "\r\n"
  elseif &fileformat == 'mac'
    return "\r"
  endif

  return "\n"
endfunction

" Join joins any number of path elements into a single path, adding a
" Separator if necessary and returns the result
function! regopher#util#Join(...) abort
  return join(a:000, regopher#util#PathSep())
endfunction

" IsWin returns 1 if current OS is Windows or 0 otherwise
function! regopher#util#IsWin() abort
  let win = ['win16', 'win32', 'win64', 'win95']
  for w in win
    if (has(w))
      return 1
    endif
  endfor

  return 0
endfunction

" IsMac returns 1 if current OS is macOS or 0 otherwise.
function! regopher#util#IsMac() abort
  return has('mac') ||
        \ has('macunix') ||
        \ has('gui_macvim') ||
        \ regopher#util#Exec(['uname'])[0] =~? '^darwin'
endfunction

 " Checks if using:
 " 1) Windows system,
 " 2) And has cygpath executable,
 " 3) And uses *sh* as 'shell'
function! regopher#util#IsUsingCygwinShell()
  return regopher#util#IsWin() && executable('cygpath') && &shell =~ '.*sh.*'
endfunction

" Check if Vim jobs API is supported.
"
" The (optional) first parameter can be added to indicate the 'cwd' or 'env'
" parameters will be used, which wasn't added until a later version.
function! regopher#util#has_job(...) abort
  if has('nvim')
    return 1
  endif

  " cwd and env parameters to job_start was added in this version.
  if a:0 > 0 && a:1 is 1
    return has('job') && has("patch-8.0.0902")
  endif

  " job was introduced in 7.4.xxx however there are multiple bug fixes and one
  " of the latest is 8.0.0087 which is required for a stable async API.
  return has('job') && has("patch-8.0.0087")
endfunction

let s:env_cache = {}

" env returns the go environment variable for the given key. Where key can be
" GOARCH, GOOS, GOROOT, etc... It caches the result and returns the cached
" version.
function! regopher#util#env(key) abort
  let l:key = tolower(a:key)
  if has_key(s:env_cache, l:key)
    return s:env_cache[l:key]
  endif

  if executable('go')
    let l:var = call('regopher#util#'.l:key, [])
    if regopher#util#ShellError() != 0
      call regopher#util#EchoError(printf("'go env %s' failed", toupper(l:key)))
      return ''
    endif
  else
    let l:var = eval("$".toupper(a:key))
  endif

  let s:env_cache[l:key] = l:var
  return l:var
endfunction

" goarch returns 'go env GOARCH'. This is an internal function and shouldn't
" be used. Instead use 'regopher#util#env("goarch")'
function! regopher#util#goarch() abort
  return substitute(s:exec(['go', 'env', 'GOARCH'])[0], '\n', '', 'g')
endfunction

" goos returns 'go env GOOS'. This is an internal function and shouldn't
" be used. Instead use 'regopher#util#env("goos")'
function! regopher#util#goos() abort
  return substitute(s:exec(['go', 'env', 'GOOS'])[0], '\n', '', 'g')
endfunction

" goroot returns 'go env GOROOT'. This is an internal function and shouldn't
" be used. Instead use 'regopher#util#env("goroot")'
function! regopher#util#goroot() abort
  return substitute(s:exec(['go', 'env', 'GOROOT'])[0], '\n', '', 'g')
endfunction

" gopath returns 'go env GOPATH'. This is an internal function and shouldn't
" be used. Instead use 'regopher#util#env("gopath")'
function! regopher#util#gopath() abort
  return substitute(s:exec(['go', 'env', 'GOPATH'])[0], '\n', '', 'g')
endfunction

" gomod returns 'go env GOMOD'. gomod changes depending on the folder. Don't
" use regopher#util#env as it caches the value.
function! regopher#util#gomod() abort
  return substitute(s:exec(['go', 'env', 'GOMOD'])[0], '\n', '', 'g')
endfunction


function! regopher#util#osarch() abort
  return regopher#util#env("goos") . '_' . regopher#util#env("goarch")
endfunction

" Run a shell command.
"
" It will temporary set the shell to /bin/sh for Unix-like systems if possible,
" so that we always use a standard POSIX-compatible Bourne shell (and not e.g.
" csh, fish, etc.) See #988 and #1276.
function! s:system(cmd, ...) abort
  " Preserve original shell, shellredir and shellcmdflag values
  let l:shell = &shell
  let l:shellredir = &shellredir
  let l:shellcmdflag = &shellcmdflag

  if !regopher#util#IsWin() && executable('/bin/sh')
      set shell=/bin/sh shellredir=>%s\ 2>&1 shellcmdflag=-c
  endif

  try
    return call('system', [a:cmd] + a:000)
  finally
    " Restore original values
    let &shell = l:shell
    let &shellredir = l:shellredir
    let &shellcmdflag = l:shellcmdflag
  endtry
endfunction

" System runs a shell command "str". Every arguments after "str" is passed to
" stdin.
function! regopher#util#System(str, ...) abort
  return call('s:system', [a:str] + a:000)
endfunction

" Exec runs a shell command "cmd", which must be a list, one argument per item.
" Every list entry will be automatically shell-escaped
" Every other argument is passed to stdin.
function! regopher#util#Exec(cmd, ...) abort
  if len(a:cmd) == 0
    call regopher#util#EchoError("regopher#util#Exec() called with empty a:cmd")
    return ['', 1]
  endif

  let l:bin = a:cmd[0]

  " Lookup the full path, respecting settings such as 'go_bin_path'. On errors,
  " CheckBinPath will show a warning for us.
  let l:bin = regopher#path#CheckBinPath(l:bin)
  if empty(l:bin)
    return ['', 1]
  endif

  " Finally execute the command using the full, resolved path. Do not pass the
  " unmodified command as the correct program might not exist in $PATH.
  return call('s:exec', [[l:bin] + a:cmd[1:]] + a:000)
endfunction

function! s:exec(cmd, ...) abort
  let l:bin = a:cmd[0]
  let l:cmd = regopher#util#Shelljoin([l:bin] + a:cmd[1:])
  if regopher#util#HasDebug('shell-commands')
    call regopher#util#EchoInfo('shell command: ' . l:cmd)
  endif

  let l:out = call('s:system', [l:cmd] + a:000)
  return [l:out, regopher#util#ShellError()]
endfunction

function! regopher#util#ShellError() abort
  return v:shell_error
endfunction

" StripPath strips the path's last character if it's a path separator.
" example: '/foo/bar/'  -> '/foo/bar'
function! regopher#util#StripPathSep(path) abort
  let last_char = strlen(a:path) - 1
  if a:path[last_char] == regopher#util#PathSep()
    return strpart(a:path, 0, last_char)
  endif

  return a:path
endfunction

" StripTrailingSlash strips the trailing slash from the given path list.
" example: ['/foo/bar/']  -> ['/foo/bar']
function! regopher#util#StripTrailingSlash(paths) abort
  return map(copy(a:paths), 'regopher#util#StripPathSep(v:val)')
endfunction

" Shelljoin returns a shell-safe string representation of arglist. The
" {special} argument of shellescape() may optionally be passed.
function! regopher#util#Shelljoin(arglist, ...) abort
  try
    let ssl_save = &shellslash
    set noshellslash
    if a:0
      return join(map(copy(a:arglist), 'shellescape(v:val, ' . a:1 . ')'), ' ')
    endif

    return join(map(copy(a:arglist), 'shellescape(v:val)'), ' ')
  finally
    let &shellslash = ssl_save
  endtry
endfunction

fu! regopher#util#Shellescape(arg)
  try
    let ssl_save = &shellslash
    set noshellslash
    return shellescape(a:arg)
  finally
    let &shellslash = ssl_save
  endtry
endf

" Shelllist returns a shell-safe representation of the items in the given
" arglist. The {special} argument of shellescape() may optionally be passed.
function! regopher#util#Shelllist(arglist, ...) abort
  try
    let ssl_save = &shellslash
    set noshellslash
    if a:0
      return map(copy(a:arglist), 'shellescape(v:val, ' . a:1 . ')')
    endif
    return map(copy(a:arglist), 'shellescape(v:val)')
  finally
    let &shellslash = ssl_save
  endtry
endfunction

" Returns the byte offset for line and column
function! regopher#util#Offset(line, col) abort
  if &encoding != 'utf-8'
    let sep = regopher#util#LineEnding()
    let buf = a:line == 1 ? '' : (join(getline(1, a:line-1), sep) . sep)
    let buf .= a:col == 1 ? '' : getline('.')[:a:col-2]
    return len(iconv(buf, &encoding, 'utf-8'))
  endif
  return line2byte(a:line) + (a:col-2)
endfunction
"
" Returns the byte offset for the cursor
function! regopher#util#OffsetCursor() abort
  return regopher#util#Offset(line('.'), col('.'))
endfunction

" Windo is like the built-in :windo, only it returns to the window the command
" was issued from
function! regopher#util#Windo(command) abort
  let s:currentWindow = winnr()
  try
    execute "windo " . a:command
  finally
    execute s:currentWindow. "wincmd w"
    unlet s:currentWindow
  endtry
endfunction

" snippetcase converts the given word to given preferred snippet setting type
" case.
function! regopher#util#snippetcase(word) abort
  let l:snippet_case = regopher#config#AddtagsTransform()
  if l:snippet_case == "snakecase"
    return regopher#util#snakecase(a:word)
  elseif l:snippet_case == "camelcase"
    return regopher#util#camelcase(a:word)
  else
    return a:word " do nothing
  endif
endfunction

" snakecase converts a string to snake case. i.e: FooBar -> foo_bar
" Copied from tpope/vim-abolish
function! regopher#util#snakecase(word) abort
  let word = substitute(a:word, '::', '/', 'g')
  let word = substitute(word, '\(\u\+\)\(\u\l\)', '\1_\2', 'g')
  let word = substitute(word, '\(\l\|\d\)\(\u\)', '\1_\2', 'g')
  let word = substitute(word, '[.-]', '_', 'g')
  let word = tolower(word)
  return word
endfunction

" camelcase converts a string to camel case. e.g. FooBar or foo_bar will become
" fooBar.
" Copied from tpope/vim-abolish.
function! regopher#util#camelcase(word) abort
  let word = substitute(a:word, '-', '_', 'g')
  if word !~# '_' && word =~# '\l'
    return substitute(word, '^.', '\l&', '')
  else
    return substitute(word, '\C\(_\)\=\(.\)', '\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfunction

" pascalcase converts a string to 'PascalCase'. e.g. fooBar or foo_bar will
" become FooBar.
function! regopher#util#pascalcase(word) abort
  let word = regopher#util#camelcase(a:word)
  return toupper(word[0]) . word[1:]
endfunction

" Echo a message to the screen and highlight it with the group in a:hi.
"
" The message can be a list or string; every line with be :echomsg'd separately.
function! s:echo(msg, hi)
  let l:msg = []
  if type(a:msg) != type([])
    let l:msg = split(a:msg, "\n")
  else
    let l:msg = a:msg
  endif

  " Tabs display as ^I or <09>, so manually expand them.
  let l:msg = map(l:msg, 'substitute(v:val, "\t", "        ", "")')

  exe 'echohl ' . a:hi
  for line in l:msg
    echom "regopher.vim: " . line
  endfor
  echohl None
endfunction

function! regopher#util#EchoSuccess(msg)
  call s:echo(a:msg, 'Function')
endfunction
function! regopher#util#EchoError(msg)
  call s:echo(a:msg, 'ErrorMsg')
endfunction
function! regopher#util#EchoWarning(msg)
  call s:echo(a:msg, 'WarningMsg')
endfunction
function! regopher#util#EchoProgress(msg)
  redraw
  call s:echo(a:msg, 'Identifier')
endfunction
function! regopher#util#EchoInfo(msg)
  call s:echo(a:msg, 'Debug')
endfunction

" Get all lines in the buffer as a a list.
function! regopher#util#GetLines()
  let buf = getline(1, '$')
  if &encoding != 'utf-8'
    let buf = map(buf, 'iconv(v:val, &encoding, "utf-8")')
  endif
  if &l:fileformat == 'dos'
    " XXX: line2byte() depend on 'fileformat' option.
    " so if fileformat is 'dos', 'buf' must include '\r'.
    let buf = map(buf, 'v:val."\r"')
  endif
  return buf
endfunction

" Convert the current buffer to the "archive" format of
" golang.org/x/tools/go/buildutil:
" https://godoc.org/golang.org/x/tools/go/buildutil#ParseOverlayArchive
"
" > The archive consists of a series of files. Each file consists of a name, a
" > decimal file size and the file contents, separated by newlinews. No newline
" > follows after the file contents.
function! regopher#util#archive()
    let l:buffer = join(regopher#util#GetLines(), "\n")
    return expand("%:p:gs!\\!/!") . "\n" . strlen(l:buffer) . "\n" . l:buffer
endfunction

" Make a named temporary directory which starts with "prefix".
"
" Unfortunately Vim's tempname() is not portable enough across various systems;
" see: https://github.com/mattn/vim-go/pull/3#discussion_r138084911
function! regopher#util#tempdir(prefix) abort
  " See :help tempfile
  if regopher#util#IsWin()
    let l:dirs = [$TMP, $TEMP, 'c:\tmp', 'c:\temp']
  else
    let l:dirs = [$TMPDIR, '/tmp', './', $HOME]
  endif

  let l:dir = ''
  for l:d in dirs
    if !empty(l:d) && filewritable(l:d) == 2
      let l:dir = l:d
      break
    endif
  endfor

  if l:dir == ''
    call regopher#util#EchoError('Unable to find directory to store temporary directory in')
    return
  endif

  " Not great randomness, but "good enough" for our purpose here.
  let l:rnd = sha256(printf('%s%s', localtime(), fnamemodify(bufname(''), ":p")))
  let l:tmp = printf("%s/%s%s", l:dir, a:prefix, l:rnd)
  call mkdir(l:tmp, 'p', 0700)
  return l:tmp
endfunction

" Report if the user enabled a debug flag in g:regopher_debug.
function! regopher#util#HasDebug(flag)
  return index(regopher#config#Debug(), a:flag) >= 0
endfunction

" vim: sw=2 ts=2 et
