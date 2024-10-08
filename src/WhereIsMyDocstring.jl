module WhereIsMyDocstring

using Documenter

export @docmatch

mutable struct DocStr
  binding
  mod
  source
  signature
  text

  function DocStr(D::Base.Docs.DocStr)
    d = new()
    if length(D.text) > 0
      d.text = D.text[1]
    else
      if isdefined(D, :object)
        d.text = string(D.object)
      else
        d.text = ""
      end
    end
    d.text = lstrip(d.text, '`')
    d.text = lstrip(d.text)
    d.binding = D.data[:binding]
    d.mod = D.data[:module]
    d.source = D.data[:path] * ":" * string(D.data[:linenumber])
    d.signature = D.data[:typesig]
    return d
  end
end

# Some type printing gymnastics for the signatures

function _name(x)
  S = string(x)
  r1 = r"([a-zA-Z1-9]*)<:([a-zA-Z1-9]*)"
  r2 = r"([a-zA-Z1-9]*)<:(.+?)<:([a-zA-Z1-9]*)"
  while match(r2, S) !== nothing
    S = replace(S, r2 => s"\2")
  end
  
  while match(r1, S) !== nothing
    S = replace(S, r1 => s"\1")
  end
  return S
end

function _print_type_hint(x::Type)
  @assert x isa UnionAll
  vars = []
  while x isa UnionAll
    push!(vars, x.var)
    x = x.body
  end
  while x isa Union
    x = x.b
  end
  @assert x <: Tuple
  res = "(" * join(["::$(_name(T))" for T in x.parameters], ", ") * ")"
  while occursin("::<:", res)
    res = replace(res, "::<:" => "::")
  end
  while occursin("<:<:", res)
    res = replace(res, "<:<:" => "<:")
  end

  return res * " where {" * join(vars, ", ") * "}"
end

function _print_type(x::Type)
  if x isa Core.TypeofBottom
    return [""]
  end
  if x isa UnionAll
    res = _print_type_hint(x)
    return ["(::$x)\n    try the following:", "$res"]
  end
  _print_type_real(x)
end

function _print_type_real(x)
  if x isa Union
    return append!(_print_type_real(x.a), _print_type_real(x.b))
  elseif x <: Tuple
    return ["(" * join(["::$(T)" for T in x.parameters], ", ") * ")"]
  else
    return ["(::$x)"]
  end
end

function Base.show(io::IO, d::DocStr)
  printstyled(io, d.binding, bold = true)
  text = join(split(d.text, "\n")[1:1], "\n")
  printstyled(io, "\n  Content:", color = :light_green)
  printstyled(io, "\n    ", text, " [...]", italic = true)
  printstyled(io, "\n  Signature type:", color = :light_green)
  printstyled(io, "\n    ", d.signature)
  printstyled(io, "\n  Include in ```@docs``` block one of the following:", color = :light_green)
  for s in _print_type(d.signature)
    print(io, "\n    ")
    print(io, "$(d.binding)")
    # now print s
    if occursin("might need adjustment:", s)
      ss = split(s, "might need adjustment:")
      print(io, ss[1])
      printstyled(io, "might need adjustment:"; color = :light_yellow)
      print(io, ss[2])
    else
      print(io, s)
    end
  end
  printstyled(io, "\n  Source:", color = :light_green)
  printstyled(io, "\n   ", d.source, color = :light_grey)
  print(io, "\n", "="^displaysize(stdout)[2])
end

function _list_documenter_docstring(mod, ex)
  bind = Documenter.DocSystem.binding(mod, ex)
  typesig = Core.eval(mod, Base.Docs.signature(ex))
  return list_documenter_docstring(mod, bind; sig = typesig)
end

function list_documenter_docstring(mod, fun; sig = Union{})
  bind = Documenter.DocSystem.binding(mod, ex)
  return list_documenter_docstring(mod, bind; sig = sig)
end

function list_documenter_docstring(mod, bind::Base.Docs.Binding; sig = Union{})
  res = Documenter.DocSystem.getdocs(bind, sig, modules = [mod])
  return [DocStr(r) for r in res]
end

function list_documenter_docstring(bind::Base.Docs.Binding; sig = Union{})
  res = Documenter.DocSystem.getdocs(bind, sig)
  return [DocStr(r) for r in res]
end

"""
    @docmatch f
    @docmatch f(sig)
    @docmatch f module
    @docmatch f(sig) module

Retrieves all docstrings that would be included in the block
````
```@docs
f
```
````
or
````
```@docs
f(sig)
```
````
The optional argument `module` controls in which module to look for `f`.

#### Example

```
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
================================================================================
 Base.sin
  Content:
    sin(A::AbstractMatrix) [...]
  Signature type:
    Tuple{AbstractMatrix{<:Real}}
  Include in ```@docs``` block:
    Base.sin(::AbstractMatrix{<:Real})
  Source:
    /usr/share/julia/stdlib/v1.10/LinearAlgebra/src/dense.jl:956
```
"""
macro docmatch
end

macro docmatch(ex)
  bind = Documenter.DocSystem.binding(Main, ex)
  typesig = Core.eval(Main, Base.Docs.signature(ex))
  return list_documenter_docstring(bind, sig = typesig)
end

macro docmatch(ex, mod)
  # (awkward)
  # mod is evaluated directly to get the module (I don't want to eval this)
  # but the expression for the function (+ signature)
  # needs to be passed to the Documenter function as an expression,
  # which is later eval'ed
  return quote
    _list_documenter_docstring($(esc(mod)), $(QuoteNode(ex)))
  end
end

end # module WhereIsMyDocstring
