" -- regopher
command! -nargs=? -complete=customlist,regopher#Complete ReGoParamsToStruct call regopher#ParamsToStruct(<bang>0, <f-args>)
command! -nargs=? -complete=customlist,regopher#Complete ReGoResultsToStruct call regopher#ResultsToStruct(<bang>0, <f-args>)
