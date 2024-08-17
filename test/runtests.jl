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
    function baz(::T, ::S) where {S <: Integer, T <: S}
    end

    @doc (@doc baz(::Float64))
    foobar(::Number) = nothing

    "blub"
    function fookw(x::Number, z::Number = 1; y::Number = 2)
    end
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

D = @docmatch foo(::Number) TestDocstrings
@test sprint(show, D) isa String
@test length(D) == 1

D = @docmatch baz TestDocstrings
@test sprint(show, D) isa String
@test length(D) == 3

D = @docmatch foobar TestDocstrings
@test sprint(show, D) isa String

D = @docmatch length
@test sprint(show, D) isa String

D = @docmatch fookw TestDocstrings
@test sprint(show, D) isa String
