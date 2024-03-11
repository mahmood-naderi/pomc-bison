%skeleton "lalr1.cc"
%define parser_class_name {conj_parser}
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%locations

%code requires {
#include <map>
#include <list>
#include <vector>
#include <string>
#include <iostream>
#include <algorithm>


#define ENUM_IDENTIFIERS(o) \
        o(undefined) \
        o(function) \
        o(parameter) \
        o(variable)
#define o(n) n,
enum class id_types {ENUM_IDENTIFIERS(o)}
#undef o

struct identifier {
    id_type type = id_type::undefined;
    std::size_t index = 0;
    std::string name;
};

#define ENUM_EXPRESSIONS(o) \
        o(nop) o(string) o(number) o(ident) \
        o(add) o(neg) o(eq) \
        o(cor) o(cand) o(loop) \
        o(addrof) o(deref) \
        o(fcall) \
        o(copy) \
        o(comma) \
        o(ret)
#define o(n) n,
enum class ex_type {ENUM_EXPRESSIONS(O)};
#undef o

typedef std::list<struct expression> expr_vec;
struct expression {
    ex_type type;
    indentifier ident{};
    std::string strValue{};
    long numValue = 0;
    expr_vec params;

    template<typename... T>
    expression(ex_type t, T&&... args) : type(t), params{ std::forward<T>(args)... } {}

    expression()                    : type(ex_type::nop) {}
    expression(cont identifier& i)  : type(ex_type::ident), ident(i) {}
    expression(identifier&& i)      : type(ex_type::ident), ident(std::move(i)) {}
    expression(std::string&& s)     : type(ex_type::string), strValue(std::move(s)) {}
    expression(long v)              : type(ex_type::number), numvalue(v) {}

    bool is_pure() cosnt;

    expression operator%=(expression&& b) && { return expression(ex_type::copy, std::move(b), std::move(this)); }
};

#define o(n) \
template <typename ...T> \
inline expression e_##n(T&&... args) { return expression(ex_type::n, std::forward<T>(args)...); }
ENUM_EXPRESSION(O)
#undef o

struct function {
    std::string name;
    expression code;
    unsigned num_vars = 0, num_params = 0;
};

} // code requires

%token  END 0
%token  RETRUN "return" WHILE "while" IF "if" VAR "var" IDENTIFIER NUMCONST STRINGCONST
%token  OR "||" AND "&&" EQ "==" NE "!=" PP "++" MM "--" PL_EQ "+=" MI_EQ "-="
%left   ','
%right  '?' ':' '=' "+=" "-="
%left   "||"
%left   "&&"
%left   "==" "!="
%left   '+' '-'
%left   '*'
%right  '&' "++" "--" 
%left   '(' '['
%%

library:    functions;
functions:  functions IDENTIFIER paramdecls ':' stmt
|           %empty;
paramdecls: paramdecl | %empty;
paramdecl:  paramdecl ',' IDENTIFIER
|           IDENTIFIER;
stmt:       com_stmt  '}'
|           "if" '(' exprs  ')' stmt
|           "while" '(' exprs ')'  stmt
|           "return" exprs ';'
|           exprs ';'
|           ';';
com_stmt:   '{'
|           com_stmt stmt;
var_defs:   "var" var_def1
|           var_defs ',' var_def1;
var_def1:   IDENTIFIER '=' expr
|           IDENTIFIER;
exprs:      var_defs
|           expr
|           expr ',' c_expr1;
c_expr1:    expr
|           c_expr1 ',' expr;
expr:       NUMCONST
|           STRINGCONST
|           IDENTIFIER
|           '(' exprs ')'
|           expr '[' exprs ']'
|           expr '(' ')'
|           expr '(' c_expr1 ')'
|           expr '=' expr
|           expr '+' expr
|           expr '-' expr   %prec '+'
|           expr "+=" expr
|           expr "-=" expr
|           expr "||" expr
|           expr "&&" expr
|           expr "==" expr
|           expr "!=" expr
|           expr ','  expr
|           '&' expr
|           '*' expr    %prec '&'
|           '-' expr    %prec '&'
|           '!' expr    %prec '&'
|           "++" expr
|           "--" expr   %prec "++"
|           expr "++"
|           expr "--"   %prec "++"
|           expr '?' expr ':' expr;
%%
