%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void yyerror(char *);
int yylex(void);


struct Obj expressionOperation(struct Obj expr1, char op, struct Obj expr2);
struct Obj getVariableValue(struct Obj variable);
int isVariableDeclared(struct Obj variable);
bool declareVariable(int type, struct Obj variable);
void setVariableValue(struct Obj variable, struct Obj expr);
void initializeVariable(int type, struct Obj variable, struct Obj expr);
void printVariable(struct Obj variable);
void printQuadruples(char operator, struct Obj operand1, struct Obj operand2, struct Obj *result);
void setVariableName(struct Obj *operand, int tempNumber);

int currentNumberofVariables = 0;

%}

%code requires {
    #include <stdbool.h>
    struct Obj
    {
        char vname[100];
        int type;
        int ival;
        float fval;
        char cval;
        char sval[100];
        bool initialized;
        int tempNumber;
        bool isDummy;
    };

    struct Obj symbolTable[100];
}

%union {
struct Obj Object;
int iValue;
char cValue;
char sValue[100];
};

%token <Object> INTEGER STRING FLOAT CHARACTER VARIABLE
%token <iValue> INT CHAR STR FLT PRINT
%token <cValue> OP EQU SCLN

%left '+' '-'
%left '*' '/'
%type <Object> expr statement
%type <iValue> typeIdentifier
%%
program:
program statement '\n'
|
;

statement:
typeIdentifier VARIABLE EQU expr { initializeVariable($1, $2, $4); printf("\n\n");}
| typeIdentifier VARIABLE { declareVariable($1, $2);}
| VARIABLE EQU expr { setVariableValue($1,$3); printf("\n\n");}
| PRINT VARIABLE { printVariable($2);}
| expr
;

expr:
INTEGER
| FLOAT 
| CHARACTER 
| STRING
| VARIABLE { $$ = getVariableValue($1); }
| expr OP expr { $$ = expressionOperation($1,$2,$3); }
;

typeIdentifier:
INT 
| FLT 
| CHAR
| STR 
;

%%
void yyerror(char *s) {
fprintf(stderr, "%s\n", s);
}

// int main(void) {
// yyparse();
// return 0;
// }

int main(int argc, char *argv[]) {
extern FILE *yyin;
yyin = fopen(argv[1], "r");
yyparse();
fclose(yyin);
return 0;
}

int isVariableDeclared(struct Obj variable) {

     for(int i = 0 ; i < currentNumberofVariables; i++) {
        if(strcmp(symbolTable[i].vname, variable.vname) == 0) {
            return i;
        }
    }
    return -1;
}

bool declareVariable(int type, struct Obj variable) {

    if (isVariableDeclared(variable) == -1) {
        symbolTable[currentNumberofVariables].type = type;
        strcpy(symbolTable[currentNumberofVariables].vname, variable.vname);
        symbolTable[currentNumberofVariables].initialized = false;
        currentNumberofVariables++;
        return true;
    }
    else yyerror("Redeclaration of variable");
    return false;
}

void setVariableValue(struct Obj variable, struct Obj expr) {
    
    int variableIndex = isVariableDeclared(variable);
    if (variableIndex != -1) {
        if(expr.initialized) {

            if(symbolTable[variableIndex].type == expr.type) {
                if (symbolTable[variableIndex].type == INTEGER) symbolTable[variableIndex].ival = expr.ival;
                else if (symbolTable[variableIndex].type == FLOAT) symbolTable[variableIndex].fval = expr.fval;
                else if (symbolTable[variableIndex].type == CHARACTER) symbolTable[variableIndex].cval = expr.cval;
                else if (symbolTable[variableIndex].type == STRING) strcpy(symbolTable[variableIndex].sval,expr.sval);

                symbolTable[variableIndex].initialized = true;
                struct Obj dummy;
                strcpy(dummy.vname, "");
                dummy.isDummy = true;
                dummy.tempNumber = 0;
                printQuadruples('=', expr, dummy, &variable);
            }
        }
    }
    else yyerror("Cannot set value of undeclared variable");
}

void initializeVariable(int type, struct Obj variable, struct Obj expr) {

    if(type == expr.type) {
        if(declareVariable(type, variable)) setVariableValue(variable, expr);
    }
    else yyerror("Type mismatch");
}

void setVariableName(struct Obj *operand, int tempNumber) {

    sprintf(operand->vname, "t%d", tempNumber);

    char operandValue[100];
    if(operand->type == INTEGER) sprintf(operandValue, "%d", operand->ival);
    else if (operand->type == FLOAT) sprintf(operandValue, "%f", operand->fval);
    else if (operand->type == STRING) strcpy(operandValue, operand->sval);
    else if (operand->type == CHARACTER) {
        operandValue[0] = operand->cval;
        operandValue[1] = '\0';
    }

    
    printf("Operator: = \t Operand 1: %s \t Operand 2: \t Result: %s \n", operandValue, operand->vname);
}

void printQuadruples(char operator, struct Obj operand1, struct Obj operand2, struct Obj *result) {

    int tempNumber = 0;
    if (operand1.tempNumber > tempNumber) tempNumber = operand1.tempNumber;
    if (operand2.tempNumber > tempNumber) tempNumber = operand2.tempNumber;

    if(strcmp(operand1.vname, "") == 0) setVariableName(&operand1, ++tempNumber);
    if(strcmp(operand2.vname, "") == 0 && operand2.isDummy == false) setVariableName(&operand2, ++tempNumber);

    if(strcmp(result->vname, "") == 0) {
        sprintf(result->vname, "t%d", ++tempNumber);
        result->tempNumber = tempNumber;
    }

    printf("Operator: %c \t Operand 1: %s \t Operand 2: %s \t Result: %s \n", operator, operand1.vname, operand2.vname, result->vname);

    tempNumber = 0;
}

struct Obj expressionOperation(struct Obj expr1, char op, struct Obj expr2) {
    
    
    struct Obj temp;
    strcpy(temp.vname, "");

    if(expr1.initialized && expr2.initialized) {

        if(expr1.type != expr2.type) {
        yyerror("Type mismatch\n");
        }
        else {

            if( expr1.type == INTEGER ) {
                temp.type = INTEGER;
                if (op == '+') temp.ival = expr1.ival + expr2.ival;
                else if (op == '-') temp.ival = expr1.ival - expr2.ival;
                else if (op == '*') temp.ival = expr1.ival * expr2.ival;
                else if (op == '/') temp.ival = expr1.ival / expr2.ival;
                temp.initialized = true;
                printQuadruples(op, expr1, expr2, &temp);
            }
            else if( expr1.type == FLOAT ) {
                temp.type = FLOAT;
                if (op == '+' ) temp.fval = expr1.fval + expr2.fval;
                else if (op == '-') temp.fval = expr1.fval - expr2.fval;
                else if (op == '*') temp.fval = expr1.fval * expr2.fval;
                else if (op == '/') temp.fval = expr1.fval / expr2.fval;
                temp.initialized = true;
                printQuadruples(op, expr1, expr2, &temp);
            }
            else {
                yyerror("Operation not supported\n");
            }

        }

    }

    return temp;
}

void printVariable(struct Obj variable) {

    int variableIndex = isVariableDeclared(variable);
    if(variableIndex != -1) {
        if(symbolTable[variableIndex].initialized) {
            if(symbolTable[variableIndex].type == INTEGER) printf("%d", symbolTable[variableIndex].ival);
            else if(symbolTable[variableIndex].type == FLOAT) printf("%f", symbolTable[variableIndex].fval);
            else if(symbolTable[variableIndex].type == CHARACTER) printf("%c", symbolTable[variableIndex].cval);
            else if(symbolTable[variableIndex].type == STRING) printf(symbolTable[variableIndex].sval);
            printf("\n");
        }
        else yyerror("Cannot print uninitialized variable");
    }
    else yyerror("Cannot print undeclared variable");
}

struct Obj getVariableValue(struct Obj variable) {
    int variableIndex = isVariableDeclared(variable);
    struct Obj temp;
    temp.initialized = false;
    if(variableIndex != -1) {
        if(symbolTable[variableIndex].initialized) {
            return symbolTable[variableIndex]; 
        }
        else yyerror("Cannot use uninitialized variable");

    }
    else yyerror("Cannot use undeclared variable");
    return temp;
}