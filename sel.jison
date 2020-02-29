// See the following links:
// https://www.makemkv.com/forum/viewtopic.php?f=10&t=4386
// https://www.makemkv.com/forum/viewtopic.php?f=10&t=4566
%lex
%%
\s+        { /* skip whitespace */ }
\d+        { return 'NUMBER'; }
"-"        { return 'MINUS'; }
"+"        { return 'PLUS'; }
":"        { return 'COLON'; }
"("        { return 'LPAREN'; }
")"        { return 'RPAREN'; }
"|"        { return 'OR'; }
"&"        { return 'AND'; }
","        { return 'COMMA'; }
"!"        { return 'NOT'; }
"~"        { return 'NOT'; }
"*"        { return 'AND'; }
"="        { return 'EQUALS'; }
"multi"    { return 'multi'; }
"stereo"   { return 'stereo'; }
"mono"     { return 'mono'; }
"sel":     { return 'sel'; }
"all":     { return 'all'; }
"mvcvideo" { return 'mvcvideo'; }
"special"  { return 'special'; }
"favlang"  { return 'favlang'; }
"subtitle" { return 'subtitle'; }
"audio"    { return 'audio'; }
"nolang"   { return 'nolang'; }
"[a-z]{3}" { return 'LANG'; }
<<EOF>>    { return 'EOF'; }

/lex

%left PLUS MINUS
%left NOT AND OR
%left UMINUS

%start expressions
%% /* lagnuage grammar */
expressions : e EOF { return $1; };
on_off
  : MINUS { $$ = 'deselect'; }
  | PLUS { $$ = 'select'; }
  ;
comma_or_end: COMMA | EOF;
selectable
  : multi     { $$ = 'multi-channel audio tracks'; }
  | stereo    { $$ = 'stereo audio tracks'; }
  | mono      { $$ = 'mono audio tracks'; }
  | all       { $$ = 'all tracks'; }
  | mvcvideo  { $$ = 'multi-angle video'; }
  | LANG      { $$ = 'tracks of language ' + $1; }
  | favlang   { $$ = 'favourite language tracks'; }
  | subtitle  { $$ = 'subtitle tracks'; }
  | audio     { $$ = 'tracks with audio'; }
  | nolang    { $$ = 'tracks without a language set'}
  ;
conditional
  : selectable                  { $$ = $1; }
  | NOT conditional             { $$ = 'not ' + $1; }
  | conditional AND conditional { $$ = $1 + ' and\n  ' + $3; }
  | conditional OR conditional  { $$ = $1 + ' or\n  ' + $3; }
  | LPAREN conditional RPAREN   { $$ = '(\n  ' + $2 + '\n)'; }
  ;
selection: on_off sel COLON conditional { $$ = $1 + ' ' + $4; };
set_weight
  : EQUALS NUMBER COLON conditional
    { $$ = 'set weight ' + $2 + ' for ' + $4; }
  | MINUS NUMBER COLON conditional %prec UMINUS
    { $$ = 'subtract weight ' + $2  + ' for ' + $4; }
  | PLUS NUMBER COLON conditional
    { $$ = 'increase weight ' + $2  + ' for ' + $4; }
  ;
e : selection COMMA e  { $$ = $1 + ' then\n' + $3; }
  | set_weight COMMA e { $$ = $1 + ' then\n' + $3; }
  | selection          { $$ = $1; }
  | set_weight         { $$ = $1; }
  ;
