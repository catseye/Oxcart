Oxcart
======

While desigining [Wagon][] the topic of continuations briefly came up.
I didn't, at the time, think that thinking in terms of continuations
would make designing Wagon any easier.  But I did remark that a
continuation-passing concatenative language sounded like an interesting
thing in its own right.

After Wagon was finished, I began thinking about how one would make
continuation-passing concatenative language, but I immediately hit a wall:
how do you compose two functions written in continuation-passing style?

So I sat down and worked it out.  Maybe you can do it, I thought, if you
adopt a non-standard formulation of function composition.

If conventional function composition is defined as

    (f ∘ g)(x) = g(f(x))

then, rather arbitrarily picking the symbol ⊛ to denote it, composition
of CPS functions can be defined as

    (f ⊛ g)(x, κ) = f(x, λs. g(s, κ))

or alternately,

    (f ⊛ g) = λ(x, κ). f(x, λs. g(s, κ))

The question that remains is whether this is a workable substitute
for conventional function composition in a concatenative language.

This question has two parts: whether it's algebraically valid,
and whether it's useful for writing programs with.

Algebraic properties of ⊛
-------------------------

The first part.  Functions form a monoid under composition;
there is an identity element (the identity function):

    e(x) = x

and this is an identity because

    (e ∘ f)(x) = f(e(x)) = f(x)
    (f ∘ e)(x) = e(f(x)) = f(x)

and composition is associative:

    ((f ∘ g) ∘ h) = (f ∘ (g ∘ h))

because

    ((f ∘ g) ∘ h) = (f ∘ (g ∘ h))
    (g(f(x)) ∘ h) = (f ∘ (h(g(x)))
    (h(g(f(x))) = (h(g(f(x))))

Can we devise an identity CPS function?  I think it might be:

    ι(x, κ) = κ(x)

and this is an identity because

    (ι ⊛ f)(x, κ) = ι(x, λs. f(s, κ)) = (λs. f(s, κ))(x) = f(x, κ)
    (f ⊛ ι)(x, κ) = f(x, λs. ι(s, κ)) = f(x, λs. κ(s))) = f(x, κ)

And is ⊕  associative?  Well, let's try expanding it:

    ((f ⊛ g) ⊛ h)
    
    replace (f ⊛ g) with λ(x, κ). f(x, λs. g(s, κ)):

    (λ(x, κ). f(x, λs. g(s, κ)) ⊛ h)

    replace (N ⊛ h) with λ(x, j). N(x, λt. h(t, j))
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
    
    (f ⊛ (g ⊛ h))

    replace (g ⊛ h) with λ(x, κ). g(x, λs. h(s, κ)):

    (f ⊛ λ(x, κ). g(x, λs. h(s, κ)))

    replace (f ⊛ N) with λ(x, j). f(x, λt. N(t, j))
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

A concatenative language with ⊛
-------------------------------

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

### Basic operations

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
followed by its index, then `:`, then its contents, top-to-bottom.
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

The instruction `:` pops a value from the current stack and pushes
two copies of the value back on the stack.

    | 0^XXX:^
    = > 0:[9,8]

The instruction `$` pops a value from the current stack and discards
it.

    | 0^XXX$
    = 

The instruction `\\` pops the top two values, swaps them, and pushes
them back on the stack.

    | 0^XXX0^\0^^
    = > 0:[2,8,1]

### Navigating the stacks

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

The instruction `'` (apostrophe) makes stack zero (the stack that
was current when the program started) the current stack, no matter
what stack is currently the current stack.

    | >>>'0^>>'0^
    = > 0:[1,1]

The instruction `Y` pops a first value off the stack, then a second
value off the stack.

If the first value is non-zero, nothing else in particular happens
and evaluation continues as usual.

    | 0^^0^0^Y0^^^
    = > 0:[3,2]

But if the first value is zero, the second value is added to the
position of the tape cell (negative values go left, positive values
go right).

    | 0^^0^0Y0^^^
    =   0:[2]
    = > 1:[3]

    | 0^^0v0Y0^^^
    = >-1:[3]
    =   0:[2]

### Operations involving continuations

The instruction `S` pushes the current continuation onto the stack.
Note that continuations don't have a defined representation other
than `#k`.

    | S
    = > 0:[#k]

The instruction `%` pops a first value off the stack, then a second
value off the stack.

If the first value is zero, nothing happens and evaluation continues
as usual.

    | S0%
    = 

But if the first value is non-zero, it replaces the current continuation
with the second value, and continues with that continuation.

    | 0^^^0S0^%
    = > 0:[3]

In the preceding example, when `%` is evaluated, the 1 pushed by the `0^`
just before the `%`, and the continuation pushed by `S`, are popped off
the stack (leaving 0 and 3 on the stack.)  The 1 is judged to be non-zero,
so the continuation pushed by `S` is continued.  That continuation
represents the remainder of the program that consists of `0^%`.  So a
1 is pushed onto the stack and `%` is evaluated again.  But this time
`%` gets a 1 and a 0, which is not a continuation, so things continue
as usual.  The result is only the initial 3 on the stack.

### Infinite loop

So we want to write an infinite loop.  In high-level terms, we need to
save the current continuation in a value _k_.  (Note that when we continue
_k_, we'll end up back at this point.)  Then we want to continue _k_.
(Note that, since we end up back at that point noted previously, we never
get to this point.)

We can write this in Oxcart as:

    S:0^%

(We don't write this as a Falderal test, because we want all our tests
to terminate.  But it is provided as a discrete program in the `eg/`
directory, if you want to run it.)

### Controlled loop

So we want to write a loop that terminates.  Say we want to generate
the numbers from 10 down to 0.  In high-level terms, we set a value
_n_ to 10, and save the current continuation as _k_.  Then we make
a copy of _n_ and decrement it to obtain _n'_.  Then we make a copy
of _n'_ and test if it's zero.  If it is, we're done.  If not, we
continue _k_.

We can write this in Oxcart as:

*   move left
*   push 10 on stack
*   move right
*   push current continuation on stack
*   duplicate
*   move left
*   duplicate
*   decrement
*   duplicate
*   transfer right
*   continue conditionally

Or, as an actual Oxcart program:

    | <0^^^^^^^^^^>S:<:v:)%
    =  -1:[0,1,2,3,4,5,6,7,8,9,10]
    = > 0:[#k]

### While loop?

So, while we've demonstrated it's possible to write a controlled loop,
it is in fact a "repeat" (or "do") type loop, where the loop body is
always executed at least once.  What about a "while" type loop, where
the loop body might not be executed at all, if the loop condition isn't
true when the loop starts?

You may have noticed that the "current continuation" is a very palpable
concept in Oxcart; using the infinite loop program to illustrate, it is
almost as if concatenating the program symbols results in a program
structured like this:

    S→:→0→^→%→■

where each → is a continuation, and ■ is HALT, and execution happens by
executing one instruction, then just following the attached arrow to get
to the next instruction to execute.  An instruction like `S` has the
effect of pushing the arrow (and, virtually, everything that follows it)
onto the stack, and an instruction like `%` also has an arrow attached
to it, but that arrow is ignored; an arrow popped off the stack is
followed instead.

But one implication of this is that an Oxcart program can't access
any continuation it hasn't already "seen", i.e. any continuations that
it might encounter down the line, in the future.  In more pedestrian
terms, you can't denote a forward jump.

And that means we can't write a "while" loop in the usual manner.

But perhaps we can write one in a slightly unconventional manner.

The idea is this: the body of the loop is executed at least once,
but it is executed in a context where it has no effect on anything
we care about.

This might not work, but let's try to work it out.

So we want to write a "while" loop.  Say we have an _n_ on the
stack, and we want to loop _n_ times, and _n_ might be zero.

In high-level terms, we first move to a "garbage" stack and
place a "garbage _n_" on it.

Then, we save the current continuation as _k_.

We test if _n_ is zero.  If it is, we switch to a garbage stack.

Then, assuming we're on the real stack, we make a copy of _n_ and
decrement it to obtain _n'_.  Then we make a copy of _n'_ and test
if it's zero.  If it is, we're done.  If not, we continue _k_.

But, assuming we're on the garbage stack, the above becomes:
we make a copy of garbage _n_ and decrement it to obtain
garbage _n'_.  Then we make a copy of garbage _n'_ and test
if it's zero.  If it is, we're done.  If not, we continue _k_.

This suggests our initial garbage _n_ should be 1.

The problem is that we want to switch back from the
garbage stack to the real stack if previously we were on
the garbage stack.

Can we can write this in Oxcart?

*   transfer left (to move n to the data stack, -1)
*   move left (to garbage stack, -2)
*   push 1 on stack
*   reset to the main stack
*   push current continuation on stack
*   duplicate
*   move left
*   duplicate
*   pop and if value is zero move one stack to the left
*   duplicate
*   decrement
*   duplicate
*   transfer right (this is the test value)
*   reset to the main stack
*   continue conditionally

Is this it?

    > | 0^^^^^
    > | (<0^'S:<:0v\:v:)'%
    > =  -2:[1]
    > =  -1:[5]

    | 0^^^^^
    | (<0^'S:<:0v\0
    =  -2:[1]
    =  -1:[5]

OK. Let's try implementing it in small bits, then put them all together.

We demonstrate (with an initial n=5) that we can move _n_ to the
"data stack" (stack -1), then put a 1 on the "garbage stack"
(stack -2),

    | 0^^^^^
    | (<0^'
    =  -2:[1]
    =  -1:[5]

### Minimality of Oxcart

Oxcart is not a minimal language.  It defines operations that are
not needed to be Turing-complete.

One could say that "Core Oxcart" omits the following operations:

    X<>\\

`X` can probably be implemented with a loop.

`<` and `>` can be thought of as just shorthands for `0v0^Y` and
`0^0^Y`.

`\\` can be implemented with `<()>`, or in fact you can build a
"rotate" of arbitrary finite depth with those.

    | 0^0^^
    = > 0:[2,1]

    | 0^0^^)<(>>(<)
    = > 0:[1,2]

[Carriage]: https://catseye.tc/node/Carriage
[Equipage]: https://catseye.tc/node/Equipage
[Wagon]: https://catseye.tc/node/Wagon
