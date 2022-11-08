#include "Ast.h"
#include "SymbolTable.h"
#include <string>
#include "Type.h"

extern FILE *yyout;
int Node::counter = 0;

Node::Node()
{
    seq = counter++;
}

void Ast::output()
{
    fprintf(yyout, "program\n");
    if(root != nullptr)
        root->output(4);
}

void SingelExpr::output(int level)
{
    std::string op_str;
    switch(op)
    {
        case NOT:
            op_str = "not";
            break;
        case MIN:
            op_str = "minus";
            break;
    }
    fprintf(yyout, "%*cSingelExpr\top: %s\n", level, ' ', op_str.c_str());
    expr1->output(level + 4);
}

void BinaryExpr::output(int level)
{
    std::string op_str;
    switch(op)
    {
        case ADD:
            op_str = "add";
            break;
        case SUB:
            op_str = "sub";
            break;
        case MUL:
            op_str = "mul";
            break;
        case DIV:
            op_str = "div";
            break;
        case MOD:
            op_str = "mod";
            break;     
        case AND:
            op_str = "and";
            break;
        case OR:
            op_str = "or";
            break;
        case LESS:
            op_str = "less";
            break;
        case GREATER:
            op_str = "greater";
            break; 
        case LESSEQ:
            op_str = "lesseq";
            break;
        case GREATEREQ:
            op_str = "greatereq";
            break;
        case EQUAL:
            op_str = "equal";
            break;
        case NOTEQUAL:
            op_str = "notequal";
            break;
    }
    fprintf(yyout, "%*cBinaryExpr\top: %s\n", level, ' ', op_str.c_str());
    expr1->output(level + 4);
    expr2->output(level + 4);
}

void Constant::output(int level)
{
    std::string type, value;
    type = symbolEntry->getType()->toStr();
    value = symbolEntry->toStr();
    fprintf(yyout, "%*cIntegerLiteral\tvalue: %s\ttype: %s\n", level, ' ',
            value.c_str(), type.c_str());
}

void Id::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}

void IDList::output(int level)
{
    std::string name, type;
    int scope;
    while(!this->getList().empty()) {
    	SymbolEntry* se;
        se = this->idList.front();
    	name = se->toStr();
    	type = se->getType()->toStr();
    	scope = dynamic_cast<IdentifierSymbolEntry*>(se)->getScope();
    	this->idList.pop();
    	fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',
    	        name.c_str(), scope, type.c_str());
    }
}

void IDList::setType(Type* type){
    std::queue<SymbolEntry*> idl;
        while(!this->idList.empty()){
        SymbolEntry* se=this->idList.front();
        se->setType(type);
        this->idList.pop();
        idl.push(se);
        }
        this->idList=idl;
}

void InitIDList::output(int level)
{
    std::string name, type;
    int scope;
    while(!this->getList().empty()) {
    	SymbolEntry* se = this->idList.front();
    	name = se->toStr();
    	type = se->getType()->toStr();
    	scope = dynamic_cast<IdentifierSymbolEntry*>(se)->getScope();
    	this->idList.pop();
    	fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',name.c_str(), scope, type.c_str());
        this->nums.front()->output(level + 4);
        this->nums.pop();
    }
}

void InitIDList::setType(Type* type)
{
    std::queue<SymbolEntry*> idl;
        while(!this->idList.empty()){
            SymbolEntry* se=this->idList.front();
            se->setType(type);
            this->idList.pop();
            idl.push(se);
        }
        this->idList=idl;
}

void ParaList::output(int level)
{
    std::string name, type;
    int scope;
    while(!this->getList().empty()) {
    	SymbolEntry* se = this->idList.front();
    	name = se->toStr();
    	type = se->getType()->toStr();
    	scope = dynamic_cast<IdentifierSymbolEntry*>(se)->getScope();
    	this->idList.pop();
    	fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',name.c_str(), scope, type.c_str());
    }
}

void CompoundStmt::output(int level)
{
    fprintf(yyout, "%*cCompoundStmt\n", level, ' ');
    stmt->output(level + 4);
}

void SeqNode::output(int level)
{
    fprintf(yyout, "%*cSequence\n", level, ' ');
    stmt1->output(level + 4);
    stmt2->output(level + 4);
}

void DeclStmt::output(int level)
{
    fprintf(yyout, "%*cDeclStmt\n", level, ' ');
    idList->output(level + 4);
}

void EmptyStmt::output(int level)
{
    fprintf(yyout, "%*cEmptyStmt\n", level, ' ');
    if(expr!= nullptr){
        expr->output(level + 4);
    }
}

void InitStmt::output(int level)
{
    fprintf(yyout, "%*cInitStmt\n", level, ' ');
    initIDList->output(level + 4);
}

void IfStmt::output(int level)
{
    fprintf(yyout, "%*cIfStmt\n", level, ' ');
    cond->output(level + 4);
    thenStmt->output(level + 4);
}

void IfElseStmt::output(int level)
{
    fprintf(yyout, "%*cIfElseStmt\n", level, ' ');
    cond->output(level + 4);
    thenStmt->output(level + 4);
    elseStmt->output(level + 4);
}

void ReturnStmt::output(int level)
{
    fprintf(yyout, "%*cReturnStmt\n", level, ' ');
    if(retValue!=nullptr)
    retValue->output(level + 4);
    if(funcCall!=nullptr)
    funcCall->output(level + 4);
}

void AssignStmt::output(int level)
{
    fprintf(yyout, "%*cAssignStmt\n", level, ' ');
    lval->output(level + 4);
    expr->output(level + 4);
}

void FunctionDef::output(int level)
{
    std::string name, type;
    name = se->toStr();
    type = se->getType()->toStr();
    fprintf(yyout, "%*cFunctionDefine function name: %s, type: %s\n", level, ' ', 
            name.c_str(), type.c_str());
    paraList->output(level + 4);
    stmt->output(level + 4);
}

void FuncCall::output(int level)
{
    fprintf(yyout, "%*cFunctionCall function name: %s, type: %s\n", level, ' ');
}

void FuncExpr::output(int level)
{
    std::string name, type;
    name = se->toStr();
    type = se->getType()->toStr();
    fprintf(yyout, "%*cFunctionExpr function name: %s, type: %s\n", level, ' ', 
            name.c_str(), type.c_str());
    if(idList!=nullptr)
    idList->output(level + 4);
}

void FuncAssignStmt::output(int level)
{
    fprintf(yyout, "%*cFuncAssignStmt\n", level, ' ');
    if(lval!=nullptr)
    lval->output(level + 4);
    if(id!=nullptr)
    id->output(level + 4);
    stmt->output(level + 4);
}

void WhileStmt::output(int level)
{
    fprintf(yyout, "%*cWhileStmt\n", level, ' ');
    cond->output(level + 4);
    stmt->output(level + 4);
}






