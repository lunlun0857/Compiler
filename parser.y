%define parse.error verbose
%code top{
    #include <iostream>
    #include <queue>
    #include <assert.h>
    #include "parser.h"
    extern Ast ast;
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
%token ADD SUB OR AND LESS ASSIGN
%token RETURN

%nterm <stmttype> Stmts Stmt AssignStmt BlockStmt IfStmt ReturnStmt DeclStmt FuncDef InitStmt WhileStmt FuncCallNoReturn FuncCallWithReturn
%nterm <exprtype> Exp AddExp Cond LOrExp PrimaryExp LVal RelExp LAndExp /*ParaExpr*/
%nterm <type> Type
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
    | FuncCallNoReturn {$$=$1;}
    | FuncCallWithReturn {$$=$1;}
    | InitStmt {$$=$1;}
    | WhileStmt {$$=$1;}
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
IDList
    :
    ID {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::intType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        std::queue<SymbolEntry*> idList;
        idList.push(se);
        $$ = new IDList(idList);
        delete []$1;
    }
    |
    IDList COMMA ID {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::intType, $3, identifiers->getLevel());
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
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::intType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        std::queue<SymbolEntry*> idList;
        std::queue<ExprNode*> nums;
        idList.push(se);
        nums.push($3);
        $$ = new InitIDList(idList, nums);
        // delete []$2;
    }
    |
    InitIDList COMMA ID ASSIGN Exp {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::intType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        std::queue<SymbolEntry*> idList = $1->getList();
        std::queue<ExprNode*> nums = $1->getNums();
        idList.push(se);
        nums.push($5);
        $$ = new InitIDList(idList, nums);
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
        // delete []$2;
    }
    |
    ParaList COMMA Type ID{
        SymbolEntry *se = new IdentifierSymbolEntry($3, $4, identifiers->getLevel());
        identifiers->install($4, se);
        std::queue<SymbolEntry*> idList = $1->getList();
        idList.push(se);
        $$ = new ParaList(idList);
        // delete []$2;
    }
    ;
AssignStmt
    :
    LVal ASSIGN Exp SEMICOLON {
        $$ = new AssignStmt($1, $3);
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
IfStmt
    : IF LPAREN Cond RPAREN Stmt %prec THEN {
        $$ = new IfStmt($3, $5);
    }
    | IF LPAREN Cond RPAREN Stmt ELSE Stmt {
        $$ = new IfElseStmt($3, $5, $7);
    }
    ;
ReturnStmt
    :
    RETURN Exp SEMICOLON{
        $$ = new ReturnStmt($2);
    }
    ;
Exp
    :
    AddExp {$$ = $1;}

    ;
Cond
    :
    LOrExp {$$ = $1;}
    ;
PrimaryExp
    :
    LVal {
        $$ = $1;
    }
    | INTEGER {
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
        $$ = new Constant(se);
    }
    ;
AddExp
    :
    PrimaryExp {$$ = $1;}
    |
    AddExp ADD PrimaryExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::ADD, $1, $3);
    }
    |
    AddExp SUB PrimaryExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::SUB, $1, $3);
    }
    ;
RelExp
    :
    AddExp {$$ = $1;}
    |
    RelExp LESS AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
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
        $$ = new DeclStmt($2);
        // delete []$2;
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
        $$ = new FunctionDef(se, $4, $5);
        SymbolTable *top = identifiers;
        identifiers = identifiers->getPrev();
        delete top;
        delete []$2;
    }
    ;
FuncCallNoReturn
    :
    ID LPAREN RPAREN SEMICOLON
    {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::voidType, $1, identifiers->getLevel());
        identifiers->install($1, se);
        identifiers = new SymbolTable(identifiers);
    	delete []$1;
    }
    ;
FuncCallWithReturn
    :
    LVal ASSIGN ID LPAREN RPAREN SEMICOLON
    {
        SymbolEntry *se = new IdentifierSymbolEntry(TypeSystem::intType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        identifiers = new SymbolTable(identifiers);
        delete []$3;
    }
    ;
InitStmt
    :
    Type InitIDList SEMICOLON {
        // SymbolEntry *se;
        // se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        // identifiers->install($2, se);
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
    return -1;
}
