%define parse.error verbose
%code top{
    #include <iostream>
    #include <queue>
    #include <assert.h>
    #include "parser.h"
    extern Ast ast;
    extern char* yytext;
    int yylex();
    int yyerror( char const * );
}

%code requires {
    #include "Ast.h"
    #include "SymbolTable.h"
    #include "Type.h"
}

%union {
    int itype;
    char* strtype;
    StmtNode* stmttype;
    ExprNode* exprtype;
    Type* type;
    IDList* idList;
    InitIDList* initIdList;
    ParaList* paraList;
}

%start Program
%token <strtype> ID 
%token <itype> INTEGER
%token IF ELSE
%token WHILE
%token CONST
%token COMMA
%token INT VOID
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token ASSIGN ADD SUB MUL DIV MOD AND OR LESS GREATER NOTEQUAL EQUAL LESSEQ GREATEREQ NOT
%token RETURN

%nterm <stmttype> Stmts Stmt AssignStmt BlockStmt IfStmt ReturnStmt DeclStmt FuncDef InitStmt WhileStmt
FuncCall FuncAssignStmt EmptyStmt
%nterm <exprtype> Exp AddExp Cond LOrExp PrimaryExp LVal RelExp LAndExp MulExp ParenExp NotExp /*FuncExpr*/
%nterm <type> Type
%nterm <itype> Intint
%nterm <idList> IDList
%nterm <initIdList> InitIDList
%nterm <paraList> ParaList

%precedence THEN
%precedence ELSE
%%
Program
    : Stmts {
        ast.setRoot($1);
    }
    ;
Stmts
    : Stmt {$$=$1;}
    | Stmts Stmt{
        $$ = new SeqNode($1, $2);
    }
    ;
Stmt
    : AssignStmt {$$=$1;}
    | BlockStmt {$$=$1;}
    | IfStmt {$$=$1;}
    | ReturnStmt {$$=$1;}
    | DeclStmt {$$=$1;}
    | FuncDef {$$=$1;}
    | FuncCall {$$=$1;}
    | FuncAssignStmt {$$=$1;}
    | InitStmt {$$=$1;}
    | WhileStmt {$$=$1;}
    | EmptyStmt {$$=$1;}
    ;
LVal
    : ID {
        SymbolEntry *se;
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
            delete [](char*)$1;
            assert(se != nullptr);
        }
        $$ = new Id(se);
        delete []$1;
    }
    ;
AssignStmt
    :
    LVal ASSIGN Exp SEMICOLON {
        $$ = new AssignStmt($1, $3);
    }
    ;
IfStmt
    : IF LPAREN Cond RPAREN Stmt %prec THEN {
        $$ = new IfStmt($3, $5);
    }
    | IF LPAREN Cond RPAREN Stmt ELSE Stmt {
        $$ = new IfElseStmt($3, $5, $7);
    }
    ;
Exp
    :
    AddExp {$$ = $1;}
    ;
Cond
    :
    LOrExp{$$=$1;}
    ;
Intint
    :
    INTEGER {$$=$1;}
    ;
PrimaryExp
    :
    LVal {
        $$ = $1;
    }
    | Intint {
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
        $$ = new Constant(se);
    }
    ;
    /* | FuncExpr{
        $$=$1;
    } */
/* FuncExpr
    :
    ID LPAREN IDList RPAREN{
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se, $3);
        delete []$1;   
    }
    | ID LPAREN RPAREN{
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se);
        delete []$1;   
    }
    |
    LPAREN ID LPAREN IDList RPAREN RPAREN{
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se, $4);
        delete []$2;   
    }
    | LPAREN ID LPAREN RPAREN RPAREN{
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se);
        delete []$2;   
    }
    ; */
NotExp
    :
    ParenExp {$$ = $1;}
    |
    NOT NotExp {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new SingelExpr(se, SingelExpr::NOT, $2);        
    }
    |
    SUB NotExp {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new SingelExpr(se, SingelExpr::MIN, $2);  
    }
    ;
MulExp
    :
    NotExp {$$=$1;}
    |
    MulExp MUL NotExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MUL, $1, $3);
    }
    |
    MulExp DIV NotExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::DIV, $1, $3);
    }
    |
    MulExp MOD NotExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MOD, $1, $3);
    }
    ;
AddExp
    :
    MulExp{$$=$1;}
    |
    AddExp ADD MulExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::ADD, $1, $3);
    }
    |
    AddExp SUB MulExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::SUB, $1, $3);
    }
    ;
ParenExp
    :
    PrimaryExp {$$ = $1;}
    |
    LPAREN PrimaryExp RPAREN{$$=$2;}
    |
    LPAREN ParenExp MUL PrimaryExp RPAREN
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MUL, $2, $4);
    }
    |
    LPAREN ParenExp DIV PrimaryExp RPAREN
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::DIV, $2, $4);
    }
    |
    LPAREN ParenExp MOD PrimaryExp RPAREN
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MOD, $2, $4);
    }
    |
    LPAREN ParenExp ADD PrimaryExp RPAREN
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::ADD, $2, $4);
    }
    |
    LPAREN ParenExp SUB PrimaryExp RPAREN
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::SUB, $2, $4);
    }
    ;
RelExp
    :
    AddExp {$$ = $1;}
    |
    RelExp LESSEQ AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESSEQ, $1, $3);
    }
    |
    RelExp GREATEREQ AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::GREATEREQ, $1, $3);
    }
    |
    RelExp LESS AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
    }
    |
    RelExp GREATER AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::GREATER, $1, $3);
    }
    |
    RelExp EQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::EQUAL, $1, $3);
    }
    |
    RelExp NOTEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::NOTEQUAL, $1, $3);
    }
    ;
IDList
    :
    ID {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::voidType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        std::queue<SymbolEntry*> idList;
        idList.push(se);
        $$ = new IDList(idList);
        delete []$1;
    }
    |
    IDList COMMA ID {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::voidType, $3, identifiers->getLevel());
        identifiers->install($3, se);
	    std::queue<SymbolEntry*> idList = $1->getList();
        idList.push(se);
        $$ = new IDList(idList);
        delete []$3;
    }
    ;
InitIDList
    :
    ID ASSIGN Exp {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::voidType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        std::queue<SymbolEntry*> idList;
        std::queue<ExprNode*> nums;
        idList.push(se);
        nums.push($3);
        $$ = new InitIDList(idList, nums);
        delete $1;
    }
    |
    InitIDList COMMA ID ASSIGN Exp {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::voidType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        std::queue<SymbolEntry*> idList = $1->getList();
        std::queue<ExprNode*> nums = $1->getNums();
        idList.push(se);
        nums.push($5);
        $$ = new InitIDList(idList, nums);
        delete $3;
    }
    ;
ParaList
    :
    Type ID {
        SymbolEntry *se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se);
        std::queue<SymbolEntry*> idList;
        idList.push(se);
        $$ = new ParaList(idList);
        delete []$2;
    }
    |
    ParaList COMMA Type ID{
        SymbolEntry *se = new IdentifierSymbolEntry($3, $4, identifiers->getLevel());
        identifiers->install($4, se);
        std::queue<SymbolEntry*> idList = $1->getList();
        idList.push(se);
        $$ = new ParaList(idList);
        delete $4;
    }
    |
    %empty {
        $$ = new ParaList();
    }
    ;
BlockStmt
    :   LBRACE 
        {identifiers = new SymbolTable(identifiers);} 
        Stmts RBRACE 
        {
            $$ = new CompoundStmt($3);
            SymbolTable *top = identifiers;
            identifiers = identifiers->getPrev();
            delete top;
        }
    ;
ReturnStmt
    :
    RETURN Exp SEMICOLON {
        $$ = new ReturnStmt($2);
    }
    | RETURN FuncCall {
        $$ = new ReturnStmt($2);
    }
    ;
LAndExp
    :
    RelExp {$$ = $1;}
    |
    LAndExp AND RelExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::AND, $1, $3);
    }
    ;
LOrExp
    :
    LAndExp {$$ = $1;}
    |
    LOrExp OR LAndExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::OR, $1, $3);
    }
    ;
Type
    : INT {
        $$ = TypeSystem::intType;
    }
    | VOID {
        $$ = TypeSystem::voidType;
    }
    | CONST INT{
    	$$ = TypeSystem::constIntType;
    }
    ;
DeclStmt
    :
    Type IDList SEMICOLON {
        $2->setType($1);
        $$ = new DeclStmt($2);
    }
    ;
EmptyStmt
    :
    AddExp SEMICOLON {
        $$ = new EmptyStmt($1);
    }
    |
    SEMICOLON {
        $$ = new EmptyStmt();
    }
    ;
FuncDef
    :
    Type ID {
        Type *funcType;
        funcType = new FunctionType($1,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
    }
    LPAREN ParaList RPAREN BlockStmt
    {   
        SymbolEntry *se;
        se = identifiers->lookup($2);
        $$ = new FunctionDef(se, $5, $7);
        SymbolTable *top = identifiers;
        identifiers = identifiers->getPrev();
        delete top;
        delete []$2;
    }
    ;
FuncAssignStmt
    :
    LVal ASSIGN ID LPAREN RPAREN SEMICOLON {
    	Type *funcType;
        funcType = new FunctionType(TypeSystem::intType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        identifiers = new SymbolTable(identifiers);
        $$ = new FuncAssignStmt($1, new FuncCall(se));
        delete []$3;
    } 
    | LVal ASSIGN ID LPAREN IDList RPAREN SEMICOLON {
    	Type *funcType;
        funcType = new FunctionType(TypeSystem::intType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        identifiers = new SymbolTable(identifiers);
        $$ = new FuncAssignStmt($1, new FuncCall(se, $5));
        delete []$3;
    }
    | Type ID ASSIGN ID LPAREN RPAREN SEMICOLON {
    	Type *funcType;
        funcType = new FunctionType(TypeSystem::intType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $4, identifiers->getLevel());
        identifiers->install($4, se);
        identifiers = new SymbolTable(identifiers);
        SymbolEntry *se0 = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se0);
        $$ = new FuncAssignStmt($1, new Id(se0), new FuncCall(se));
        delete []$4;
    }
    | Type ID ASSIGN ID LPAREN IDList RPAREN SEMICOLON {
        
    	Type *funcType;
        funcType = new FunctionType(TypeSystem::intType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $4, identifiers->getLevel());
        identifiers->install($4, se);
        identifiers = new SymbolTable(identifiers);
        SymbolEntry *se0 = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se0);
        $$ = new FuncAssignStmt($1, new Id(se0), new FuncCall(se, $6));
        delete []$4;
    }
    ;
FuncCall
    :
    ID LPAREN IDList RPAREN SEMICOLON {
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se, $3);
        delete []$1;   
    }
    | ID LPAREN RPAREN SEMICOLON {
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se);
        delete []$1;   
    }
    |
    LPAREN ID LPAREN IDList RPAREN RPAREN SEMICOLON {
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se, $4);
        delete []$2;   
    }
    | LPAREN ID LPAREN RPAREN RPAREN SEMICOLON {
        Type *funcType;
        funcType = new FunctionType(TypeSystem::voidType,{});
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
    	$$ = new FuncCall(se);
        delete []$2;   
    }
    ;
InitStmt
    :
    Type InitIDList SEMICOLON {
        $2->setType($1);
        $$ = new InitStmt($2);
        // delete []$2;
    }
    ;
WhileStmt
    :
    WHILE LPAREN Cond RPAREN Stmt{
    	$$ = new WhileStmt($3, $5);
    }
    ;
%%

int yyerror(char const* message)
{
    std::cerr<<message<<std::endl;
    std::cout << yytext;
    return -1;
}
