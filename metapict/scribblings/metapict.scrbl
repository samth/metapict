#lang scribble/manual
@(require "utils.rkt")

@title[#:tag "MetaPict" #:style svg-picts]{MetaPict}
@(author-jens-axel)

@defmodule[metapict]

@section{Introduction}

The @racketmodname[metapict] library provides functions and data structures useful
for generating picts. The library includes support for points, vectors, Bezier curves, 
and, general curves.

The algorithm used to calculate a nice curve from points and tangents is the 
same as the one used in MetaPost.


With this library I to hope narrow the gap between Scribble and LaTeX + MetaPost/Tikz.
If you find any features in MetaPost or Tikz that you miss, don't hessitate to mail me. 

@section{Guide}
@local-table-of-contents[]
@include-section["coordinates.scrbl"]

@section{Reference}
@include-section["pt.scrbl"]
@include-section["colors.scrbl"]


@include-section["examples.scrbl"]

