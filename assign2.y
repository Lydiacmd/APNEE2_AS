%{
#include <stdio.h>
#include <stdlib.h>
#include "table_symboles.h"

int yyparse(void);
int yylex(void);
int yyerror(char *s);

int erreur = 0;
%}

%union {
    long nval;
    char *sval;
}

/* Tokens typés */
%token <nval> ENTIER
%token <sval> VAR

/* Priorités (première = plus faible) */
%left LBRACK
%left PLUS MINUS
%left MULT DIV MODULO
%right EXPON
%right UMINUS

/* Autres tokens */
%token ASSIGN SEMICOLON LB RB RBRACK LBRACK

%start Source

%type<nval> Source List Assign Expr

%%

/* SOURCE = suite d’assignations */
Source
    : List
      {
        if (!erreur) print_symbols();
      }
    ;

/* L → ε | L Assign ; */
List
    : /* vide */
          { $$ = 0; }
    | List Assign SEMICOLON
    ;

/* A → VAR = A | Expr */
Assign
    : VAR ASSIGN Assign
      {
        set_value($1, $3);
        $$ = $3;
        free($1);
      }
    | Expr
      {
        $$ = $1;
      }
    ;

/* Grammaire AMBIGUË mais gérée par priorités */
Expr
    : Expr PLUS Expr
      { $$ = $1 + $3; }
    | Expr MINUS Expr
      { $$ = $1 - $3; }

    | Expr MULT Expr
      { $$ = $1 * $3; }
    | Expr DIV Expr
      { $$ = $1 / $3; }
    | Expr MODULO Expr
      { $$ = $1 % $3; }

    | Expr EXPON Expr
      {
        long r = 1;
        for (long i = 0; i < $3; i++) r *= $1;
        $$ = r;
      }

    | Expr LBRACK Expr RBRACK
      {
        $$ = ($3 == 0) ? $1 : ($1 % $3);
      }

    /* parenthèses contenant une assignation complète */
    | LB Assign RB
      { $$ = $2; }

    /* - unaire */
    | MINUS Expr %prec UMINUS
      { $$ = -$2; }

    | ENTIER
      { $$ = $1; }
    | VAR
      {
        long v = get_value($1);
        $$ = v;
        free($1);
      }
    ;

%%

int yyerror(char *s) {
    if (!erreur) {
        erreur = 1;
        printf("!!! ERREUR !!!\n");
    }
    return 0;
}

int main(void) {
    yyparse();
    return 0;
}
