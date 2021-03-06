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
 bool declaration = false;
 bool pop = false;
 int  declaration_type = 0;
 int currentAdr_var;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);

 int load_ListVar_index = -3;


typedef struct {
  char name[256];
  enum {ptr, ent, cst, mlc} type;
  int  adr;
} ident_t;

enum {func, var} current_ident = var;

#define MAX 4096
#define TAS 10000
int variables_index=MAX;
int fonctions_index=MAX;
int consts_index=MAX;
int tas_index=0; 
ident_t variables[MAX];
ident_t consts[MAX];
ident_t fonctions[MAX];

 bool isDecl_variable(const char * name);
 bool isDecl_fonciton(const char * name);
 int  getAdr_variable(const char * name);
 int  getAdr_fonction(const char * name);
 int  getValue_const(const char * name);
 void decl_variable  (const char * name, int type);
 void decl_const  (const char * name, int type);
 void decl_fonction  (const char * name, int type);
 void load_variable(const char * name, int type);
 void load_ListVar(const char * name);
 bool isDecl_const(const char *name);

 void clear_ident(ident_t* idents, int * size);

 void setVariable_mlc(const char *name, int size);
 const char * getLoader(const char * name);

%}

%union { 
  void*                                       data;
  int                                         entier;
  char                                        ident[256];
  enum { gte, gt, lt, lte, eq, neq }          comparator;
  enum { add, sub, times, divide, mod }       operator;
  enum { vrg, pv}                            separator;
  enum { lpar, rpar, lacc, racc, lsqb, rsqb } block;
  int type;
}

%nonassoc ENDIF
%nonassoc ELSE
%token  IF ELSE PRINT MAIN LPAR RPAR PV CONST RETURN FREE MALLOC VRG LACC RACC LSQB RSQB VOID ENTIER POINTEUR WHILE EGAL READ IDENT NUM ADR

%token COMP ADDSUB STAR DIV MOD

%type<data> Exp Parametres
%type<entier> NUM FIXIF FIXELSE WHILESTART WHILETEST  ENTIER NombreSigne
%type<operator> ADDSUB
%type<comparator> COMP
%type<ident> IDENT Variable ListVar
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
  | IDENT EGAL NombreSigne                { decl_const($1,$3); }
  ;
NombreSigne: NUM { $$=$1; }
  | ADDSUB NUM { $$=($1==sub)?(-$2):($2); }
  | NombreSigne ADDSUB NombreSigne {  $$=($2==add)?($1+$3):($1-$3); }
  | NombreSigne STAR NombreSigne { $$=$1*$3; }
  | NombreSigne DIV NombreSigne  { if($3 == 0) { yyerror("ERROR DIVIDE BY 0"); /* CHECK FAIL COMPIL */ } else $$=$1/$3; }
  | NombreSigne MOD NombreSigne  { $$=$1%$3; }
  ;

DeclVar: DeclVar VAR FIXDECLVAR ListVar PV { declaration = false;  }
  | /* epsi */
  ;
ListVar: Variable VRG ListVar    { 
    strcpy($$,$3); 
    load_ListVar($1); 
  }
  | Variable { 
    strcpy($$,$1); 
    if(declaration) 
      decl_variable($1, declaration_type); 
    load_ListVar($1);
  }
Variable: STAR Variable       { strcpy($$,$2); pointeur_decal = 0; inst("LOADR"); }
  | IDENT LSQB Exp RSQB       { strcpy($$,$1); pointeur_decal = 1; }
  | IDENT                     { strcpy($$,$1); pointeur_decal = -1;  }
  ;
DeclMain: EnTeteMain Corps {  }
  ;
EnTeteMain: MAIN LPAR RPAR { instarg("LABEL", 0); }
  ;
DeclFonct: DeclFonct DeclUneFonct
  | /* epsi */
  ;
DeclUneFonct: EnTeteFonct Corps { clear_ident(variables, &variables_index);  }
  ;
EnTeteFonct: Type IDENT FIXDECLFONCTION LPAR Parametres RPAR { decl_fonction($2, $1); pop = false; load_ListVar_index = -3;  }
  ;
Type: ENTIER { $$ = 1; }
  | VOID { $$ = 0; }
  ;
Parametres: VOID {} 
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
Instr: IDENT EGAL Exp PV                                 { instarg("SET", getAdr_variable($1)); inst("SWAP");  inst("POP"); inst("SAVER"); }
  | STAR IDENT EGAL Exp PV                               { instarg("SET", getAdr_variable($2)); inst("LOADR"); inst("SWAP"); inst("POP"); inst("SAVER"); }
  | IDENT LSQB Exp RSQB EGAL Exp PV                      { instarg("SET", getAdr_variable($1)); inst("SWAP"); inst("POP"); inst("ADD"); inst("LOADR"); inst("SWAP"); inst("POP"); inst("SAVER"); }
  | IDENT EGAL MALLOC LPAR NombreSigne RPAR PV           { setVariable_mlc($1, $5); }
  | FREE LPAR Exp RPAR PV                                {}
  | IF LPAR Exp RPAR FIXIF Instr %prec ENDIF             { instarg("LABEL", $5); } 
  | IF LPAR Exp RPAR FIXIF Instr  ELSE FIXELSE Instr     { instarg("LABEL", $8); }
  | WHILE WHILESTART LPAR Exp RPAR WHILETEST Instr       { instarg("JUMP" , $2); instarg("LABEL", $6); }
  | RETURN Exp PV                                        { inst("POP"); inst("RETURN"); }
  | RETURN PV                                            { inst("RETURN"); }
  | IDENT LPAR Arguments RPAR PV                         { instarg("CALL" , getAdr_fonction($1)); /* TODO CORRIGER LA CUSTOM */}
  | READ LPAR IDENT RPAR PV                              { instarg("SET", getAdr_variable($3)); inst("SWAP"); inst("READ"); inst("SAVER"); }
  | PRINT LPAR Exp RPAR PV                               { inst("POP"); inst("WRITE"); }
  | PV                                                   {}
  | InstrComp                                            {}
  ;
Arguments: ListExp
  | /* epsi */
  ;
ListExp: ListExp VRG Exp
  | Exp {}
  ;
Exp: Exp ADDSUB Exp {  
    inst("POP");
    inst("SWAP");
    inst("POP"); 
    ($2==add)?(inst("ADD")):(inst("SUB"));
    inst("PUSH");  
  }
  | Exp STAR Exp { inst("POP"); inst("SWAP"); inst("POP");  inst("MULT"); inst("PUSH"); }
  | Exp DIV Exp  { inst("POP"); inst("SWAP"); inst("POP");  inst("DIV");  inst("PUSH");  }
  | Exp MOD Exp  { inst("POP"); inst("SWAP"); inst("POP");  inst("MOD");  inst("PUSH"); }
  | Exp COMP Exp { 
    inst("POP"); 
    inst("SWAP"); 
    inst("POP");
    switch($2) {
      case eq:  inst("EQUAL"); break;
      case neq: inst("NOTEQ"); break;
      case lt:  inst("LOW");   break;
      case gt:  inst("GREAT"); break;
      case lte: inst("LEQ");   break;
      case gte: inst("GEQ");   break;
      default:  inst("UNDEFINED COMPARATOR");
    }
    inst("PUSH"); 
  }
  | ADDSUB Exp { if($1==sub) inst("NEG"); } /* TODO ######### */
  | LPAR Exp RPAR {}
  | Variable {
    if ( isDecl_variable($1) ) {
      currentAdr_var =  getAdr_variable($1);
      instarg("SET", currentAdr_var); 
      inst(getLoader($1));  
    } else {
      instarg("SET", getValue_const($1));
    }

  /* test si c'est une gobale */
  if(pointeur_decal >= 0) {
    if(variables[currentAdr_var].type == ptr) {
      inst("SWAP");
      if(pointeur_decal == 0)
        instarg("SET", 0);
      else if (pointeur_decal == 1)
        inst("POP");
      inst("ADD");
      inst("LOADR");
    } else {
      inst("CONFLIC TYPE");
    }
  }

  inst("PUSH");  }
  | ADR Variable { instarg("SET", getAdr_variable($2)); inst("PUSH"); }
  | NombreSigne { instarg("SET", $1); inst("PUSH"); }
  | IDENT LPAR Arguments RPAR { instarg("CALL" , getAdr_fonction($1)); inst("PUSH"); }
  ;

VAR: ENTIER { declaration_type = ent;}
  | POINTEUR { declaration_type = ptr;}
  ;

  FIXIF :      { instarg("JUMPF", $$=jump_label+=2); }
  FIXELSE :    { instarg("JUMP", $$=jump_label++); instarg("LABEL", jump_label-1); }
  WHILESTART : { instarg("LABEL", $$=jump_label++); }
  WHILETEST  : { instarg("JUMPF", $$=jump_label++); }
  FIXDECLVAR: { declaration = true; }
  FIXDECLFONCTION: {instarg("LABEL", jump_label++); pop=true;}

%%

int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}


void load_ListVar(const char * name) {
  if (pop) { 
      /*instarg("SET", load_ListVar_index); 
      inst("LOADR");*/
      load_variable(name, load_ListVar_index); 
      load_ListVar_index--;
    }  
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
      yyerror("ERROR : DECLARED VARIABLE");
      exit(EXIT_FAILURE);
    }
    strcpy(ident[ident_index].name, name);
    ident[ident_index].adr = adr;
    ident[ident_index].type = type;
    if(alloc) instarg("ALLOC", 1);
 }


 int  getAdr_ident(const char * name, ident_t* ident, int ident_index) {
    int i;
    //printf("%s max : %d\n", name, ident_index);
    for (i=0; i < ident_index; i++) {
      //printf("%s == %s ? %d\n", name, ident[i].name, i);
      if (strcmp(ident[i].name, name) == 0) {
        return ident[i].adr;
      }
    }
    yyerror("ERROR UNKNOWN IDENT");
    yyerror((char *)name);
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
 bool isDecl_const(const char *name) {
  return isDecl_ident(name, consts, consts_index);
 }
 int  getValue_const(const char * name) {
  return getAdr_ident(name, consts, consts_index);
 }
 void load_variable(const char * name, int type) {
  //fprintf(stderr, "Load Variable %s\n", name);
  decl_ident(name, variables, variables_index, type, 0, false);
  variables_index++;
 }
 void decl_variable(const char * name, int type) {
  decl_ident(name, variables, variables_index, variables_index, type, true);
  variables_index++;
 }
 void decl_fonction(const char * name, int type) {
  decl_ident(name, fonctions, fonctions_index, jump_label-1 /* Le label a deja ete incremente, => call-1 */ , type, false); 
  fonctions_index++;
 }

 void decl_const( const char *name, int value) {
  decl_ident(name, consts, consts_index, consts_index, cst, false);
  consts[consts_index].adr = value;
  consts_index++;
 }

  void clear_ident(ident_t* idents, int * size) {
    int i;
    for(i = 0; i < *size; i++) {
      idents[i].name[0] = '\0';
    }
    *size = 0;
  }


  void setVariable_mlc(const char *name, int size) {
    int i, index;
    for (i=0; i < variables_index; i++) {
      if (strcmp(variables[i].name, name) == 0) {
           index = i;
           break;
      }
    }
    if((tas_index+1)+size > TAS) {
      fprintf(stderr, "MAX SIZE EXECED\n");
      return;
    }

    variables[index].type = mlc;
    variables[index].adr = tas_index+1;

    // Ajout de la size en tete
    instarg("SET", tas_index);
    inst("SWAP");
    instarg("SET", size);
    inst("SAVE");

    tas_index += size+1;

  }

  const char * getLoader(const char * name) {
    int i;
      for (i=0; i < variables_index; i++) {
      if (strcmp(variables[i].name, name) == 0) {
           return (variables[i].type==mlc)?"LOAD":"LOADR";
      }
    }
    return "LOADR";
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
  clear_ident(consts, &consts_index);

  /* TODO INIATILISE MAIN in FONCTIONS */
  instarg("ALLOC", TAS);
  instarg("JUMP", 0);
  yyparse();
  endProgram();
  return 0;
}
