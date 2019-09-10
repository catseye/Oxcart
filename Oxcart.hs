module Oxcart where


composeCPS f g = \x k -> (f x (\s -> (g s k)))

incr x k = k (x+1)
dbl  x k = k (x*2)

t1 = incr 10 (\x -> dbl x id)
t2 = (incr `composeCPS` dbl) 10 id
