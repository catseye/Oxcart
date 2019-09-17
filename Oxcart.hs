module Oxcart where

data Elem = Num Integer
          | Cont String
   deriving (Show, Ord, Eq)

type Op = [Elem] -> ([Elem] -> [Elem]) -> [Elem]


nop :: Op
nop  x k = k x

incr :: Op
incr ((Num x):xs) k = k (Num (x+1):xs)

dbl :: Op
dbl  ((Num x):xs) k = k (Num (x*2):xs)

m [] = nop
m (x:xs) = (m' x) `composeCPS` (m xs)
    where
        m' '+' = incr
        m' 'X' = dbl
        composeCPS f g = \x k -> (f x (\s -> (g s k)))


test = m "+XX" [Num 0] id
