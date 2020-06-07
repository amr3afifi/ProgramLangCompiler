digit [0-9]
letter [A-Za-z]
%{
#include <stdlib.h>
#include <string.h>
void yyerror(char *);
#include "y.tab.h"
%}
%%

"int" { yylval.iValue = INTEGER; return INT; }

"str" { yylval.iValue = STRING; return STR; }

"char" { yylval.iValue = CHARACTER; return CHAR; }

"flt" { yylval.iValue = FLOAT; return FLT; }

"print" { yylval.iValue = PRINT; return PRINT; }

{letter}({letter}|{digit})* { strcpy(yylval.Object.vname, yytext); yylval.Object.tempNumber = 0; return VARIABLE; }

{digit}+[.]{digit}+ { yylval.Object.fval = atof(yytext); yylval.Object.type = FLOAT; strcpy(yylval.Object.vname, ""); 
yylval.Object.initialized = true; yylval.Object.tempNumber = 0; return FLOAT; }

{digit}+ { yylval.Object.ival = atoi(yytext); yylval.Object.type = INTEGER; strcpy(yylval.Object.vname, ""); 
yylval.Object.initialized = true; yylval.Object.tempNumber = 0; return INTEGER; }

\"[^"]\" { yylval.Object.cval = yytext[1]; yylval.Object.type = CHARACTER; strcpy(yylval.Object.vname, ""); yylval.Object.initialized = true;
yylval.Object.tempNumber = 0; return CHARACTER; }

\"[^"]*\" { memset(yylval.Object.sval, '\0', sizeof(yylval.Object.sval)); strncpy(yylval.Object.sval, yytext + 1, strlen(yytext) - 2); 
yylval.Object.type = STRING; strcpy(yylval.Object.vname, ""); yylval.Object.initialized = true; yylval.Object.tempNumber = 0; return STRING;}

[-+*/] { yylval.cValue = yytext[0]; return OP;}

[=] { yylval.cValue = yytext[0]; return EQU;}

[;] {yylval.cValue = yytext[0]; return SCLN;}

[()\n] { return *yytext; }

[ \t] ;

. yyerror("invalid character");
%%
int yywrap(void) {
return 1;
}