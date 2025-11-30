/*
 * assign1.lex : Scanner pour analyse des assignations.
 */

%{
#include "assign1.h"
#include <errno.h>

#define YY_SKIP_YYWRAP 1

int yywrap() {
    return 1;
}
%}

%%

[0-9]+          { yylval.nval = atol(yytext); return ENTIER; }

[a-zA-Z]+       { yylval.sval = strdup(yytext); return VAR; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULT; }
"/"             { return DIV; }
"^"             { return EXPON; }

"("             { return LB; }
")"             { return RB; }
"["             { return LBRACK; }
"]"             { return RBRACK; }

"="             { return ASSIGN; }
";"             { return SEMICOLON; }

[ \t\n]+        /* ignore whitespace */

.               {
                    fprintf(stderr, "Caractere inattendu: '%c'\n", yytext[0]);
                    return 0;
                }

<<EOF>>         { return 0; }

%%