Oxcart
======

While desigining [Wagon][] the topic of continuations briefly came up.
I didn't, at the time, think that thinking in terms of continuations
would make designing Wagon any easier.  But I did remark that a
continuation-passing concatenative language sounded like an interesting
thing in its own right.

Later when I began thinking about how one would make 
continuation-passing concatenative language, I immediately hit a wall:
how do you compose two functions written in continuation-passing style?

So I sat down and worked it out.  Maybe you can do it if you adopt a
non-standard formulation of function composition.

If conventional function composition is defined as

    (f · g)(x) = g(f(x))

Then composition of CPS functions can be defined as

    (f ⊕ g)(x, κ) = f(x, λs. g(s, κ))

or alternately,

    (f ⊕ g) = λ(x, κ). f(x, λs. g(s, κ))

The question that remains is whether this is a workable substitute
for conventional function composition in a concatenative language.

This question has two parts: whether it's algebraically valid,
and whether it's useful for writing programs with.

Algebraic properties of ⊕
-------------------------

The first part.  Functions form a monoid under composition;
there is an identity element (the identity function):

    e(x) = x

and this is an identity because

    (e · f)(x) = f(e(x)) = f(x)
    (f · e)(x) = e(f(x)) = f(x)

and composition is associative:

    ((f · g) · h) = (f · (g · h))

because

    ((f · g) · h) = (f · (g · h))
    (g(f(x)) · h) = (f · (h(g(x)))
    (h(g(f(x))) = (h(g(f(x))))

Can we devise an identity CPS function?  I think it might be:

    e(x, κ) = κ(x)

and this is an identity because

    (e ⊕ f)(x, κ) = e(x, λs. f(s, κ)) = (λs. f(s, κ))(x) = f(x, κ)
    (f ⊕ e)(x, κ) = f(x, λs. e(s, κ)) = f(x, λs. κ(s))) = f(x, κ)

And is ⊕  associative?  Well, let's try expanding it:

    ((f ⊕ g) ⊕ h)
    
    replace (f ⊕ g) with λ(x, κ). f(x, λs. g(s, κ)):

    (λ(x, κ). f(x, λs. g(s, κ)) ⊕ h)

    replace (N ⊕ h) with λ(x, j). N(x, λt. h(t, j))
    where N = (λ(x, κ). f(x, λs. g(s, κ)))
    to get

    λ(x, j). (λ(x, κ). f(x, λs. g(s, κ)))(x, λt. h(t, j))

    Now reduce (λ(x, κ). f(x, λs. g(s, κ)))(x, λt. h(t, j))
    by replacing in the lambda body
    x with x and
    κ with λt. h(t, j)
    to get
    f(x, λs. g(s, λt. h(t, j)))

    and the whole thing reads

    λ(x, j). f(x, λs. g(s, λt. h(t, j)))

    which looks reasonable.

Versus:
    
    (f ⊕ (g ⊕ h))

    replace (g ⊕ h) with λ(x, κ). g(x, λs. h(s, κ)):

    (f ⊕ λ(x, κ). g(x, λs. h(s, κ)))

    replace (f ⊕ N) with λ(x, j). f(x, λt. N(t, j))
    where N = (λ(x, κ). g(x, λs. h(s, κ)))
    to get
    
    λ(x, j). f(x, λt. (λ(x, κ). g(x, λs. h(s, κ)))(t, j))

    Now reduce (λ(x, κ). g(x, λs. h(s, κ)))(t, j)
    by replacing in the lambda body
    x with t and
    κ with j
    to get
    g(t, λs. h(s, j))

    and the whole thing reads

    λ(x, j). f(x, λt. g(t, λs. h(s, j)))

Yes!  It looks like it is!

A concatenative language with ⊕
-----------------------------

Now the second part.  This requires us to actually try to define some
kind of concatenative language around this formulation of composition,
and see what kind of programs we can write in it.

Like [Carriage][] and [Equipage][] and [Wagon][], this will be
a "purely concatenative language": the entire program is a single
string of sequentially concatenated symbols, and each symbol
represents a function, and the functions are sequentially composed
in the same manner the symbols are concatenated.  More to the point,
you don't get to name anything or to nest anything inside anything else.

Unlike [Wagon][] we won't be concerned with expressing control
outside of the program state.  Indeed, first-class continuations are
a way to reify control as data, so we'll happily make them part of
the data store.

I'm sure we could get away with having a single stack for the store,
like most concatenative languages, but to make things easier (maybe)
let's deviate slightly.  A store, in Oxcart, is a tape of stacks.
That is, it's an unbounded array of stacks, plus an index into that
array.  The index is initially 0 but can be changed; the stack that
it points to is referred to as "the current stack", and most
operations operate on the current stack.

Each stack is strictly FIFO and initially empty, and each stack cell
can hold either an int or a continuation.  Ints are generally assumed
to be 64 bits in this day and age, but it pays to be cautious.

    -> Tests for functionality "Evaluate Oxcart Program"

    -> Functionality "Evaluate Oxcart Program" is implemented by
    -> shell command "bin/oxcart %(test-body-file)"

The instruction `0` pushes a zero onto the current stack.

    | 0
    = > 0:[0]

Whitespace is a no-op.

    |       
    = 

These demonstrate how Oxcart stores are represented on output by
the reference implementation: the current stack is indicated by `>`,
its index is printed, then `:`, then its contents, top-to-bottom.
But only stacks that are non-empty are output.

The instruction `^` (resp. `v`) pops a value from the current stack,
increments (resp. decrements) it, and pushes the result back onto the
current stack.

    | 0^^^0vv
    = > 0:[-2,3]

The instruction `X` pops a value from the current stack, doubles
it, and pushes the result back onto the current stack.

    | 0^XXXX
    = > 0:[16]

The instruction `<` (resp `>`) moves one space left (resp. right)
on the tape, changing which stack is the current stack.

    | 0^XX<0^XXX<0^XXXX>
    =  -2:[16]
    = >-1:[8]
    =   0:[4]

The instruction `(` (resp `)`) pops a value off the current stack,
moves one space left (resp. right) on the tape, and pushes the value
onto the new current stack.

    | 0^XX<0^XXX(0^XXXX)
    =  -2:[8]
    = >-1:[16]
    =   0:[4]

[Carriage]: https://catseye.tc/node/Carriage
[Equipage]: https://catseye.tc/node/Equipage
[Wagon]: https://catseye.tc/node/Wagon
