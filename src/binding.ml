open Interface
open Format

let header = {|(* This file has been generated by coq-bindgen. *)

From FreeSpec.Core Require Import All.

Set Implicit Arguments.|}

let rec last = function
  | [x] -> x
  | _ :: rst -> last rst
  | _ -> raise (UnsupportedOcaml "Found an empty ident")

let is_not_empty = function
  | _ :: _ -> true
  | _ -> false

let open_parens fmt cond =
  fprintf fmt "%s" (if cond then "(" else "")

let close_parens fmt cond =
  fprintf fmt "%s" (if cond then ")" else "")

let rec print_type_tree ~param fmt = function
  | ArrowNode(l,r) ->
    fprintf fmt "%a%a -> %a%a"
      open_parens param
      (print_type_tree ~param:true) l
      (print_type_tree ~param:true) r
      close_parens param
  | ProdNode(x :: l) ->
    fprintf fmt "%a%a%a%a"
      open_parens param
      (print_type_tree ~param:true) x
      (fun fmt -> List.iter (fun x -> fprintf fmt " * %a"
                                (print_type_tree ~param:true) x)) l
      close_parens param
  | ProdNode(_) -> assert false (* a tuple with no element? *)
  | TypeLeaf leaf ->
    print_type_leaf ~param:param fmt leaf

and print_type_leaf ~param fmt (name, ts) =
  let with_parens = param && is_not_empty ts in
  fprintf fmt "%a%s" open_parens with_parens name;
  List.iter (fun x -> fprintf fmt " %a" (print_type_tree ~param:true) x) ts;
  close_parens fmt with_parens

let print_type fmt t =
  if is_not_empty t.poly_vars
  then begin
    fprintf fmt "forall%a, "
      (fun fmt -> List.iter (fun x -> fprintf fmt " (%s : Type)" x))
      t.poly_vars;
  end;
  fprintf fmt "%a -> %a"
    (print_type_tree ~param:true) t.domain_types
    (print_type_tree ~param:false) t.codomain_type

let print_coq_type fmt (t : type_entry) =
  let name = Ident.name t.name in
  match t.coq_model with
  | Some ident ->
    fprintf fmt "Definition %s : Type := %@%s.\n" name ident
  | None ->
    fprintf fmt "Axiom (%s : Type).\n" name

let print_coq_types fmt i =
  List.iter (print_coq_type fmt) i.types

let print_coq_function fmt (t : function_entry) =
  let name = Ident.name t.name in
  begin
    match t.coq_model with
    | Some ident ->
      fprintf fmt "Definition %s : %a := %@%s.\n"
        name
        print_type t.type_sig
        ident
    | None ->
      fprintf fmt "Axiom (%s : %a).\n"
        name
        print_type t.type_sig
  end

let print_coq_primitive iname fmt p =
  let pname = String.capitalize_ascii @@ Ident.name p.name in
  fprintf fmt "\n| %s : %a"
    pname
    print_type { p.type_sig with codomain_type = TypeLeaf (iname, [p.type_sig.codomain_type])}

let print_coq_primitives fmt i =
  let name = String.uppercase_ascii (last i.module_path) in
  fprintf fmt "Inductive %s : interface :=%a.\n"
    name
    (fun fmt -> List.iter (print_coq_primitive name fmt)) i.primitives

let print_coq_functions fmt i =
  List.iter (print_coq_function fmt) i.functions

let print_coq_extraction_function modname fmt (f : function_entry) =
  let modname = modname in
  let name = Ident.name f.name in
  fprintf fmt "  Extract Constant %s => \"%s\".\n"
    name
    (String.concat "." modname ^ "." ^ name)

let print_coq_extraction_functions fmt i =
  List.iter (print_coq_extraction_function i.module_path fmt) i.functions

let print_coq_extraction_primitive modname fmt (p : primitive_entry) =
  let name = Ident.name p.name in
  fprintf fmt "  Axiom (ocaml_%s : %a).\n"
    name
    print_type p.type_sig;
  fprintf fmt "  Extract Constant ocaml_%s => \"%s\".\n"
    name
    (String.concat "." modname ^ "." ^ name)

let arg_list (t : type_tree) : string =
  let rec aux n = function
    | ArrowNode (_, t) -> sprintf " arg%d" n ^ aux (n+1) t
    | _ -> sprintf " arg%d" n
  in aux 0 t

let print_coq_extraction_primitives fmt i =
  let modname = i.module_path in
  let semantics_name = String.lowercase_ascii (last modname) in
  let interface_name = String.uppercase_ascii (last modname) in
  List.iter (print_coq_extraction_primitive modname fmt) i.primitives;
  fprintf fmt "\n";
  fprintf fmt {|  Definition %s : semantics %s :=
    bootstrap (fun a e =>
                 local match e in %s a return a with|}
    semantics_name
    interface_name
    interface_name;
  List.iter (fun p ->
      let args = arg_list p.type_sig.domain_types in
      fprintf fmt "\n                 | %s%s => ocaml_%s%s"
        (String.capitalize_ascii (Ident.name p.name))
        args
        (Ident.name p.name)
        args) i.primitives;
  fprintf fmt "\n                 end).\n"

let print_coq_interface fmt i =
  fprintf fmt "%s\n%a\n%a\n%a\n"
    header
    print_coq_types i
    print_coq_functions i
    print_coq_primitives i;
  let name = String.capitalize_ascii (last i.module_path) in
  fprintf fmt "Module %sExtr.\n%a\n%aEnd %sExtr.\n"
    name
    print_coq_extraction_primitives i
    print_coq_extraction_functions i
    name
