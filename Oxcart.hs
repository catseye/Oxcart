module Oxcart where

composeCPS f g = \x k -> (f x (\s -> (g s k)))

nop  x k = k x
incr x k = k (x+1)
dbl  x k = k (x*2)

t1 = incr 10 (\x -> dbl x id)
t2 = (incr `composeCPS` dbl) 10 id

m [] = nop
m (x:xs) = (m' x) `composeCPS` (m xs)
    where
        m' '+' = incr
        m' 'X' = dbl

t3 = (m "+XX") 10 id
