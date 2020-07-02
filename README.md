# `coqffi`

**`coqffi` automatically generates Coq FFI bindings to OCaml
libraries.**

For example, given the OCaml header file `file.mli`:

```ocaml
open Coqbase

type fd

type file_flags =
  | O_RDONLY
  | O_WRONLY
  | O_RDWR

val openfile : Bytestring.t -> file_flags list -> fd [@@impure]
val read_all : fd -> Bytestring.t [@@impure]
val write : fd -> Bytestring.t -> unit [@@impure]
val closefile : fd -> unit [@@impure]

val fd_equal : fd -> fd -> bool
```

`coqffi` generates the necessary Coq boilerplate to use these
functions in a Coq development, and to configure the extraction
mechanism accordingly.

```coq
(* This file has been generated by coqffi. *)

Set Implicit Arguments.

From Base Require Import Prelude.
From FreeSpec.Core Require Import All.

(** * Types *)

Inductive file_flags : Type :=
| O_RDONLY : file_flags
| O_WRONLY : file_flags
| O_RDWR : file_flags.

Axiom (fd : Type).

(** * Pure Functions *)

Axiom (fd_equal : fd -> fd -> bool).

(** * Impure Primitives *)

(** ** Interface Definition *)

Inductive FILE : interface :=
| Openfile : bytestring -> list file_flags -> FILE fd
| Read_all : fd -> FILE bytestring
| Write : fd -> bytestring -> FILE unit
| Closefile : fd -> FILE unit.

(** ** Primitive Helpers *)

Definition openfile `{Provide ix FILE} (x0 : bytestring)
(x1 : list file_flags) : impure ix fd :=
  request (Openfile x0 x1).

Definition read_all `{Provide ix FILE} (x0 : fd) : impure ix bytestring :=
  request (Read_all x0).

Definition write `{Provide ix FILE} (x0 : fd) (x1 : bytestring)
  : impure ix unit :=
  request (Write x0 x1).

Definition closefile `{Provide ix FILE} (x0 : fd) : impure ix unit :=
  request (Closefile x0).

(** * Extraction *)

Extract Constant fd => "Demo.File.fd".
Extract Inductive file_flags => "Demo.File.file_flags" ["Demo.File.O_RDONLY"
  "Demo.File.O_WRONLY" "Demo.File.O_RDWR"].

Extract Constant fd_equal => "Demo.File.fd_equal".

Axiom (ml_openfile : bytestring -> list file_flags -> fd).
Axiom (ml_read_all : fd -> bytestring).
Axiom (ml_write : fd -> bytestring -> unit).
Axiom (ml_closefile : fd -> unit).

Extract Constant ml_openfile => "Demo.File.openfile".
Extract Constant ml_read_all => "Demo.File.read_all".
Extract Constant ml_write => "Demo.File.write".
Extract Constant ml_closefile => "Demo.File.closefile".

Definition ml_file_sem : semantics FILE :=
  bootstrap (fun a e =>
    local match e in FILE a return a with
          | Openfile x0 x1 => ml_openfile x0 x1
          | Read_all x0 => ml_read_all x0
          | Write x0 x1 => ml_write x0 x1
          | Closefile x0 => ml_closefile x0
          end).
```

`coqffi` can be configured through two key options:

- The “extraction profile” determines the set of supported
  “base”. Currently, `coqffi` provides two profiles: `stdlib` and
  `coq-base`.
- The “impure mode” determines which framework is used to model impure
  functions. Currently, `coqffi` provides one mode:
  [`FreeSpec`](https://github.com/ANSSI-FR/FreeSpec). We expect to
  support more frameworks in the future, such as [Interactive
  Trees](https://github.com/DeepSpec/InteractionTrees)

Besides, it provides several flags to enable certain experimental
features:

- `-ftransparent-types` to generate Coq definitions for types whose
  implementation is public. **Note:** `coqffi` does only support a
  subset of OCaml’s types, and may generate invalid Coq types.
