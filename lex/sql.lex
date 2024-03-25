%{
#include <stdio.h>
#include <string.h>

extern FILE* yyin;

void print(char* type_ ) {
    fprintf(yyout, "\n[%s]\n-- %s\n", type_, yytext);  
}
%}

%s CODE_BLOCK
%s PROCEDURE_NAME
%s PROCEDURE_PARAM
%s PROCEDURE_SETTING
%s FINISHED

STRING      \"[a-zA-Z0-9_\.]+\"
COMMENT     "/*"([^*]|"*"+[^*/])*"*"+"/"
 
%%
[ \t\n]                                             ;
{COMMENT}                                           { print("COMMENT"); }

<INITIAL>"PROCEDURE"                                { BEGIN(PROCEDURE_NAME); } 

<PROCEDURE_NAME>{STRING}                            { print("PROCEDURE_NAME"); }
<PROCEDURE_NAME>"("                                 { BEGIN(PROCEDURE_PARAM); }

<PROCEDURE_PARAM>[IN|OUT].+","                      { print("PROCEDURE_PARAM"); }
<PROCEDURE_PARAM>")"                                { BEGIN(PROCEDURE_SETTING); }

<PROCEDURE_SETTING>"BEGIN"[\t\n]                    { BEGIN(CODE_BLOCK); }
<PROCEDURE_SETTING>.+[\t\n]                         { print("PROCEDURE_SETTING"); }

<CODE_BLOCK>"END"                                   { BEGIN(FINISHED); }
<CODE_BLOCK>"DECLARE"[^;]*";"                       { print("DECLARE"); }
<CODE_BLOCK>"IF"(.|\n)*"END IF;"                    { print("IF-ELSE"); }
<CODE_BLOCK>"CALL"[^;]*";"                          { print("CALL"); }
<CODE_BLOCK>[A-Z][^;]*";"                           { print("OTHERS"); }
%%

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s input_file\n", argv[0]);
        return 1;
    }

    FILE* file = fopen(argv[1], "r");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    yyin = file;

    yylex();

    fclose(file);
    return 0;
}