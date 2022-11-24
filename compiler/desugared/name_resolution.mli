(* This file is part of the Catala compiler, a specification language for tax
   and social benefits computation rules. Copyright (C) 2020 Inria, contributor:
   Nicolas Chataing <nicolas.chataing@ens.fr> Denis Merigoux
   <denis.merigoux@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

(** Builds a context that allows for mapping each name to a precise uid, taking
    lexical scopes into account *)

open Utils
open Shared_ast

(** {1 Name resolution context} *)

type ident = string

module IdentMap : Map.S with type key = String.t

type unique_rulename =
  | Ambiguous of Pos.t list
  | Unique of RuleName.t Marked.pos

type scope_def_context = {
  default_exception_rulename : unique_rulename option;
  label_idmap : LabelName.t IdentMap.t;
}

type scope_var_or_subscope =
  | ScopeVar of ScopeVar.t
  | SubScope of SubScopeName.t * ScopeName.t

type scope_context = {
  var_idmap : scope_var_or_subscope IdentMap.t;
      (** All variables, including scope variables and subscopes *)
  scope_defs_contexts : scope_def_context Ast.ScopeDefMap.t;
      (** What is the default rule to refer to for unnamed exceptions, if any *)
  sub_scopes : ScopeSet.t;
      (** Other scopes referred to by this scope. Used for dependency analysis *)
}
(** Inside a scope, we distinguish between the variables and the subscopes. *)

type struct_context = typ StructFieldMap.t
(** Types of the fields of a struct *)

type enum_context = typ EnumConstructorMap.t
(** Types of the payloads of the cases of an enum *)

type var_sig = {
  var_sig_typ : typ;
  var_sig_is_condition : bool;
  var_sig_io : Surface.Ast.scope_decl_context_io;
  var_sig_states_idmap : StateName.t IdentMap.t;
  var_sig_states_list : StateName.t list;
}

(** Capitalised type names share a namespace on the user side, but may
    correspond to only one of the following *)
type typedef =
  | TStruct of StructName.t
  | TEnum of EnumName.t
  | TScope of ScopeName.t * scope_out_struct
      (** Implicitly defined output struct *)

type context = {
  local_var_idmap : Ast.expr Var.t IdentMap.t;
      (** Inside a definition, local variables can be introduced by functions
          arguments or pattern matching *)
  typedefs : typedef IdentMap.t;
      (** Gathers the names of the scopes, structs and enums *)
  field_idmap : StructFieldName.t StructMap.t IdentMap.t;
      (** The names of the struct fields. Names of fields can be shared between
          different structs *)
  constructor_idmap : EnumConstructor.t EnumMap.t IdentMap.t;
      (** The names of the enum constructors. Constructor names can be shared
          between different enums *)
  scopes : scope_context ScopeMap.t;  (** For each scope, its context *)
  structs : struct_context StructMap.t;  (** For each struct, its context *)
  enums : enum_context EnumMap.t;  (** For each enum, its context *)
  var_typs : var_sig ScopeVarMap.t;
      (** The signatures of each scope variable declared *)
}
(** Main context used throughout {!module: Surface.Desugaring} *)

(** {1 Helpers} *)

val raise_unsupported_feature : string -> Pos.t -> 'a
(** Temporary function raising an error message saying that a feature is not
    supported yet *)

val raise_unknown_identifier : string -> ident Marked.pos -> 'a
(** Function to call whenever an identifier used somewhere has not been declared
    in the program previously *)

val get_var_typ : context -> ScopeVar.t -> typ
(** Gets the type associated to an uid *)

val is_var_cond : context -> ScopeVar.t -> bool
val get_var_io : context -> ScopeVar.t -> Surface.Ast.scope_decl_context_io

val get_var_uid : ScopeName.t -> context -> ident Marked.pos -> ScopeVar.t
(** Get the variable uid inside the scope given in argument *)

val get_subscope_uid :
  ScopeName.t -> context -> ident Marked.pos -> SubScopeName.t
(** Get the subscope uid inside the scope given in argument *)

val is_subscope_uid : ScopeName.t -> context -> ident -> bool
(** [is_subscope_uid scope_uid ctxt y] returns true if [y] belongs to the
    subscopes of [scope_uid]. *)

val belongs_to : context -> ScopeVar.t -> ScopeName.t -> bool
(** Checks if the var_uid belongs to the scope scope_uid *)

val get_def_typ : context -> Ast.ScopeDef.t -> typ
(** Retrieves the type of a scope definition from the context *)

val is_def_cond : context -> Ast.ScopeDef.t -> bool
val is_type_cond : Surface.Ast.typ -> bool

val add_def_local_var : context -> ident -> context * Ast.expr Var.t
(** Adds a binding to the context *)

val get_def_key :
  Surface.Ast.qident ->
  Surface.Ast.ident Marked.pos option ->
  ScopeName.t ->
  context ->
  Pos.t ->
  Ast.ScopeDef.t
(** Usage: [get_def_key var_name var_state scope_uid ctxt pos]*)

val get_enum : context -> ident Marked.pos -> EnumName.t
(** Find an enum definition from the typedefs, failing if there is none or it
    has a different kind *)

val get_struct : context -> ident Marked.pos -> StructName.t
(** Find a struct definition from the typedefs (possibly an implicit output
    struct from a scope), failing if there is none or it has a different kind *)

val get_scope : context -> ident Marked.pos -> ScopeName.t
(** Find a scope definition from the typedefs, failing if there is none or it
    has a different kind *)

(** {1 API} *)

val form_context : Surface.Ast.program -> context
(** Derive the context from metadata, in one pass over the declarations *)