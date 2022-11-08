#ifndef __AST_H__
#define __AST_H__

#include <fstream>
#include "Type.h"
#include <queue>
#include "SymbolTable.h"

class SymbolEntry;

class Node
{
private:
    static int counter;
    int seq;
public:
    Node();
    int getSeq() const {return seq;};
    virtual void output(int level) = 0;
};

class ExprNode : public Node
{
protected:
    SymbolEntry *symbolEntry;
public:
    ExprNode() {};
    ExprNode(SymbolEntry *symbolEntry) : symbolEntry(symbolEntry){};
};

class BinaryExpr : public ExprNode
{
private:
    int op;
    ExprNode *expr1, *expr2;
public:
    enum {ADD, SUB, MUL, DIV, MOD ,AND, OR, LESS, GREATER, NOTEQUAL, EQUAL, LESSEQ, GREATEREQ};
    BinaryExpr(SymbolEntry *se, int op, ExprNode*expr1, ExprNode*expr2) : ExprNode(se), op(op), expr1(expr1), expr2(expr2){};
    void output(int level);
};

class SingelExpr : public ExprNode
{
private:
    int op;
    ExprNode *expr1;
public:
    enum {MIN,NOT};
    SingelExpr(SymbolEntry *se, int op, ExprNode*expr1) : ExprNode(se), op(op), expr1(expr1){};
    void output(int level);
};

class Constant : public ExprNode
{
public:
    Constant(SymbolEntry *se) : ExprNode(se){};
    void output(int level);
};

class Id : public ExprNode
{
public:
    Id(SymbolEntry *se) : ExprNode(se){};
    void output(int level);
};

class IDList
{
private:
    std::queue<SymbolEntry*> idList;
public:
    IDList(std::queue<SymbolEntry*> idList) : idList(idList){};
    void output(int level);
    std::queue<SymbolEntry*> getList() {return this->idList;};
    void setType(Type *type);
};

class InitIDList
{
private:
    std::queue<SymbolEntry*> idList;
    std::queue<ExprNode*> nums;
public:
    InitIDList(std::queue<SymbolEntry*> idList, std::queue<ExprNode*> nums) : idList(idList), nums(nums){};
    void output(int level);
    std::queue<SymbolEntry*> getList() {return this->idList;};
    std::queue<ExprNode*> getNums() {return this->nums;};
    void setType(Type *type);
};

class ParaList
{
private:
    std::queue<SymbolEntry*> idList;
public:
    ParaList(){};
    ParaList(std::queue<SymbolEntry*> idList) : idList(idList){};
    void output(int level);
    std::queue<SymbolEntry*> getList() {return this->idList;};
};

class StmtNode : public Node
{};

class CompoundStmt : public StmtNode
{
private:
    StmtNode *stmt;
public:
    CompoundStmt(StmtNode *stmt) : stmt(stmt) {};
    void output(int level);
};

class SeqNode : public StmtNode
{
private:
    StmtNode *stmt1, *stmt2;
public:
    SeqNode(StmtNode *stmt1, StmtNode *stmt2) : stmt1(stmt1), stmt2(stmt2){};
    void output(int level);
};

class DeclStmt : public StmtNode
{
private:
    IDList *idList;
public:
    DeclStmt(IDList *idList) : idList(idList){};
    void output(int level);
};

class EmptyStmt : public StmtNode
{
public:
    ExprNode* expr;
    EmptyStmt(){};
    EmptyStmt(ExprNode* expr) : expr(expr){};
    void output(int level);
};

class InitStmt : public StmtNode
{
private:
    InitIDList* initIDList;
public:
    InitStmt(InitIDList* initIDList) : initIDList(initIDList){};
    void output(int level);
};

class IfStmt : public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *thenStmt;
public:
    IfStmt(ExprNode *cond, StmtNode *thenStmt) : cond(cond), thenStmt(thenStmt){};
    void output(int level);
};

class IfElseStmt : public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *thenStmt;
    StmtNode *elseStmt;
public:
    IfElseStmt(ExprNode *cond, StmtNode *thenStmt, StmtNode *elseStmt) : cond(cond), thenStmt(thenStmt), elseStmt(elseStmt) {};
    void output(int level);
};

class AssignStmt : public StmtNode
{
private:
    ExprNode *lval;
    ExprNode *expr;
public:
    AssignStmt(ExprNode *lval, ExprNode *expr) : lval(lval), expr(expr) {};
    void output(int level);
};

class FunctionDef : public StmtNode
{
private:
    SymbolEntry *se;
    ParaList *paraList;
    StmtNode *stmt;
public:
    FunctionDef(SymbolEntry *se, ParaList *paraList, StmtNode *stmt) : se(se), paraList(paraList), stmt(stmt) {};
    void output(int level);
};

class FuncAssignStmt : public StmtNode
{
private:
    Type *type;
    Id *id;
    ExprNode *lval;
    StmtNode *stmt;
public:
    FuncAssignStmt(ExprNode *lval, StmtNode *stmt) : lval(lval), stmt(stmt) {};
    FuncAssignStmt(Type *type, Id *id, StmtNode *stmt) : type(type), id(id), stmt(stmt) {};
    void output(int level);
};

class FuncCall : public StmtNode
{
private:
    SymbolEntry *se;
    IDList *idList;
public:
    FuncCall(SymbolEntry *se) : se(se) {};
    FuncCall(SymbolEntry *se, IDList *idList) : se(se), idList(idList) {};
    void output(int level);
};

class WhileStmt : public StmtNode
{
private:
    ExprNode* cond;
    StmtNode* stmt;
public:
    WhileStmt(ExprNode* cond, StmtNode* stmt) : cond(cond), stmt(stmt) {};
    void output(int level);
};

class ReturnStmt : public StmtNode
{
private:
    ExprNode *retValue;
    StmtNode *funcCall;
public:
    ReturnStmt(ExprNode*retValue) : retValue(retValue) {};
    ReturnStmt(StmtNode *funcCall) : funcCall(funcCall) {};
    void output(int level);
};

class Ast
{
private:
    Node* root;
public:
    Ast() {root = nullptr;}
    void setRoot(Node*n) {root = n;}
    void output();
};

#endif
