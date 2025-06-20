#ifndef __SYMBOL_H__
#define __SYMBOL_H__
#define TYPE_NULLPTR 999


typedef enum BaseType {
    TYPE_INT,
    TYPE_CHAR,
    TYPE_POINTER,
    TYPE_STRUCT,
    TYPE_ARRAY,
} BaseType;

typedef struct TypeInfo {
    BaseType type;
    struct TypeInfo *next; 
    char *struct_name; 
    int array_size; 
    int is_lvalue; 
    struct FieldInfo *field_list; 
} TypeInfo;


typedef struct Symbol {
    char *name; 
    TypeInfo *type;
    struct Symbol *next; 
} Symbol;


typedef struct SymbolTable {
    Symbol *symbols; 
    struct SymbolTable *parent; 
} SymbolTable;

typedef struct ParamNode {
    char* name;
    TypeInfo* type;
    struct ParamNode* next;
} ParamNode;

typedef struct ParamList {
    ParamNode* head;
    ParamNode* tail;
} ParamList;

typedef struct FieldInfo {
    char *name;
    TypeInfo* type;
    struct FieldInfo* next;
} FieldInfo;

typedef struct StructType {
    char *name;
    FieldInfo *field_list;
    struct StructType *next;
} StructType;
typedef struct FuncInfo {
    char *name;
    TypeInfo *return_type;
    ParamList *param_list;
    struct FuncInfo *next;
} FuncInfo;



extern SymbolTable *current_scope; 
extern ParamList* current_param_list; 
extern StructType* global_type_list; 
extern FuncInfo* global_func_list; 
extern TypeInfo* current_function_return_type; 
extern char* current_filename; 
extern int error_lineno; 


FuncInfo* find_func_info(const char* name);
ParamList* create_arg_list(TypeInfo* type);
TypeInfo* find_field_type(TypeInfo *struct_type, const char *field_name);
TypeInfo* deep_copy_typeinfo(TypeInfo* src);
FieldInfo* deep_copy_field_list(FieldInfo* src);
SymbolTable* create_symbol_table(SymbolTable* parent);
Symbol* lookup_symbol(const char *name);
ParamList* create_param_list();
FieldInfo* convert_scope_to_field_list();
void print_param_list(ParamList* list, const char* msg);
void free_symbol_table(SymbolTable* table);
void free_symbol(Symbol* symbol);
void free_struct_type_list(StructType* list);
void free_func_list(FuncInfo* list);
void free_type(TypeInfo* type);
void free_field_list(FieldInfo* field_list);
void free_param_list(ParamList* list);
void init_symbol_system();
void push_scope();
void pop_scope();
void register_struct_type(const char *name, FieldInfo *field_list);
void insert_param_list_to_scope(ParamList* list);
void error_redeclaration(); 
void insert_func_info(char* name, TypeInfo* return_type, ParamList* param_list);
int is_redelcare_struct(const char *name);
int insert_symbol(const char* name, TypeInfo* type);
int lookup_symbol_in_current_scope(const char* name);
int is_same_type(TypeInfo* type1, TypeInfo* type2);
int is_lvalue(TypeInfo *type);
int add_param(ParamList* list, const char* name, TypeInfo* type);
int is_arithmetic_type(TypeInfo* type);
int is_boolean_type(TypeInfo* type);
int is_comparable_type(TypeInfo* type1, TypeInfo* type2);
int is_func_declared(char* name);
int add_arg(ParamList* list, TypeInfo* type);
int is_compatible_arguments(ParamList* declared, ParamList* args);
int is_same_param_list(ParamList* p1, ParamList* p2);

#endif