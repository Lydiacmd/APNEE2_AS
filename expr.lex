/*
 * expr.lex : Scanner for a simple
 *            expression parser.
 */

%{
#include "expr.h"
#include <errno.h>

#define YY_SKIP_YYWRAP 1

int yywrap() {
    return 1;
}

%}

%%

[0-9]+          { yylval.nval = atol(yytext); return(ENTIER); }

[a-zA-Z]+       { yylval.sval = strdup(yytext); return(VAR); }

"+"        return(PLUS);
"*"        return(MULT);
"("        return(LB);
")"        return(RB);
[\n\t ]*     /* throw away whitespace */

<<EOF>>  { return(EOF); }
%%



