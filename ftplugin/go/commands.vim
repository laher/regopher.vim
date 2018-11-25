" -- regopher
command! -nargs=? -complete=customlist,regopher#Complete ReGoParamStruct call regopher#ParamStruct(<bang>0, <f-args>)
