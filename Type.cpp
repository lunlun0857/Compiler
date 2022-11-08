#include "Type.h"
#include <sstream>

IntType TypeSystem::commonInt = IntType(4);
VoidType TypeSystem::commonVoid = VoidType();
ConstIntType TypeSystem::commonConstInt = ConstIntType(4);

Type* TypeSystem::intType = &commonInt;
Type* TypeSystem::voidType = &commonVoid;
Type* TypeSystem::constIntType = &commonConstInt;

std::string IntType::toStr()
{
    return "int";
}

std::string VoidType::toStr()
{
    return "void";
}

std::string ConstIntType::toStr()
{
    return "const int";
}

std::string FunctionType::toStr()
{
    std::ostringstream buffer;
    buffer << returnType->toStr() << "()";
    return buffer.str();
}