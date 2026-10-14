" Indentation Gibiane : un niveau de plus dans REPE, SI, SINON, DEBP ; un de moins sur FIN, FINSI, FINP, SINON.
" Mots écrits avec ou sans apostrophes ; commentaires en colonne 1.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GibianeIndent() indentkeys+=0=~fin,0=~sino,0=~'fin,0=~'sino
let b:undo_indent = 'setlocal inde< indk<'

let s:open = '^\s*''\=\%(repe\%[ter]\|si\|sino\%[n]\|debp\%[roc]\)\>'
let s:close = '^\s*''\=\%(fin\|fins\%[i]\|finp\%[roc]\|sino\%[n]\)\>'
" Bloc fermé sur la même ligne : SI … ; FINSI ;
let s:close_inline = ';\s*''\=\%(fin\|fins\%[i]\|finp\%[roc]\)\>'

function! GibianeIndent() abort
  let line = getline(v:lnum)
  if line =~# '^\*'
    return 0
  endif
  " Ligne de code précédente, sans les commentaires.
  let lnum = prevnonblank(v:lnum - 1)
  while lnum > 0 && getline(lnum) =~# '^\*'
    let lnum = prevnonblank(lnum - 1)
  endwhile
  if lnum == 0
    return 0
  endif
  let prev = getline(lnum)
  let ind = indent(lnum)
  if prev =~? s:open && prev !~? s:close_inline
    let ind += shiftwidth()
  endif
  if line =~? s:close
    let ind -= shiftwidth()
  endif
  return ind
endfunction
