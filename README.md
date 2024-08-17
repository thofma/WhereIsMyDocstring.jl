# WhereIsMyDocstring

---

*Dude, where is my docstring?*

---


- Have you ever wondered, which docstring is included in a ```` ```@docs``` ```` when writing the documentation?
- Are you tired of finding the magic syntax to include the *right* docstring of a method?

Enter: WhereIsMyDocString.jl

## Status

[![Build Status](https://github.com/thofma/WhereIsMyDocstring.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/thofma/WhereIsMyDocstring.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/thofma/WhereIsMyDocstring.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thofma/WhereIsMyDocstring.jl)
[![Pkg Eval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/W/WhereIsMyDocstring.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html)

## Installation

Since WhereIsMyDocstring.jl is a registered package, it can be simply installed as follows:
```julia
julia> using Pkg; Pkg.install("WhereIsMyDocstring")
```

## Usage

The provides the `@docmatch` macro, which allows one to simulate the behaviour of ```` ```@docs``` ```` blocks interactively. This is helpful in case a function has many different methods and docstrings, and one wants to include a specific one. In particular in the presence of type parameters, this can be a frustrating experience due to https://github.com/JuliaLang/julia/issues/29437. Here is a simple example:

```julia
julia> using WhereIsMyDocstring

julia> @docmatch sin
2-element Vector{WhereIsMyDocstring.DocStr}:
 Base.sin
  Content:
    sin(x) [...]
  Signature type:
    Tuple{Number}
  Include in ```@docs``` block:
    Base.sin(::Number)
  Source:
   math.jl:490
====================================================================================

 Base.sin
  Content:
    sin(A::AbstractMatrix) [...]
  Signature type:
    Tuple{AbstractMatrix{<:Real}}
  Include in ```@docs``` block:
    Base.sin(::AbstractMatrix{<:Real})
  Source:
   /usr/share/julia/stdlib/v1.10/LinearAlgebra/src/dense.jl:956
====================================================================================
```
The macro returns the docstrings (including metadata). In view of ```` ```@docs ``` ```` blocks, the most imporant information is the "Include in ..." field. This provides the right invocation to include the specific docstring. For example, if we want to include the second docstring, in our documentation markdown source we would write:
````
```@docs
Base.sin(::AbstractMatrix{<:Real})
````

A more complicated example would be
````
julia> s
```

