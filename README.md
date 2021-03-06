# `coqffi`

[![Build Status](https://travis-ci.org/lthms/coqffi.svg?branch=main)](https://travis-ci.org/lthms/coqffi)

**`coqffi` automatically generates Coq FFI bindings to OCaml
libraries.**

For example, given the OCaml header file `file.mli`:

```ocaml
open Coqbase

type fd

val fd_equal : fd -> fd -> bool

val openfile : Bytestring.t -> fd [@@impure]
val read_all : fd -> Bytestring.t [@@impure]
val write : fd -> Bytestring.t -> unit [@@impure]
val closefile : fd -> unit [@@impure]
```

`coqffi` generates the necessary Coq boilerplate to use these
functions in a Coq development, and to configure the extraction
mechanism accordingly.

```coq
(* This file has been generated by coqffi. *)

Set Implicit Arguments.
Unset Strict Implicit.
Set Contextual Implicit.
Generalizable All Variables.

From Base Require Import Prelude Extraction.
From SimpleIO Require Import IO_Monad.
From CoqFFI Require Import Interface.

(** * Types *)

Axiom (fd : Type).

Extract Constant fd => "Examples.File.fd".

(** * Pure Functions *)

Axiom (fd_equal : fd -> fd -> bool).

Extract Constant fd_equal => "Examples.File.fd_equal".

(** * Impure Primitives *)

(** ** Monad *)

Class MonadFile (m : Type -> Type) : Type :=
  { openfile : bytestring -> m fd
  ; read_all : fd -> m bytestring
  ; write : fd -> bytestring -> m unit
  ; closefile : fd -> m unit
  }.

(** ** [IO] Instance *)

Axiom (io_openfile : bytestring -> IO fd).
Axiom (io_read_all : fd -> IO bytestring).
Axiom (io_write : fd -> bytestring -> IO unit).
Axiom (io_closefile : fd -> IO unit).

Extract Constant io_openfile =>
  "(fun x0 k__ -> k__ (Examples.File.openfile x0))".
Extract Constant io_read_all =>
  "(fun x0 k__ -> k__ (Examples.File.read_all x0))".
Extract Constant io_write =>
  "(fun x0 x1 k__ -> k__ (Examples.File.write x0 x1))".
Extract Constant io_closefile =>
  "(fun x0 k__ -> k__ (Examples.File.closefile x0))".

Instance MonadFile_IO : MonadFile IO :=
  { openfile := io_openfile
  ; read_all := io_read_all
  ; write := io_write
  ; closefile := io_closefile
  }.
```

See the `coqffi` man pages for more information on how to use it.

# Getting Started

First, install
[`coq-simple-io`](https://github.com/Lysxia/coq-simple-io).  Then, you
can use `dune` to build `coqffi`.

```
dune build -p coqffi
dune install coqffi
```

This also builds several examples which use `coqffi`. At the very
least, we can use this to ensure that Coq still typechecks the the
generated code.
