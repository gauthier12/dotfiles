" Gibiane : indentation de 4 espaces, commentaires en « * » au début de la ligne.
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4 textwidth=972
setlocal comments=:* commentstring=*\ %s
let b:undo_ftplugin = 'setlocal et< ts< sts< sw< tw< com< cms<'
