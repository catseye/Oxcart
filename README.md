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

    (f ⊕ g)(x, κ) = f(x, λs. g(s, κ))

or alternately,

    (f ⊕ g) = λ(x, κ). f(x, λs. g(s, κ))

The question that remains is whether this is a workable substitute
for conventional function composition in a concatenative language.

This question has two parts: whether it's algebraically valid,
and whether it's useful for writing programs with.

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

    = (λ(x, κ). f(x, λs. g(s, κ)) ⊕ h)

    replace (N ⊕ h) with λ(x, j). N(x, λt. h(t, j))
    where N = (λ(x, κ). f(x, λs. g(s, κ)))
    to get
    = λ(x, j). (λ(x, κ). f(x, λs. g(s, κ)))(x, λt. h(t, j))

    Now reduce (λ(x, κ). f(x, λs. g(s, κ)))(x, λt. h(t, j))
    by replacing in the lambda body
    x with x and
    κ with λt. h(t, j)
    to get
    f(x, λs. g(s, λt. h(t, j)))

    and the whole thing reads
    = λ(x, j). f(x, λs. g(s, λt. h(t, j)))

    which looks reasonable.

Versus:
    
    (f ⊕ (g ⊕ h))

    replace (g ⊕ h) with λ(x, κ). g(x, λs. h(s, κ)):

    = (f ⊕ λ(x, κ). g(x, λs. h(s, κ)))

    replace (f ⊕ N) with λ(x, j). f(x, λt. N(t, j))
    where N = (λ(x, κ). g(x, λs. h(s, κ)))
    to get
    
    = λ(x, j). f(x, λt. (λ(x, κ). g(x, λs. h(s, κ)))(t, j))

    Now reduce (λ(x, κ). g(x, λs. h(s, κ)))(t, j)
    by replacing in the lambda body
    x with t and
    κ with j
    to get
    g(t, λs. h(s, j))

    and the whole thing reads
    = λ(x, j). f(x, λt. g(t, λs. h(s, j)))

Yes!  It looks like it is!
