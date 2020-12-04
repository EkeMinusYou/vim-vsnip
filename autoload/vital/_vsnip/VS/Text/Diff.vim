" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_vsnip#VS#Text#Diff#import() abort', printf("return map({'try_enable_lua': '', 'is_lua_enabled': '', 'compute': ''}, \"vital#_vsnip#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
"
" is_lua_enabled
"
function! s:is_lua_enabled(is_lua_enabled) abort
  let s:is_lua_enabled = a:is_lua_enabled
endfunction

"
" compute
"
function! s:compute(old, new) abort
  let l:old = a:old
  let l:new = a:new

  let l:old_len = len(l:old)
  let l:new_len = len(l:new)
  let l:min_len = min([l:old_len, l:new_len])

  " empty -> empty
  if l:old_len == 0 && l:new_len == 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': 0,
    \       'character': 0,
    \     }
    \   },
    \   'text': '',
    \   'rangeLength': 0
    \ }
  " not empty -> empty
  elseif l:old_len != 0 && l:new_len == 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': l:old_len - 1,
    \       'character': strchars(l:old[-1]),
    \     }
    \   },
    \   'text': '',
    \   'rangeLength': strchars(join(l:old, "\n"))
    \ }
  " empty -> not empty
  elseif l:old_len == 0 && l:new_len != 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': 0,
    \       'character': 0,
    \     }
    \   },
    \   'text': join(l:new, "\n"),
    \   'rangeLength': 0
    \ }
  endif

  if s:is_lua_enabled
    let l:first_line = luaeval('vital_vs_text_diff_search_first_line(_A[1], _A[2])', [l:old, l:new])
  else
    let l:first_line = 0
    while l:first_line < l:min_len - 1
      if l:old[l:first_line] !=# l:new[l:first_line]
        break
      endif
      let l:first_line += 1
    endwhile
  endif

  if s:is_lua_enabled
    let l:last_line = luaeval('vital_vs_text_diff_search_last_line(_A[1], _A[2], _A[3])', [l:old, l:new, l:first_line])
  else
    let l:last_line = -1
    while l:last_line > -l:min_len + l:first_line
      if l:old[l:last_line] !=# l:new[l:last_line]
        break
      endif
      let l:last_line -= 1
    endwhile
  endif

  let l:old_lines = l:old[l:first_line : l:last_line]
  let l:new_lines = l:new[l:first_line : l:last_line]
  let l:old_text = join(l:old_lines, "\n") . "\n"
  let l:new_text = join(l:new_lines, "\n") . "\n"
  let l:old_text_len = strchars(l:old_text)
  let l:new_text_len = strchars(l:new_text)
  let l:min_text_len = min([l:old_text_len, l:new_text_len])

  let l:first_char = 0
  while l:first_char < l:min_text_len - 1
    if strgetchar(l:old_text, l:first_char) != strgetchar(l:new_text, l:first_char)
      break
    endif
    let l:first_char += 1
  endwhile

  let l:last_char = 0
  while l:last_char > -l:min_text_len + l:first_char
    if strgetchar(l:old_text, l:old_text_len + l:last_char - 1) != strgetchar(l:new_text, l:new_text_len + l:last_char - 1)
      break
    endif
    let l:last_char -= 1
  endwhile

  return {
  \   'range': {
  \     'start': {
  \       'line': l:first_line,
  \       'character': l:first_char,
  \     },
  \     'end': {
  \       'line': l:old_len + l:last_line,
  \       'character': strchars(l:old_lines[-1]) + l:last_char + 1,
  \     }
  \   },
  \   'text': strcharpart(l:new_text, l:first_char, l:new_text_len + l:last_char - l:first_char),
  \   'rangeLength': l:old_text_len + l:last_char - l:first_char
  \ }
endfunction

let s:is_lua_enabled = v:false
function! s:try_enable_lua() abort
lua <<EOF
function vital_vs_text_diff_search_first_line(old, new)
  local min_len = math.min(#old, #new)
  local first_line = 0
  while first_line < min_len - 1 do
    if old[first_line + 1] ~= new[first_line + 1] then
      return first_line
    end
    first_line = first_line + 1
  end
  return min_len - 1
end
function vital_vs_text_diff_search_last_line(old, new, first_line)
  local old_len = #old
  local new_len = #new
  local min_len = math.min(#old, #new)
  local last_line = -1
  while last_line > -min_len + first_line do
    if old[(old_len + last_line) + 1] ~= new[(new_len + last_line) + 1] then
      return last_line
    end
    last_line = last_line - 1
  end
  return -min_len + first_line
end
EOF
let s:is_lua_enabled = v:true
endfunction

if has('nvim')
  try
    call s:try_enable_lua()
  catch /.*/
  endtry
endif

