%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
int yyerror(char*);
int yylex();
 FILE* yyin; 
 int jump_label=0;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
%}

%union { 
  int                                         entier;
  char*                                       indent;
  enum { gte, gt, lt, lte, eq, neq }          comparator;
  enum { add, sub, tim, div, mod }            operator;
  enum { vrg, pv }                            separator;
  enum { lpar, rpar, lacc, racc, lsqb, rsqb } block;
}

%nonassoc FX
%nonassoc ELSE
%token  IF ELSE PRINT MAIN LPAR RPAR PV CONST RETURN FREE MALLOC VRG LACC RACC LSQB RSQB VOID ENTIER POINTEUR WHILE EGAL READ IDENT NUM

%token COMP ADDSUB STAR DIV


%left '+'
%left '*'

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
EnTeteMain: MAIN LPAR RPAR { /*inst("MAIN");*/}
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
  | READ LPAR IDENT RPAR PV  { inst("READ"); inst("PUSH"); }
  | PRINT LPAR Exp RPAR PV {inst("POP");  inst("WRITE"); comment("---affichage"); }
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
  | Exp DIV Exp { /*instarg("DIVISION", 9); */}
  | Exp COMP Exp {/* instarg("COMPARAISON", 9);*/ }
  | ADDSUB Exp
  | LPAR Exp RPAR
  | Variable
  /*| ADR Variable ################ */
  | NUM
  | IDENT LPAR Arguments RPAR
  ;

VAR: ENTIER
  | POINTEUR
  ;
%%

int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}



void endProgram() {
  printf("HALT\n");
}

void inst(const char *s){
  printf("%s\n",s);
}

void instarg(const char *s,int n){
  printf("%s\t%d\n",s,n);
}


void comment(const char *s){
  printf("#%s\n",s);
}

int main(int argc, char** argv) {
  if(argc==2){
    yyin = fopen(argv[1],"r");
  }
  else if(argc==1){
    yyin = stdin;
  }
  else{
    fprintf(stderr,"usage: %s [src]\n",argv[0]);
    return 1;
  }

  yyparse();
  endProgram();
  return 0;
}
