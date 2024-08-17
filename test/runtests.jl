using Test, WhereIsMyDocstring

module TestDocstrings
    "foo(::Number)"
    foo(::Number) = nothing

    "foo(::Float64)"
    foo(::Float64) = nothing

    "baz(::Number)"
    baz(::Number)

    "baz(::Float64)"
    baz(::Float64)

    "bla"
    baz(::T, ::S) where {S <: Integer, T <: S}
end

D = @docmatch foo
@test sprint(show, D) isa String
@test length(D) == 0
D = @docmatch foo(::Number)
@test sprint(show, D) isa String
@test length(D) == 0
D = @docmatch foo TestDocstrings
@test sprint(show, D) isa String
@test length(D) == 2
D = @docmatch baz TestDocstrings
@test sprint(show, D) isa String
@test length(D) == 3
