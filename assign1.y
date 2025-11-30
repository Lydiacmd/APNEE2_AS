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
    int   nval;
    char *sval;
}

/* Tokens typés */
%token <nval> ENTIER
%token <sval> VAR

/* Tokens simples - SANS directives de priorité */
%token PLUS MINUS MULT DIV EXPON ASSIGN SEMICOLON LB RB LBRACK RBRACK

/* Types des non-terminaux */
%type<nval> S L A M T P F

%start S

%%

/* S -> L */
S     : L
      {
        if (!erreur) {
            print_symbols();
        }
      }
      ;

/* L -> A ; L | ε */
L     : /* vide */
        { $$ = 0; }
      | A SEMICOLON L
        { $$ = $1; }
      ;

/* A -> VAR = A | M */
A     : VAR ASSIGN A
      {
          set_value($1, $3);
          $$ = $3;
          free($1);
      }
      | M
      {
          $$ = $1;
      }
      ;

/* M -> TM' 
   M' -> +TM' | -TM' | [M]M' | ε
   
   En Bison (élimination de M') :
   M -> T | M + T | M - T | M[M]
*/
M     : T
      { $$ = $1; }
      | M PLUS T
      { $$ = $1 + $3; }
      | M MINUS T
      { $$ = $1 - $3; }
      | M LBRACK M RBRACK
      {
          int n = $3;
          if (n == 0) {
              $$ = $1;
          } else {
              int v = $1 % n;
              if (v < 0) v += n;
              $$ = v;
          }
      }
      ;

/* T -> PT'
   T' -> *PT' | /PT' | ε
   
   En Bison :
   T -> P | T * P | T / P
*/
T     : P
      { $$ = $1; }
      | T MULT P
      { $$ = $1 * $3; }
      | T DIV P
      {
          if ($3 == 0) {
              fprintf(stderr, "Division par zero!\n");
              yyerror("division by zero");
              $$ = 0;
          } else {
              $$ = $1 / $3;
          }
      }
      ;

/* P -> FP'
   P' -> ^P | ε
   
   En Bison (associativité droite) :
   P -> F | F ^ P
*/
P     : F
      { $$ = $1; }
      | F EXPON P
      {
          int base = $1;
          int exp = $3;
          int res = 1;
          for (int i = 0; i < exp; i++) {
              res *= base;
          }
          $$ = res;
      }
      ;

/* F -> VAR | INT | (A) */
F     : ENTIER
      { $$ = $1; }
      | VAR
      {
          int v = get_value($1);
          $$ = v;
          free($1);
      }
      | LB A RB
      { $$ = $2; }
      ;

%%

int yyerror(char *s) {
    (void)s;
    if (!erreur) {
        erreur = 1;
        printf("!!! ERREUR !!!\n");
    }
    return 0;
}

int main(void) {
    if (yyparse() != 0) {
        return 1;
    }
    return 0;
}