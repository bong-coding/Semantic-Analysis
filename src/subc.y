/*
 * File Name    : subc.y
 * Description  : a skeleton bison input
 */

%{

#include "subc.h"

int   yylex ();
void   yyerror (char* s);
int   get_lineno();

// Declaration and Type Errors
void error_symbol_redeclared(void);
void error_symbol_undeclared(void);
void error_type_incomplete(void);

// Assignment and Compatibility Errors
void error_assignment_incompatible(void);
void error_lvalue_not_assignable(void);
void error_null_assignment_invalid(void);

// Expression and Operation Errors
void error_binary_operands_invalid(void);
void error_unary_operand_invalid(void);
void error_comparison_invalid(void);

// Pointer and Memory Errors
void error_pointer_indirection_invalid(void);
void error_address_of_rvalue(void);

// Struct and Member Errors
void error_struct_member_access_invalid(void);
void error_struct_pointer_access_invalid(void);
void error_struct_member_not_found(void);

// Array Errors
void error_array_subscript_invalid(void);
void error_array_index_not_integer(void);

// Function Errors
void error_function_call_invalid(void);
void error_function_arguments_incompatible(void);
void error_function_return_incompatible(void);

%}

%union {
  int   intVal;
  char  *stringVal;
  struct TypeInfo *typeInfo;
  struct ParamList *paramList;
}

%left   ','
%right  '='
%left   LOGICAL_OR
%left   LOGICAL_AND
%left   EQUOP
%left   RELOP
%left   '+' '-'
%left   '*' '/' '%'
%right  '!' '&' INCOP DECOP
%left   '[' ']' '(' ')' '.' STRUCTOP

%precedence IF
%precedence ELSE

%token STRUCT RETURN WHILE FOR BREAK CONTINUE SYM_NULL
%token<stringVal> TYPE
%token CHAR_CONST
%token STRING
%token<intVal> INTEGER_CONST
%token<stringVal> ID
%type<typeInfo> type_specifier
%type<typeInfo> struct_specifier
%type<typeInfo> unary
%type<typeInfo> expr
%type<typeInfo> binary
%type<typeInfo> expr_e
%type<typeInfo> func_decl
%type<paramList> param_list param_decl
%type<typeInfo> pointers
%type<paramList> args

%%
program
  : ext_def_list 
  ;

ext_def_list
  : ext_def_list ext_def 
  | %empty 
  ;

ext_def
  : type_specifier pointers ID ';' { 
    TypeInfo* final_type = $1;
    if($2 != NULL) {
      $2->next = $1;
      final_type = $2;
    }
    
    if(final_type == NULL) {
      error_type_incomplete();
    } else if (!insert_symbol($3, final_type)) {
      error_symbol_redeclared();
    }
  }
  | type_specifier pointers ID '[' INTEGER_CONST ']' ';' {
    TypeInfo *base_type = $1;
    
    if($2 != NULL) {
      $2->next = $1;
      base_type = $2;
    }

    TypeInfo *array_type = malloc(sizeof(TypeInfo));
    array_type->type = TYPE_ARRAY;
    array_type->next = base_type;
    array_type->is_lvalue = 0;
    array_type->struct_name = NULL;
    array_type->array_size = $5;
    array_type->field_list = NULL;

    if(!insert_symbol($3, array_type)) {
      error_symbol_redeclared();
    }
  }
  | struct_specifier ';' 
  | func_decl compound_stmt
  ;

type_specifier
  : TYPE {
    $$ = malloc(sizeof(TypeInfo));
    
    if (strcmp($1, "int") == 0) {
      $$->type = TYPE_INT;
    } else if (strcmp($1, "char") == 0) {
      $$->type = TYPE_CHAR;
    } else {
      $$->type = TYPE_INT; 
    }
    $$->next = NULL;
    $$->struct_name = NULL;
    $$->array_size = 0;
    $$->is_lvalue = 0;
    $$->field_list = NULL;
  }
  | struct_specifier 
  ;

struct_specifier
  : STRUCT ID {
    error_lineno = get_lineno();
  }
  '{' {
    push_scope();
  } def_list '}' {
    if(is_redelcare_struct($2)) {
      error_symbol_redeclared();
      $$ = NULL;
    } else {
      $$ = malloc(sizeof(TypeInfo));
      $$->type = TYPE_STRUCT;
      $$->struct_name = strdup($2);
      $$->next = NULL;
      $$->array_size = 0;
      $$->is_lvalue = 0;
      $$->field_list = convert_scope_to_field_list();
      register_struct_type($2, $$->field_list);
    }
    pop_scope();
  }
  | STRUCT ID {
    StructType *current = global_type_list;
    
    while(current != NULL) {
      if(strcmp(current->name, $2) == 0) {
        $$ = malloc(sizeof(TypeInfo));
        $$->type = TYPE_STRUCT;
        $$->struct_name = strdup($2);
        $$->next = NULL;
        $$->array_size = 0;
        $$->is_lvalue = 0;
        $$->field_list = current->field_list;
        break;
      }
      current = current->next;
    }
    
    if (current == NULL) {
      error_symbol_undeclared();
      $$ = NULL;
    }
  }
  ;

func_decl
  : type_specifier pointers ID '(' ')' {
    TypeInfo* final_type = $1;
    
    if($2 != NULL) {
      $2->next = $1;
      final_type = $2;
    }

    current_function_return_type = final_type;

    if(!insert_symbol($3, final_type)) {
      error_symbol_redeclared();
      $$ = NULL;
    } else if(is_func_declared($3)) {
      error_symbol_redeclared();
      $$ = NULL;
    } else {
      insert_func_info($3, final_type, NULL);
      $$ = NULL;
    }
  }
  | type_specifier pointers ID '(' param_list ')' {
    TypeInfo* final_type = $1;
    
    if ($2 != NULL) {
      $2->next = $1;
      final_type = $2;
    }

    current_function_return_type = final_type;
    current_param_list = $5;

    if (is_func_declared($3)) {
      error_symbol_redeclared();
      $$ = NULL;
    } else {
      insert_func_info($3, final_type, $5);
      if (!insert_symbol($3, final_type)) {
        error_symbol_redeclared();
      }
      $$ = NULL;
    }
  }
  ;

pointers
  : '*' {
    $$ = malloc(sizeof(TypeInfo));
    $$->type = TYPE_POINTER;
    $$->next = NULL;
    $$->is_lvalue = 0;
    $$->struct_name = NULL;
    $$->array_size = 0;
    $$->field_list = NULL;
  }
  | %empty {
    $$ = NULL;
  }
  ;

param_list  
  : param_decl {
    $$ = $1;
  }
  | param_list ',' param_decl {
    if ($1 != NULL && $3 != NULL) {
      $1->tail->next = $3->head;
      $1->tail = $3->tail;
    }
    $$ = $1;
  }
  ;		

param_decl 
  : type_specifier pointers ID {
    if ($1 == NULL) {
      error_type_incomplete();
      $$ = NULL;
    } else {
      TypeInfo* final_type = $1;
      if ($2 != NULL) {
        $2->next = $1;
        final_type = $2;
      }
      $$ = create_param_list();
      if(!add_param($$, $3, final_type)) {
        error_symbol_redeclared();
        $$ = NULL;
      }
    }
  }
  | type_specifier pointers ID '[' INTEGER_CONST ']' {
    if ($1 == NULL) {
      error_type_incomplete();
      $$ = NULL;
    } else {
      TypeInfo* base_type = deep_copy_typeinfo($1);

      TypeInfo* array_type = malloc(sizeof(TypeInfo));
      array_type->type = TYPE_ARRAY;
      array_type->array_size = $5;
      array_type->next = base_type;
      array_type->is_lvalue = 0;
      array_type->struct_name = NULL;
      array_type->field_list = NULL;

      $$ = create_param_list();
      if (!add_param($$, $3, array_type)) {
        error_symbol_redeclared();
        $$ = NULL;
      }
    }
  }
  ;

def_list    
  : def_list def 
  | %empty 
  ;

def
  : type_specifier pointers ID ';' {
    TypeInfo* final_type = $1;

    if($2 != NULL) {
      $2->next = $1;
      final_type = $2;
    }
    
    if(final_type == NULL) {
      error_type_incomplete();
    } else if (!insert_symbol($3, final_type)) {
      error_symbol_redeclared();
    }
  }
  | type_specifier pointers ID '[' INTEGER_CONST ']' ';' {
    TypeInfo* base_type = $1;

    if ($2 != NULL) {
        $2->next = $1;
        base_type = $2;
    }

    TypeInfo* array_type = malloc(sizeof(TypeInfo));
    array_type->type = TYPE_ARRAY;
    array_type->array_size = $5;
    array_type->next = base_type;
    array_type->is_lvalue = 0;
    array_type->struct_name = NULL;
    array_type->field_list = NULL;

    if (!insert_symbol($3, array_type)) {
      error_symbol_redeclared();
    }
  }
  ;

compound_stmt
  : '{' {
    push_scope();
    if (current_param_list != NULL) {
        ParamNode* cur = current_param_list->head;
        while (cur != NULL) {
          if (!insert_symbol(cur->name, cur->type)) {
            error_symbol_redeclared();
          }
          cur = cur->next;
        }
        current_param_list = NULL;
      }
  } def_list stmt_list '}' {
    pop_scope();
  }
  ;

stmt_list
  : stmt_list stmt 
  | %empty 
  ;

stmt
  : expr ';' 
  | RETURN expr ';' {
    if ($2 != NULL && current_function_return_type != NULL) {
        if (!is_same_type($2, current_function_return_type)) {
            error_function_return_incompatible();
        }
    }
  }
  | BREAK ';' 
  | CONTINUE ';' 
  | ';' 
  | compound_stmt 
  | IF '(' expr ')' stmt 
  | IF '(' expr ')' stmt ELSE stmt 
  | WHILE '(' expr ')' stmt 
  | FOR '(' expr_e ';' expr_e ';' expr_e ')' stmt 
  ;

expr_e
  : expr 
  | %empty {
    $$ = NULL;
  }
  ;

expr
  : unary '=' expr {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if(!is_lvalue($1)) {
      error_lvalue_not_assignable();
      $$ = NULL;
    } else if($3->type == TYPE_NULLPTR && $1->type != TYPE_POINTER) {
      error_null_assignment_invalid();
      $$ = NULL;
    } else if(!is_same_type($1, $3)) {
      error_assignment_incompatible();
      $$ = NULL;
    } else {
      $$ = $1;
    }
  }
  | binary {
    $$ = $1;
  }
  ;

binary
  : binary RELOP binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if (!is_comparable_type($1, $3)) {
      error_comparison_invalid();
      $$ = NULL;
    } else {
      $$ = malloc(sizeof(TypeInfo));
      $$->type = TYPE_INT;
      $$->is_lvalue = 0;
      $$->next = NULL;
      $$->struct_name = NULL;
      $$->array_size = 0;
    }
  }
  | binary EQUOP binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if (!is_comparable_type($1, $3)) {
      error_comparison_invalid();
      $$ = NULL;
    } else {
      $$ = malloc(sizeof(TypeInfo));
      $$->type = TYPE_INT;
      $$->is_lvalue = 0;
      $$->next = NULL;
      $$->struct_name = NULL;
      $$->array_size = 0;
    }
  }
  | binary '+' binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if(!is_arithmetic_type($1) || !is_arithmetic_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
    }
  }
  | binary '-' binary  {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if(!is_arithmetic_type($1) || !is_arithmetic_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
    }
  }
  | binary '*' binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if(!is_arithmetic_type($1) || !is_arithmetic_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
    }
  }
  | binary '/' binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if(!is_arithmetic_type($1) || !is_arithmetic_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
    }
  }
  | binary '%' binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if(!is_arithmetic_type($1) || !is_arithmetic_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
    }
  }
  | unary %prec '=' {
    $$ = $1;
  }
  | binary LOGICAL_AND binary  {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if (!is_boolean_type($1) || !is_boolean_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = malloc(sizeof(TypeInfo));
      $$->type = TYPE_INT;
      $$->is_lvalue = 0;
      $$->next = NULL;
      $$->struct_name = NULL;
      $$->array_size = 0;
    }
  }
  | binary LOGICAL_OR binary {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if (!is_boolean_type($1) || !is_boolean_type($3)) {
      error_binary_operands_invalid();
      $$ = NULL;
    } else {
      $$ = $1;
    }
  }
  
  ;

unary
  : '(' expr ')' {
    $$ = $2;
  }
  | '(' unary ')' {
    $$ = $2;
  }
  | INTEGER_CONST {
    $$ = malloc(sizeof(TypeInfo));
    $$->type = TYPE_INT;
    $$->is_lvalue = 0;
    $$->next = NULL;
    $$->struct_name = NULL;
    $$->array_size = 0;
    $$->field_list = NULL;
  }
  | CHAR_CONST {
    $$ = malloc(sizeof(TypeInfo));
    $$->type = TYPE_CHAR;
    $$->is_lvalue = 0;
    $$->next = NULL;
    $$->struct_name = NULL;
    $$->array_size = 0;
    $$->field_list = NULL;
  }
  | STRING {
    $$ = malloc(sizeof(TypeInfo));
    $$->type = TYPE_POINTER;
    $$->next = malloc(sizeof(TypeInfo));
    $$->next->type = TYPE_CHAR;
    $$->next->is_lvalue = 0;
    $$->next->next = NULL;
    $$->next->struct_name = NULL;
    $$->next->array_size = 0;
    $$->next->field_list = NULL;
    $$->is_lvalue = 0;
    $$->struct_name = NULL;
    $$->array_size = 0;
    $$->field_list = NULL;
  }
  | ID {
    Symbol* symbol = lookup_symbol($1);

    if (!symbol) {
        error_symbol_undeclared();
        $$ = NULL;
    } else {
        $$ = deep_copy_typeinfo(symbol->type);

        if ($$->type == TYPE_ARRAY) {
            $$->is_lvalue = 0;
        } else {
            $$->is_lvalue = 1;
        }

        $$->struct_name = strdup($1);
    }
}
  | '-' unary %prec '!' {
    if ($2 == NULL) {
      $$ = NULL;
    } else {
      $$ = $2;
    }
  }
  | '!' unary {
    if ($2 == NULL) {
      $$ = NULL;
    } else {
      $$ = $2;
    }
  }
  | unary INCOP %prec STRUCTOP {
    if ($1 == NULL) {
      $$ = NULL;
    } 
    else if (!is_lvalue($1)) {
      error_unary_operand_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
      $$->is_lvalue = 0;
    }
  }
  | unary DECOP %prec STRUCTOP {
    if ($1 == NULL) {
      $$ = NULL;
    } 
    else if (!is_lvalue($1)) {
      error_unary_operand_invalid();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1);
      $$->is_lvalue = 0;
    }
  }
  | INCOP unary %prec '!' {
    if ($2 == NULL) {
      $$ = NULL;
    } 
    else if (!is_lvalue($2)) {
      error_unary_operand_invalid();
      $$ = NULL;
    } 
    else {
      $$ = deep_copy_typeinfo($2);
      $$->is_lvalue = 0;
    }
  }
  | DECOP unary %prec '!' {
    if ($2 == NULL) {
      $$ = NULL;
    } 
    else if (!is_lvalue($2)) {
      error_unary_operand_invalid();
      $$ = NULL;
    }
    else {
      $$ = deep_copy_typeinfo($2);
      $$->is_lvalue = 0;
    }
  }
  | '&' unary {
    if ($2 == NULL) {
      $$ = NULL;
    } 
    else if(!is_lvalue($2)) {
      if ($2->type == TYPE_ARRAY) {
        error_address_of_rvalue();
      } else {
        error_unary_operand_invalid();
      }
      $$ = NULL;
    } else {
      $$ = malloc(sizeof(TypeInfo));
      $$->type = TYPE_POINTER;
      $$->next = deep_copy_typeinfo($2);
      $$->is_lvalue = 0;
      $$->struct_name = NULL;
      $$->array_size = 0;
      $$->field_list = NULL;
    }
}
  | '*' unary %prec '!' {
    if ($2 == NULL) {
      $$ = NULL;
    } 
    else if($2->type != TYPE_POINTER) {
      error_pointer_indirection_invalid();
      $$ = NULL;
    } 
    else if (!is_lvalue($2)) {
      error_unary_operand_invalid();
      $$ = NULL;
    } 
    else { 
      $$ = deep_copy_typeinfo($2->next);
      $$->is_lvalue = 1;
    }
  }
  | unary '[' expr ']' {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else if($1->type != TYPE_ARRAY) {
      error_array_subscript_invalid();
      $$ = NULL;
    } else if($3->type != TYPE_INT) {
      error_array_index_not_integer();
      $$ = NULL;
    } else {
      $$ = deep_copy_typeinfo($1->next);
      $$->is_lvalue = 1;
    }
  }
  | unary '.' ID {
    if ($1 == NULL) {
      $$ = NULL;
    } else if($1->type != TYPE_STRUCT) {
      error_lineno = get_lineno();
      error_struct_member_access_invalid(); 
      $$ = NULL;
    } else {
      TypeInfo *field_type = find_field_type($1, $3);
      if(field_type == NULL) {
        error_lineno = get_lineno();
        error_struct_member_not_found();
        $$ = NULL;
      } else {
        $$ = deep_copy_typeinfo(field_type);
        $$->is_lvalue = 1;
      }
    }
  }
  | unary STRUCTOP ID {
    if($1 == NULL) {
      $$ = NULL;
    } else if($1->type != TYPE_POINTER || $1->next->type != TYPE_STRUCT) {
      error_struct_pointer_access_invalid();
      $$ = NULL;
    } else {
      TypeInfo *struct_type = $1->next;
      TypeInfo *field_type = find_field_type(struct_type, $3);

      if(field_type == NULL) {
        error_struct_member_not_found();
        $$ = NULL;
      } else {
        $$ = deep_copy_typeinfo(field_type);
        $$->is_lvalue = 1;
      }
    }
  }
  | unary '(' args ')' {
    if ($1 == NULL) {
      $$ = NULL;
    } else {
      FuncInfo* func = find_func_info($1->struct_name);
        if (func == NULL) {
            error_function_call_invalid();
            $$ = NULL;
        } else if (!is_compatible_arguments(func->param_list, $3)) {
            error_function_arguments_incompatible();
            $$ = NULL;
        } else if (func->param_list == NULL) {
          error_function_call_invalid();
          $$ = NULL;
        } else {
            $$ = deep_copy_typeinfo(func->return_type);
            $$->is_lvalue = 0;
        }
    }
  }
  | unary '(' ')' {
    if ($1 == NULL || $1->struct_name == NULL) {
      error_function_call_invalid();
      $$ = NULL;
    } else {
      FuncInfo* func = find_func_info($1->struct_name);

      if (func == NULL || func->return_type == NULL) {
        error_function_call_invalid(); 
        $$ = NULL;
      } 

      else if (func->param_list != NULL) {
        error_function_arguments_incompatible();
        $$ = NULL;
      }

      else {
        $$ = deep_copy_typeinfo(func->return_type);
        $$->is_lvalue = 0;
      }
    }
  }
  | SYM_NULL {
    $$ = malloc(sizeof(TypeInfo));
    $$->type = TYPE_NULLPTR;
    $$->next = NULL;
    $$->is_lvalue = 0;
    $$->struct_name = NULL;
    $$->array_size = 0;
    $$->field_list = NULL;
  }
  ;

args
  : expr {
    if ($1 == NULL) {
      $$ = NULL;
    } else {
      $$ = create_param_list();
      add_arg($$, $1);
    }
  }
  | args ',' expr {
    if ($1 == NULL || $3 == NULL) {
      $$ = NULL;
    } else {
        $$ = $1;
        add_arg($$, $3);
    }
  }
  ;

%%

void error_preamble(void) {
  if (error_lineno != -1) {
    printf("%s:%d: error: ", current_filename, error_lineno);
  } else {
    printf("%s:%d: error: ", current_filename, get_lineno());
  }
  error_lineno = -1;
}

// Declaration and Type Errors
void error_symbol_redeclared(void) {
  error_preamble();
  printf("redeclaration\n");
}

void error_symbol_undeclared(void) {
  error_preamble();
  printf("use of undeclared identifier\n");
}

void error_type_incomplete(void) {
  error_preamble();
  printf("incomplete type\n");
}

// Assignment and Compatibility Errors
void error_assignment_incompatible(void) {
  error_preamble();
  printf("incompatible types for assignment operation\n");
}

void error_lvalue_not_assignable(void) {
  error_preamble();
  printf("lvalue is not assignable\n");
}

void error_null_assignment_invalid(void) {
  error_preamble();
  printf("cannot assign 'NULL' to non-pointer type\n");
}

// Expression and Operation Errors
void error_binary_operands_invalid(void) {
  error_preamble();
  printf("invalid operands to binary expression\n");
}

void error_unary_operand_invalid(void) {
  error_preamble();
  printf("invalid argument type to unary expression\n");
}

void error_comparison_invalid(void) {
  error_preamble();
  printf("types are not comparable in binary expression\n");
}

// Pointer and Memory Errors
void error_pointer_indirection_invalid(void) {
  error_preamble();
  printf("indirection requires pointer operand\n");
}

void error_address_of_rvalue(void) {
  error_preamble();
  printf("cannot take the address of an rvalue\n");
}

// Struct and Member Errors
void error_struct_member_access_invalid(void) {
  error_preamble();
  printf("member reference base type is not a struct\n");
}

void error_struct_pointer_access_invalid(void){
  error_preamble();
  printf("member reference base type is not a struct pointer\n");
}

void error_struct_member_not_found(void) {
  error_preamble();
  printf("no such member in struct\n");
}

// Array Errors
void error_array_subscript_invalid(void) {
  error_preamble();
  printf("subscripted value is not an array\n");
}

void error_array_index_not_integer(void) {
  error_preamble();
  printf("array subscript is not an integer\n");
}

// Function Errors
void error_function_call_invalid(void) {
  error_preamble();
  printf("not a function\n");
}

void error_function_arguments_incompatible(void) {
  error_preamble();
  printf("incompatible arguments in function call\n");
}

void error_function_return_incompatible(void) {
  error_preamble();
  printf("incompatible return types\n");
}

void yyerror(char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}