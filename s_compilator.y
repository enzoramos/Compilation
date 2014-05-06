%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
int yyerror(char*);
int yylex();
 FILE* yyin; 
 int jump_label=1;
 int pointeur_decal = -1;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);


typedef struct {
  char name[256];
  enum {ptr, ent} type;
  int  adr;
} ident_t;

enum {func, var} current_ident = var;

int variables_index=4096;
int fonctions_index=4096;
ident_t variables[4096];
ident_t fonctions[4096];

 bool isDecl_variable(const char * name);
 bool isDecl_fonciton(const char * name);
 int  getAdr_variable(const char * name);
 int  getAdr_fonction(const char * name);
 void decl_variable(const char * name, int type);
 void decl_fonction(const char * name, int type);

 void clear_ident(ident_t* idents, int * size);


%}

%union { 
  void*                                       data;
  int                                         entier;
  char                                        ident[256];
  enum { gte, gt, lt, lte, eq, neq }          comparator;
  enum { add, sub, times, divide, mod }       operator;
  enum { vrg, pv }                            separator;
  enum { lpar, rpar, lacc, racc, lsqb, rsqb } block;
  int type;
}

%nonassoc ENDIF
%nonassoc ELSE
%token  IF ELSE PRINT MAIN LPAR RPAR PV CONST RETURN FREE MALLOC VRG LACC RACC LSQB RSQB VOID ENTIER POINTEUR WHILE EGAL READ IDENT NUM

%token COMP ADDSUB STAR DIV MOD

%type<data> Exp
%type<entier> NUM FIXIF FIXELSE WHILESTART WHILETEST ListVar ENTIER
%type<operator> ADDSUB
%type<comparator> COMP
%type<ident> IDENT Variable
%type<type> Type



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
  | Type Variable PV { decl_variable($2,$1);   }
  | /* epsi */
  ;
ListVar: ListVar VRG Variable
  | Variable 
Variable: STAR Variable     { strcpy($$,$2); pointeur_decal = 0; }
  | IDENT LSQB ENTIER RSQB  { strcpy($$,$1); pointeur_decal = $3; }
  | IDENT                   { strcpy($$,$1); pointeur_decal = -1; }
  ;
DeclMain: EnTeteMain Corps {  }
  ;
EnTeteMain: MAIN LPAR RPAR { instarg("LABEL", 0); }
  ;
DeclFonct: DeclFonct DeclUneFonct
  | /* epsi */
  ;
DeclUneFonct: EnTeteFonct Corps { }
  ;
EnTeteFonct:  IDENT LPAR  RPAR { decl_fonction($1, 0); instarg("LABEL", jump_label++); }
  ;
Type: ENTIER
  | VOID
  ;
Parametres: VOID
  | ListVar
  /* | epsi */                                 /* Élargit le langage */
  ;
Corps: LACC DeclConst DeclVar SuiteInstr RACC
  ;
SuiteInstr: SuiteInstr Instr
  | /* epsi */
  ;
InstrComp: LACC SuiteInstr RACC
  ;
Instr: IDENT EGAL Exp PV                                 { instarg("SET", getAdr_variable($1)); inst("SWAP"); instarg("SET", $3); inst("SAVER"); }
  | STAR IDENT EGAL Exp PV                               {}
  | IDENT EGAL MALLOC LPAR Exp RPAR PV                   {}
  | FREE LPAR Exp RPAR PV                                {}
  | IF LPAR Exp RPAR FIXIF Instr %prec ENDIF             { instarg("LABEL",$5); } 
  | IF LPAR Exp RPAR FIXIF Instr  ELSE FIXELSE Instr     { instarg("LABEL",$8); }
  | WHILE WHILESTART LPAR Exp RPAR WHILETEST Instr       { instarg("JUMP", $2); instarg("LABEL",$6); }
  | RETURN Exp PV                                        { instarg("SET", $2); inst("RETURN"); }
  | RETURN PV                                            { inst("RETURN");    }
  | IDENT LPAR Arguments RPAR PV                         { instarg("CALL", getAdr_fonction($1)); }
  | READ LPAR IDENT RPAR PV                              { inst("READ"); /*inst("PUSH");*/ }
  | PRINT LPAR Exp RPAR PV                               { instarg("SET", $3); inst("LOADR"); inst("WRITE"); }
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
    /* inst("PUSH"); */ 
  }
  | Exp STAR Exp { instarg("SET", $3); inst("SWAP"); instarg("SET", $1); inst("MULT"); /* inst("PUSH"); */ }
  | Exp DIV Exp  { instarg("SET", $3); inst("SWAP"); instarg("SET", $1); inst("DIV");  /* inst("PUSH"); */ }
  | Exp MOD Exp  { instarg("SET", $3); inst("SWAP"); instarg("SET", $1); inst("MOD");  /* inst("PUSH"); */ }
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

  }
  | ADDSUB Exp { if($1==sub) $$=($2); else $$=$2; } /* TODO ######### */
  | LPAR Exp RPAR
  | Variable {  $$=getAdr_variable($1);  }
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


 bool isDecl_ident(const char * name, ident_t* ident, int ident_index) {
    int i;
    for (i=0; i < ident_index; i++) {
      if (strcmp(ident[i].name, name) == 0) {
        return true;
      }
    }
    return false;
 }

 void decl_ident(const char * name, ident_t* ident, int ident_index, int adr, int type, bool alloc) {
    if(isDecl_variable(name) == true) {
      inst("ERROR : DECLARED VARIABLE");
      exit(EXIT_FAILURE);
    }
    strcpy(ident[ident_index].name, name);
    ident[ident_index].adr = adr;
    ident[ident_index].type = type;
    if(alloc) instarg("ALLOC", 2);
 }


 int  getAdr_ident(const char * name, ident_t* ident, int ident_index) {
    int i;
    /*printf("%s max : %d\n", name, ident_index);*/
    for (i=0; i < ident_index; i++) {
      /*printf("%s == %s ? %d\n", name, ident[i].name, i);*/
      if (strcmp(ident[i].name, name) == 0) {
        return ident[i].adr;
      }
    }
    inst("ERROR UNKNOWN VARIABLE");
    exit(EXIT_FAILURE);
    return -1;
 }

bool isDecl_variable(const char * name) {
  return isDecl_ident(name, variables, variables_index);
}
 bool isDecl_fonciton(const char * name) {
return isDecl_ident(name, fonctions, fonctions_index);
 }
 int  getAdr_variable(const char * name) {
  /* printf("get Variable\n"); */
return getAdr_ident(name, variables, variables_index);
 }
 int  getAdr_fonction(const char * name) {
    /* printf("get function\n"); */
  return getAdr_ident(name, fonctions, fonctions_index);
 }
 void decl_variable(const char * name, int type) {
  decl_ident(name, variables, variables_index, variables_index, type, true);
  variables_index++;
 }
 void decl_fonction(const char * name, int type) {
  decl_ident(name, fonctions, fonctions_index, jump_label, type, false);
  fonctions_index++;
 }

  void clear_ident(ident_t* idents, int * size) {
    int i;
    for(i = 0; i < *size; i++) {
      idents[i].name[0] = '\0';
    }
    *size = 0;
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

  clear_ident(variables, &variables_index);
  clear_ident(fonctions, &fonctions_index);

  /* TODO INIATILISE MAIN in FONCTIONS */
  instarg("JUMP", 0);
  yyparse();
  endProgram();
  return 0;
}
