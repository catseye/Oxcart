Oxcart
======

While desigining [Wagon][] the topic of continuations briefly came up.
I didn't, at the time, think that thinking in terms of continuations
would make designing Wagon any easier.  But I did say that a
continuation-passing concatenative language sounded like an interesting
thing in its own right.

Later when I began thinking about how one would make 
continuation-passing concatenative language, I immediately hit a wall:
how do you compose two functions written in continuation-passing style?

So I sat down and worked it out.

Maybe you can do it, if you have a new kind of function composition.

If conventional function composition is defined as

    (f · g)(x) = g(f(x))

Then composition of CPS functions can be defined as

    (f ⊕ g)(x, κ) = f(x, λs′. g(s′, κ))

The question that remains is whether this is a workable substitute
for conventional function composition in a concatenative language.

This question has two parts: whether it's algebraically valid,
and whether it's useful for writing programs with.

The first part.  Functions form a monoid under composition;
there is an identity element (the identity function):

    f(x) = x

and composition is associative:

    ((f · g) · h) = (f · (g · h))

Can we devise an identity CPS function?  Yes.

    f(x, κ) = κ(x)

And is the operation ⊕ that we've defined, associative?
Well, let's try expanding it: (TODO)

    ((f ⊕ g) ⊕ h)
    …(f ⊕ g)(x, κ) = f(x, λs′. g(s′, λs″ . h(s″, κ)))

Versus:
    
    (f ⊕ (g ⊕ h))
    …(f ⊕ g)(x, κ) = f(x, λs′. g(s′, λs″ . h(s″, κ)))

