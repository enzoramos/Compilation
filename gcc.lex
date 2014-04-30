%%
[ \t]+ ;
[<=|>=|==|!=]       {
	switch ( *yytext ) {
		case '<': yylval.comparator = lte; break;
		case '>': yylval.comparator = gte; break;
		case '=': yylval.comparator = eq;  break;
		case '!': yylval.comparator = neq; break;
		default: exit( 1 );
	}
	return COMP;
}
[<>]                {
	switch ( *yytext ) {
		case '<': yylval.comparator = lt; break;
		case '>': yylval.comparator = gt; break;
		default: exit( 1 );
	}
	return COMP;
}
[\-\+&\*/%]             {
	switch ( *yytext ) {
		case '+': yylval.operator = add; return ADDSUB;
		case '-': yylval.operator = sub; return ADDSUB;
		case '*': yylval.operator = tim; return STAR;
		case '/': yylval.operator = div; return DIV;
		case '%': yylval.operator = mod; return MOD;
		case '&': return ADR;
		default: exit( 1 );
	}
}
[a-zA-Z][a-zA-Z0-9_]* { yylval.ident = yytext;   return IDENT;  }


[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&yylval); return NOMBRE_ENTIER;}
"if" {return IF;}
"else" {return ELSE;}
"print" {return PRINT;}
"main" {return MAIN; }
"(" {return LPAR; }
")"  {return RPAR; }
. return yytext[0];
%%


.|\n return yytext[0];
%%
