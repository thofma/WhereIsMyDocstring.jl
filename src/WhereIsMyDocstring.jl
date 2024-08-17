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
  res = "(" * join(["::$(replace(string(T),r"[a-zA-Z]<:" => "<:"))" for T in x.parameters], ", ") * ")"
  while occursin("::<:", res)
    res = replace(res, "::<:" => "::")
  end
  return res
end

function _print_type(x::Type)
  if x isa Core.TypeofBottom
    return [""]
  end
  if x isa UnionAll
    res = _print_type_hint(x)
    return ["(::$x)\n    might need adjustment:", "$res"]
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
  printstyled(io, "\n  Include in ```@docs``` block:", color = :light_green)
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
  println(io, "\n", "="^displaysize(stdout)[2])
end

function _list_documenter_docstring(mod, ex)
  bind = Documenter.DocSystem.binding(mod, ex)
  typesig = Core.eval(mod, Base.Docs.signature(ex))
  return list_documenter_docstring(mod, bind; sig = typesig)
end

function list_documenter_docstring(mod, fun; sig = Union{})
  bind = Documenter.DocSystem.binding(mod, ex)
  return list_documenter_docstring(mod, bind; sig)
end

function list_documenter_docstring(mod, bind::Base.Docs.Binding; sig = Union{})
  res = Documenter.DocSystem.getdocs(bind, sig, modules = [mod])
  return [DocStr(r) for r in res]
end

function list_documenter_docstring(bind::Base.Docs.Binding; sig = Union{})
  res = Documenter.DocSystem.getdocs(bind, sig)
  return [DocStr(r) for r in res]
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
  bind = Documenter.DocSystem.binding(Main, ex)
  return list_documenter_docstring(bind, sig = typesig)
end

end # module WhereIsMyDocstring
