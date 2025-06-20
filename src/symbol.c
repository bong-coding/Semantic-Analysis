#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.h"

SymbolTable* current_scope = NULL;
ParamList* current_param_list = NULL;
StructType* global_type_list = NULL;
FuncInfo* global_func_list = NULL;
TypeInfo* current_function_return_type = NULL;
char* current_filename = NULL;
int error_lineno = -1;

SymbolTable* create_symbol_table(SymbolTable* parent) {
    SymbolTable* symbol_table = (SymbolTable*)malloc(sizeof(SymbolTable));
    symbol_table->symbols = NULL;
    symbol_table->parent = parent;
    return symbol_table;
}

void init_symbol_system() {
    current_scope = create_symbol_table(NULL);
}

void push_scope() {
    SymbolTable *new_scope = create_symbol_table(current_scope);
    current_scope = new_scope;
}

void pop_scope() {
    if (current_scope == NULL) return;
    SymbolTable *old_scope = current_scope;
    current_scope = current_scope->parent;
    free_symbol_table(old_scope);
}

int insert_symbol(const char *name, TypeInfo *type) {
    if(lookup_symbol_in_current_scope(name)) return 0;
    Symbol *new_symbol = (Symbol*)malloc(sizeof(Symbol));
    new_symbol->name = strdup(name);
    new_symbol->type = deep_copy_typeinfo(type);
    new_symbol->next = current_scope->symbols;
    current_scope->symbols = new_symbol;
    return 1;
}

int lookup_symbol_in_current_scope(const char *name) {
    Symbol *symbol = current_scope -> symbols;
    while(symbol != NULL) {
        if (strcmp(symbol->name, name) == 0) return 1;
        symbol = symbol->next;
    }
    return 0;
}

Symbol* lookup_symbol(const char *name){
    SymbolTable *scope = current_scope;
    while(scope != NULL) {
        Symbol *symbol = scope -> symbols;
        while(symbol != NULL) {
            if (strcmp(symbol->name, name) == 0) return symbol;
            symbol = symbol->next;
        }
        scope = scope->parent;
    }
    return NULL;
}

int is_same_type(TypeInfo *type1, TypeInfo *type2) {
    if (type1 == NULL && type2 == NULL) return 1;
    if (type1 == NULL || type2 == NULL) return 0;
    if ((type1->type == TYPE_NULLPTR && type2->type == TYPE_POINTER) ||
        (type2->type == TYPE_NULLPTR && type1->type == TYPE_POINTER)) return 1;
    if (type1->type != type2->type) return 0;
    if (type1->type == TYPE_STRUCT) {
        if (type1->struct_name == NULL || type2->struct_name == NULL) return 0;
        if (strcmp(type1->struct_name, type2->struct_name) == 0) return 1;
        Symbol* s1 = lookup_symbol(type1->struct_name);
        Symbol* s2 = lookup_symbol(type2->struct_name);
        if ((s1 && s1->type && s1->type->type == TYPE_STRUCT &&
             strcmp(s1->type->struct_name, type2->struct_name) == 0) ||
            (s2 && s2->type && s2->type->type == TYPE_STRUCT &&
             strcmp(s2->type->struct_name, type1->struct_name) == 0)) return 1;
        return 0;
    }
    if (type1->type == TYPE_ARRAY) {
        if (type1->array_size != type2->array_size) return 0;
    }
    if (type1->next == NULL && type2->next == NULL) return 1;
    return is_same_type(type1->next, type2->next);
}

int is_lvalue(TypeInfo *type) {
    if (type == NULL) return 0;
    return type->is_lvalue;
}

int is_arithmetic_type(TypeInfo* type) {
    return type->type == TYPE_INT || type->type == TYPE_CHAR;
}

int is_boolean_type(TypeInfo* type) {
    return type->type == TYPE_INT;
}

int is_comparable_type(TypeInfo* type1, TypeInfo* type2) {
    if (type1 == NULL || type2 == NULL) return 0;
    if (type1->type == TYPE_STRUCT || type2->type == TYPE_STRUCT) return 0;
    if ((type1->type == TYPE_INT || type1->type == TYPE_CHAR) &&
        (type2->type == TYPE_INT || type2->type == TYPE_CHAR)) return 1;
    return 0;
}

ParamList* create_param_list() {
    ParamList* list = (ParamList*)malloc(sizeof(ParamList));
    list->head = list->tail = NULL;
    return list;
}

int add_param(ParamList* list, const char* name, TypeInfo* type) {
    ParamNode* curr = list->head;
    while (curr != NULL) {
        if (strcmp(curr->name, name) == 0) return 0;
        curr = curr->next;
    }
    ParamNode* node = (ParamNode*)malloc(sizeof(ParamNode));
    node->name = strdup(name);
    node->type = deep_copy_typeinfo(type);
    node->next = NULL;
    if(list->tail != NULL) list->tail->next = node;
    else list->head = node;
    list->tail = node;
    return 1;
}

void free_type(TypeInfo *type) {
    if (type == NULL) return;
    free_type(type->next);
    if(type -> struct_name) free(type->struct_name);
    free_field_list(type->field_list);
    free(type);
}

void free_field_list(FieldInfo *field_list) {
    while(field_list) {
        FieldInfo *next = field_list->next;
        if (field_list->name) free(field_list->name);
        free_type(field_list->type);
        free(field_list);
        field_list = next;
    }
}

void free_param_list(ParamList* list) {
    if (list == NULL) return;
    ParamNode* current = list->head;
    while(current) {
        ParamNode* next = current->next;
        if(current->name) free(current->name);
        if(current->type) free_type(current->type);
        free(current);
        current = next;
    }
    free(list);
}

void free_symbol(Symbol* symbol) {
    while(symbol) {
        Symbol* next = symbol->next;
        if(symbol->name) free(symbol->name);
        free_type(symbol->type);
        free(symbol);
        symbol = next;
    }
}

void free_symbol_table(SymbolTable* table) {
    if (table == NULL) return;
    free_symbol(table->symbols);
    free(table);
}

void free_struct_type_list(StructType* list){
    while(list) {
        StructType* next = list->next;
        if(list->name) free(list->name);
        free_field_list(list->field_list);
        free(list);
        list = next;
    }
}

void free_func_list(FuncInfo* list) {
    while(list) {
        FuncInfo* next = list->next;
        if(list->name) free(list->name);
        free_type(list->return_type);
        free_param_list(list->param_list);
        free(list);
        list = next;
    }
}

ParamList* create_arg_list(TypeInfo* type) {
    ParamList* list = create_param_list();
    if (type != NULL) add_arg(list, type);
    return list;
}

int add_arg(ParamList* list, TypeInfo* type) {
    ParamNode* node = malloc(sizeof(ParamNode));
    node->type = deep_copy_typeinfo(type);
    node->name = NULL;
    node->next = NULL;
    if (!list->head) list->head = list->tail = node;
    else {
        list->tail->next = node;
        list->tail = node;
    }
    return 1;
}

int is_compatible_arguments(ParamList* declared, ParamList* args) {
    ParamNode *p1 = declared ? declared->head : NULL;
    ParamNode *p2 = args ? args->head : NULL;
    while (p1 && p2) {
        if (!is_same_type(p1->type, p2->type)) return 0;
        p1 = p1->next;
        p2 = p2->next;
    }
    return (p1 == NULL && p2 == NULL);
}

void insert_param_list_to_scope(ParamList* list){
    ParamNode* current_node = list->head;
    while(current_node != NULL) {
        insert_symbol(current_node->name, current_node->type);
        current_node = current_node->next;
    }
}

int is_redelcare_struct(const char *name) {
    StructType *current = global_type_list;
    while(current != NULL) {
        if (strcmp(current->name, name) == 0) return 1;
        current = current->next;
    }
    return 0;
}

void register_struct_type(const char *name, FieldInfo *field_list) {
    StructType *new_struct = malloc(sizeof(StructType));
    new_struct->name = strdup(name);
    new_struct->field_list = field_list;
    new_struct->next = global_type_list;
    global_type_list = new_struct;
}

FieldInfo* convert_scope_to_field_list() {
    if (current_scope == NULL) return NULL;
    Symbol *symbol = current_scope -> symbols;
    FieldInfo *head = NULL;
    FieldInfo *tail = NULL;
    while(symbol != NULL) {
        FieldInfo* field = (FieldInfo*)malloc(sizeof(FieldInfo));
        field->name = strdup(symbol->name);
        field->type = deep_copy_typeinfo(symbol->type);
        field->next = NULL;
        if(head == NULL) head = tail = field;
        else {
            tail->next = field;
            tail = field;
        }
        symbol = symbol->next;
    }
    return head;
}

TypeInfo* find_field_type(TypeInfo *struct_type, const char *field_name) {
    if (!struct_type || struct_type->type != TYPE_STRUCT || !struct_type->field_list) return NULL;
    FieldInfo *field = struct_type->field_list;
    while(field != NULL) {
        if (strcmp(field->name, field_name) == 0) return field->type;
        field = field->next;
    }
    return NULL;
}

TypeInfo* deep_copy_typeinfo(TypeInfo* src) {
    if(src == NULL) return NULL;
    TypeInfo* dst = malloc(sizeof(TypeInfo));
    dst->type = src->type;
    dst->next = deep_copy_typeinfo(src->next);
    dst->array_size = src->array_size;
    dst->is_lvalue = src->is_lvalue;
    if (src->type == TYPE_STRUCT) {
        dst->struct_name = src->struct_name ? strdup(src->struct_name) : NULL;
        StructType* cur = global_type_list;
        dst->field_list = NULL;
        while (cur) {
            if (strcmp(cur->name, dst->struct_name) == 0) {
                dst->field_list = deep_copy_field_list(cur->field_list);
                break;
            }
            cur = cur->next;
        }
    } else {
        dst->struct_name = NULL;
        dst->field_list = deep_copy_field_list(src->field_list);
    }
    return dst;
}

FieldInfo* deep_copy_field_list(FieldInfo* src) {
    if(src == NULL) return NULL;
    FieldInfo* head = NULL;
    FieldInfo* tail = NULL;
    while(src != NULL) {
        FieldInfo* field = malloc(sizeof(FieldInfo));
        field->name = strdup(src->name);
        field->type = deep_copy_typeinfo(src->type);
        field->next = NULL;
        if(tail != NULL) tail->next = field;
        else head = field;
        tail = field;
        src = src->next;
    }
    return head;
}

int is_func_declared(char* name) {
    FuncInfo* current = global_func_list;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) return 1;
        current = current->next;
    }
    return 0;
}

void insert_func_info(char* name, TypeInfo* return_type, ParamList* param_list) {
    FuncInfo* new_func = malloc(sizeof(FuncInfo));
    new_func->name = strdup(name);
    new_func->return_type = deep_copy_typeinfo(return_type);
    new_func->param_list = param_list;
    new_func->next = global_func_list;
    global_func_list = new_func;
}

FuncInfo* find_func_info(const char* name) {
    FuncInfo* current = global_func_list;
    while (current) {
        if (strcmp(current->name, name) == 0) return current;
        current = current->next;
    }
    return NULL;
}

