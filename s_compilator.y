%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
int yyerror(char*);
int yylex();
 FILE* yyin; 
 int jump_label=1;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 int compteur_variable=0;
%}

%union { 
  void*                                       data;
  int                                         entier;
  char*                                       indent;
  enum { gte, gt, lt, lte, eq, neq }          comparator;
  enum { add, sub, times, divide, mod }       operator;
  enum { vrg, pv }                            separator;
  enum { lpar, rpar, lacc, racc, lsqb, rsqb } block;
}

%nonassoc ENDIF
%nonassoc ELSE
%token  IF ELSE PRINT MAIN LPAR RPAR PV CONST RETURN FREE MALLOC VRG LACC RACC LSQB RSQB VOID ENTIER POINTEUR WHILE EGAL READ IDENT NUM

%token COMP ADDSUB STAR DIV MOD

%type<data> Exp
%type<entier> NUM FIXIF FIXELSE WHILESTART WHILETEST
%type<operator> ADDSUB
%type<comparator> COMP



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
EnTeteMain: MAIN LPAR RPAR { instarg("LABEL", 0); }
  ;
DeclFonct: DeclFonct 
  | /* epsi */
  ;
DeclUneFonct: EnTeteFonct Corps
  ;
EnTeteFonct: Type IDENT LPAR Parametres RPAR { instarg("LABEL", jump_label++); }
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
Instr: IDENT EGAL Exp PV                                 { instarg("ALLOC", 1); instarg("SET", $3); inst("PUSH"); }
  | STAR IDENT EGAL Exp PV                               {}
  | IDENT EGAL MALLOC LPAR Exp RPAR PV                   {}
  | FREE LPAR Exp RPAR PV                                {}
  | IF LPAR Exp RPAR FIXIF Instr %prec ENDIF             { instarg("LABEL",$5); } 
  | IF LPAR Exp RPAR FIXIF Instr  ELSE FIXELSE Instr     { instarg("LABEL",$8); }
  | WHILE WHILESTART LPAR Exp RPAR WHILETEST Instr       { instarg("JUMP", $2); instarg("LABEL",$6); }
  | RETURN Exp PV                                        { instarg("SET", $2); inst("RETURN"); }
  | RETURN PV                                            { inst("RETURN"); }
  | IDENT LPAR Arguments RPAR PV                         {}
  | READ LPAR IDENT RPAR PV                              { inst("READ"); inst("PUSH"); }
  | PRINT LPAR Exp RPAR PV                               { inst("POP");  inst("WRITE"); }
  | PV                                                   {}
  | InstrComp                                            {}
  ;
Arguments: ListExp
  | /* epsi */
  ;
ListExp: ListExp VRG Exp
  | Exp
  ;
Exp: Exp ADDSUB Exp { instarg("SET", $3);
    inst("SWAP");
    instarg("SET", $1); 
    if ($2==add) 
          inst("ADD"); 
    else 
          inst("SUB");
    inst("PUSH"); 
  }
  | Exp STAR Exp { instarg("SET", $3); inst("SWAP"); instarg("SET", $1); inst("MULT"); inst("PUSH"); }
  | Exp DIV Exp  { instarg("SET", $3); inst("SWAP"); instarg("SET", $1); inst("DIV"); inst("PUSH"); }
  | Exp MOD Exp  { instarg("SET", $3); inst("SWAP"); instarg("SET", $1); inst("MOD"); inst("PUSH"); }
  | Exp COMP Exp { instarg("SET", $3); 
  inst("SWAP"); 
  instarg("SET", $1);
  switch($2) {
    case eq: inst("EQUAL"); break;
    case neq:inst("NOTEQ"); break;
    case lt: inst("LOW");   break;
    case gt: inst("GREAT"); break;
    case lte: inst("LEQ");  break;
    case gte: inst("GEQ");  break;
    default: inst("UNDEFINED COMPARATOR");
  }
  inst("WRITE");
  }
  | ADDSUB Exp { if($1==sub) $$=($2); else $$=$2; } /* TODO ######### */
  | LPAR Exp RPAR
  | Variable
  /*| ADR Variable ################ */
  | NUM { instarg("SET",$$=$1); }
  | IDENT LPAR Arguments RPAR
  ;

VAR: ENTIER
  | POINTEUR
  ;

  FIXIF :  { instarg("JUMPF", $$=jump_label+=2); }
  FIXELSE : { instarg("JUMP", $$=jump_label); instarg("LABEL", jump_label-1); }
  WHILESTART : { instarg("LABEL", $$=jump_label++); }
  WHILETEST  : { instarg("JUMPF", $$=jump_label++); }

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
  instarg("JUMP", 0);
  yyparse();
  endProgram();
  return 0;
}
