%{
#include "s_compilator.h"
%}
%%
[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&(yylval.entier)); return NUM;}

"if" 			{return IF;}
"else"			{return ELSE;}
"print"			{return PRINT;}
"main"			{return MAIN; }
"void"          {return VOID; }
"entier"        {return ENTIER; }
"pointeur"      {return POINTEUR; }
"while"         {return WHILE; }

";"       {return PV; }
"const"   {return CONST; }
"return"  {return RETURN; }
"read"    {return READ; }

"free"    {return FREE; }
"malloc"  {return MALLOC; }

"("			{return LPAR; }
")"			{return RPAR; }
","  {return VRG; }
"{"  {return LACC; }
"}"  {return RACC; }
"["  {return LSQB; }
"]"  {return RSQB; }

"<"  { yylval.comparator = lt;  return COMP; }
">"  { yylval.comparator = gt;  return COMP; }
"<=" { yylval.comparator = lte; return COMP; }
">=" { yylval.comparator = gte; return COMP; }
"==" { yylval.comparator = eq;  return COMP; }
"!=" { yylval.comparator = neq; return COMP; }

"="             {return EGAL ; }
"+"  { yylval.operator = add; return ADDSUB; }
"-"  { yylval.operator = sub; return ADDSUB; }
"/"  { yylval.operator = divide; return DIV; }
"*"  { yylval.operator = times; return STAR; }
"%"  { yylval.operator = mod; return MOD; }

[a-zA-Z][a-zA-Z0-9_]* { yylval.indent = yytext;   return IDENT;  }


. return yytext[0];
%%
