sql_lex:
	flex ./lex/sql.lex
	gcc lex.yy.c -o lexer -lfl