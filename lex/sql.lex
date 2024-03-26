%{
#include <stdio.h>
#include <string.h>

#define _CODE_BLOCK             0
#define _PROCEDURE_DEF          1
#define _DOUBLE_QUOTES_STRING   2
#define _PROCEDURE_PARAM        3
#define _PROCEDURE_SETTING      4
#define _PROCEDURE_NAME         5
#define _COMMENT                6

extern FILE* yyin;

#ifdef DISABLE_LEX_DEBUG
// work with bison
#define HANDLE_TOKEN(type_name, type_enum) \
    do { \
        return type_enum; \
    } while(0);

#else
// debug usage
#define HANDLE_TOKEN(type_name, type_enum) \
    do { \
        fprintf(yyout, "\n[%s]\n-- %s\n", type_name, yytext); \
    } while(0);

#endif

%}

%s CODE_BLOCK
%s CODE_BLCOK_CALL_PROCEDURE
%s PROCEDURE_NAME
%s PROCEDURE_PARAM
%s PROCEDURE_SETTING
%s FINISHED

STRING      \"[a-zA-Z0-9_\.]+\"
COMMENT     "/*"([^*]|"*"+[^*/])*"*"+"/"

%%
[ \t\n]                                             ;
{COMMENT}                                           { HANDLE_TOKEN("COMMENT", _COMMENT); }

<INITIAL>(?i:PROCEDURE)                             { BEGIN(PROCEDURE_NAME); } 

<PROCEDURE_NAME>{STRING}                            { HANDLE_TOKEN("PROCEDURE_NAME", _PROCEDURE_NAME); }
<PROCEDURE_NAME>"("                                 { BEGIN(PROCEDURE_PARAM); }

<PROCEDURE_PARAM>[(?i:IN)|(?i:OUT)].+","            { HANDLE_TOKEN("PROCEDURE_PARAM", _PROCEDURE_PARAM); }
<PROCEDURE_PARAM>")"                                { BEGIN(PROCEDURE_SETTING); }

<PROCEDURE_SETTING>(?i:BEGIN)[\t\n]                 { BEGIN(CODE_BLOCK); }
<PROCEDURE_SETTING>.+[\t\n]                         { HANDLE_TOKEN("PROCEDURE_SETTING", _PROCEDURE_SETTING); }

<CODE_BLOCK>(?i:END)                                { BEGIN(FINISHED); }
<CODE_BLOCK>(?i:DECLARE)[^;]*";"                    { HANDLE_TOKEN("DECLARE", _CODE_BLOCK); }
<CODE_BLOCK>(?i:IF)(.|\n)*(?i:END" "IF)";"          { HANDLE_TOKEN("IF-ELSE", _CODE_BLOCK); }
<CODE_BLOCK>(?i:CALL)[^;]*";"                       { HANDLE_TOKEN("CALL", _CODE_BLOCK); }
<CODE_BLOCK>[^ ;]*";"                               { HANDLE_TOKEN("OTHERS", _CODE_BLOCK); }
%%

#ifdef DISABLE_LEX_DEBUG

int yywrap() {
    return 0;
}

#endif

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