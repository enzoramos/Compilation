%{
  #include <stdlib.h>   /* utilise par les free de bison */
  #include <stdio.h>
  #include <string.h>

  int yyerror(char*);
  int yylex();

  typedef struct variable {
    char name[255];
    union {
      unsigned int entier;
      void * pointeur;
    };
    enum{ e, p } type;
  } var;
  var variables;
  int ind = 0;

  void print_var( var *variable ) {
    switch ( variable->type ) {
      case e:
        printf( "%d", variable->entier );
        break;
      case p:
        printf( "%p", variable->pointeur );
        break;
    }
  }

%}

%union {
  void                                        *pointeur;
  int                                         entier;
  char                                        *ident;
  enum { gte, gt, lt, lte, eq, neq }          comparator;
  enum { add, sub, tim, div, mod }            operator;
  enum { vrg, pv }                            separator;
  enum { lpar, rpar, lacc, racc, lsqb, rsqb } block;
}

%left "<" ">" "<=" "=>" "==" "!=" /* Comparateurs */
%left "+" "-"                     /* additions / soustractions */
%left "*" "/"                     /* multiplications / divisions */
%left UMINUS                      /* Moins unaire */
%right PTR ADR                    /* Pointeur */

%token <comp>   COMP
%token <addsub> ADDSUB
%token <div>    DIV
%token <star>   STAR
%token <num>    NUM
%token <ident>  IDENT
%token <mod>    MOD
%token <adr>    ADR

%%
prog: DeclConst DeclVar DeclFonct DeclMain
  ;
DeclConst: DeclConst CONST ListConst PV
  | /* epsi */
  ;
ListConst: ListConst VRG IDENT EGAL NombreSigne
  | IDENT EGAL NombreSigne
  ;
NombreSigne: NUM
  | ADDSUB NUM
  ;
DeclVar: DeclVar VAR ListVar PV
  | /* epsi */
  ;
ListVar: ListVar VRG Variable
  | Variable
Variable: STAR Variable
  | IDENT LSQB ENTIER RSQB
  | IDENT
  ;
DeclMain: EnTeteMain Corps
  ;
EnTeteMain: MAIN LPAR RPAR
  ;
DeclFonct: DeclFonct DeclUneFonct
  | /* epsi */
  ;
DeclUneFonct: EnTeteFonct Corps
  ;
EnTeteFonct: Type IDENT LPAR Parametres RPAR
  ;
Type: ENTIER
  | VOID
  ;
Parametres: VOID
  | ListVar
  | /* epsi */                                 /* Élargit le langage */
  ;
Corps: LACC DeclConst DeclVar SuiteInstr RACC
  ;
SuiteInstr: SuiteInstr Instr
  | /* epsi */
  ;
InstrComp: LACC SuiteInstr RACC
  ;
Instr: IDENT EGAL Exp PV
  | STAR IDENT EGAL Exp PV
  | IDENT EGAL MALLOC LPAR Exp RPAR PV
  | FREE LPAR Exp RPAR PV
  | IF LPAR Exp RPAR Instr
  | IF LPAR Exp RPAR Instr ELSE Instr
  | WHILE LPAR Exp RPAR Instr
  | RETURN Exp PV
  | RETURN PV
  | IDENT LPAR Arguments RPAR PV
  | READ LPAR IDENT RPAR PV
  | PRINT LPAR Exp RPAR PV
  | PV
  | InstrComp
  ;
Arguments: ListExp
  | /* epsi */
  ;
ListExp: ListExp VRG Exp
  | Exp
  ;
Exp: Exp ADDSUB Exp
  | Exp STAR Exp
  | Exp DIV Exp
  | Exp COMP Exp
  | ADDSUB Exp
  | LPAR Exp RPAR
  | Variable
  | ADR Variable
  | NUM
  | IDENT LPAR Arguments RPAR
  ;
PV: ";" ;
CONST: "const" ;
RETURN: "return" ;

FREE: "free" ;
MALLOC: "malloc" ;

VRG: "," ;
LPAR: "(" ;
RPAR: ")" ;
LACC: "{" ;
RACC: "}" ;
LSQB: "[" ;
RSQB: "]" ;

VOID: "void" ;
ENTIER: "entier" ;
POINTEUR: "pointeur" ;

IF: "if" ;
ELSE: "else" ;
WHILE: "while" ;
EGAL: "=" ;
VAR: ENTIER
  | POINTEUR
  ;
MAIN: "main" ;

READ: "read" ;
PRINT: "print" ;


%%

int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}

int main(void) {
  yyparse();
  return 0;
}
