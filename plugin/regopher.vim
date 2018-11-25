" install necessary Go tools
if exists("g:regopher_loaded_install")
  finish
endif
let g:regopher_loaded_install = 1

function! s:checkVersion() abort
  " Not using the has('patch-7.4.2009') syntax because that wasn't added until
  " 7.4.237, and we want to be sure this works for everyone (this is also why
  " we're not using utils#EchoError()).
  "
  " Version 7.4.2009 was chosen because that's greater than what the most recent Ubuntu LTS
  " release (16.04) uses and has a couple of features we need (e.g. execute()
  " and :message clear).

  let l:unsupported = 0
  if regopher#config#VersionWarning() != 0
    if has('nvim')
      let l:unsupported = !has('nvim-0.3.1')
    else
      let l:unsupported = (v:version < 800)
    endif

    if l:unsupported == 1
      echohl Error
      echom "regopher.vim requires Vim 8 or Neovim 0.3.1, but you're using an older version."
      echom "Please update your Vim for the best regopher.vim experience."
      echom "If you really want to continue you can set this to make the error go away:"
      echom "    let g:regopher_version_warning = 0"
      echom "Note that some features may error out or behave incorrectly."
      echom "Please do not report bugs unless you're using Vim 8 or newer or Neovim 0.3.1."
      echohl None

      " Make sure people see this.
      sleep 2
    endif
  endif
endfunction

call s:checkVersion()

" these packages are used by regopher.vim and can be automatically installed if
" needed by the user with ReGoUpdate.
let s:packages = {
      \ 'regopher':         ['github.com/laher/regopher'],
\ }

" These commands are available on any filetypes
command! -nargs=* -complete=customlist,s:complete ReGoInstall call s:RegopherInstall(-1, <f-args>)
command! -nargs=* -complete=customlist,s:complete ReGoUpdate  call s:RegopherInstall(1, <f-args>)
command! -nargs=? -complete=dir GoPath call regopher#path#GoPath(<f-args>)


fun! s:complete(lead, cmdline, cursor)
  return filter(keys(s:packages), 'strpart(v:val, 0, len(a:lead)) == a:lead')
endfun

" s:RegopherInstall downloads and installs binaries defined in s:packages to
" $GOBIN or $GOPATH/bin. s:RegopherInstall will update already installed
" binaries only if updateBinaries = 1. By default, all packages in s:packages
" will be installed, but the set can be limited by passing the desired
" packages in the unnamed arguments.
function! s:RegopherInstall(updateBinaries, ...)
  let err = s:CheckBinaries()
  if err != 0
    return
  endif

  if regopher#path#Default() == ""
    echohl Error
    echomsg "vim.go: $GOPATH is not set and 'go env GOPATH' returns empty"
    echohl None
    return
  endif

  let go_bin_path = regopher#path#BinPath()

  " change $GOBIN so go get can automatically install to it
  let $GOBIN = go_bin_path

  " old_path is used to restore users own path
  let old_path = $PATH

  " vim's executable path is looking in PATH so add our go_bin path to it
  let $PATH = go_bin_path . regopher#util#PathListSep() . $PATH

  " when shellslash is set on MS-* systems, shellescape puts single quotes
  " around the output string. cmd on Windows does not handle single quotes
  " correctly. Unsetting shellslash forces shellescape to use double quotes
  " instead.
  let resetshellslash = 0
  if has('win32') && &shellslash
    let resetshellslash = 1
    set noshellslash
  endif

  let l:dl_cmd = ['go', 'get', '-v', '-d']
  if get(g:, "regopher_go_get_update", 1) != 0 " copied from vim-go, this is to allow people to stop updating misbehaving dependencies
    let l:dl_cmd += ['-u']
  endif

  " Filter packages from arguments (if any).
  let l:packages = {}
  if a:0 > 0
    for l:bin in a:000
      let l:pkg = get(s:packages, l:bin, [])
      if len(l:pkg) == 0
        call regopher#util#EchoError('unknown binary: ' . l:bin)
        return
      endif
      let l:packages[l:bin] = l:pkg
    endfor
  else
    let l:packages = s:packages
  endif

  let l:platform = ''
  if regopher#util#IsWin()
    let l:platform = 'windows'
  endif

  for [binary, pkg] in items(l:packages)
    let l:importPath = pkg[0]

    let l:run_cmd = copy(l:dl_cmd)
    if len(l:pkg) > 1 && get(l:pkg[1], l:platform, '') isnot ''
      let l:run_cmd += get(l:pkg[1], l:platform, '')
    endif

    let bin_setting_name = "go_" . binary . "_bin"

    if exists("g:{bin_setting_name}")
      let bin = g:{bin_setting_name}
    else
      if regopher#util#IsWin()
        let bin = binary . '.exe'
      else
        let bin = binary
      endif
    endif

    if !executable(bin) || a:updateBinaries == 1
      if a:updateBinaries == 1
        echo "regopher.vim: Updating " . binary . ". Reinstalling ". importPath . " to folder " . go_bin_path
      else
        echo "regopher.vim: ". binary ." not found. Installing ". importPath . " to folder " . go_bin_path
      endif

      " first download the binary
      let [l:out, l:err] = regopher#util#Exec(l:run_cmd + [l:importPath])
      if l:err
        echom "Error downloading " . l:importPath . ": " . l:out
      endif

      " and then build and install it
      let l:build_cmd = ['go', 'build', '-o', go_bin_path . regopher#util#PathSep() . bin, l:importPath]
      let [l:out, l:err] = regopher#util#Exec(l:build_cmd + [l:importPath])
      if l:err
        echom "Error installing " . l:importPath . ": " . l:out
      endif
    endif
  endfor

  " restore back!
  let $PATH = old_path
  if resetshellslash
    set shellslash
  endif

  if a:updateBinaries == 1
    call regopher#util#EchoInfo('updating finished!')
  else
    call regopher#util#EchoInfo('installing finished!')
  endif
endfunction

" CheckBinaries checks if the necessary binaries to install the Go tool
" commands are available.
function! s:CheckBinaries()
  if !executable('go')
    echohl Error | echomsg "regopher.vim: go executable not found." | echohl None
    return -1
  endif

  if !executable('git')
    echohl Error | echomsg "regopher.vim: git executable not found." | echohl None
    return -1
  endif
endfunction

" vim: sw=2 ts=2 et
