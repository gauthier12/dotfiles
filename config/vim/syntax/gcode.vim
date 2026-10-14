" Syntaxe G-code (commande numérique : LinuxCNC, Fanuc, imprimantes 3D…).
if exists('b:current_syntax')
  finish
endif

syn case ignore

syn match gcodeG /G\d\+\%(\.\d\+\)\=/
syn match gcodeM /M\d\+/
syn match gcodeTool /[TH]\d\+/
syn match gcodeLineNumber /^\s*N\d\+/
syn match gcodeProgram /^\s*O\d\+\|^%.*$/
" Coordonnées, puis réglages (avance, vitesse, temporisation…).
syn match gcodeAxis /[XYZABCUVWIJKR]\s*[-+]\=\%(\d\+\.\=\d*\|\.\d\+\)/
syn match gcodeParam /[FSPQELD]\s*[-+]\=\%(\d\+\.\=\d*\|\.\d\+\)/
syn match gcodeVariable /#\d\+\|#<\w\+>/

syn keyword gcodeTodo TODO FIXME contained
syn match gcodeComment /(.\{-})/ contains=gcodeTodo
syn match gcodeComment /;.*$/ contains=gcodeTodo

hi def link gcodeG Statement
hi def link gcodeM Function
hi def link gcodeTool Type
hi def link gcodeLineNumber LineNr
hi def link gcodeProgram PreProc
hi def link gcodeAxis Number
hi def link gcodeParam Constant
hi def link gcodeVariable Identifier
hi def link gcodeTodo Todo
hi def link gcodeComment Comment

let b:current_syntax = 'gcode'
