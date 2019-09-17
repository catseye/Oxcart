module Oxcart where

data Elem = Num Integer
          | Cont ([Elem] -> [Elem])

instance Show Elem where
    show (Num n)         = show n
    show (Cont k)        = "#k"

type Op = [Elem] -> ([Elem] -> [Elem]) -> [Elem]


nop :: Op
nop  xs k = k xs

push0 :: Op
push0 xs k = k ((Num 0):xs)

incr :: Op
incr ((Num x):xs) k = k (Num (x+1):xs)

dbl :: Op
dbl  ((Num x):xs) k = k (Num (x*2):xs)

save :: Op
save xs k = k (Cont k:xs)

rsr :: Op
rsr xs@((Cont k):_) _ = k xs



m [] = nop
m (x:xs) = (m' x) `composeCPS` (m xs)
    where
        m' '0' = push0
        m' '+' = incr
        m' 'X' = dbl
        m' '*' = save
        m' '$' = rsr
        composeCPS f g = \x k -> (f x (\s -> (g s k)))


run s = m s [] id

test = run "+XX"
