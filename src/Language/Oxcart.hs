module Language.Oxcart where

data Elem = Num Integer
          | Cont ([Elem] -> [Elem])

instance Show Elem where
    show (Num n)         = show n
    show (Cont k)        = "#k"

type Op = [Elem] -> ([Elem] -> [Elem]) -> [Elem]


nop   xs k                = k xs
push0 xs k                = k ((Num 0):xs)
incr  ((Num x):xs) k      = k (Num (x+1):xs)
decr  ((Num x):xs) k      = k (Num (x-1):xs)
dbl   ((Num x):xs) k      = k (Num (x*2):xs)
save  xs k                = k (Cont k:xs)
rsr   ((Cont j):xs) _     = j xs
cont  xs@((Cont j):_) _   = j xs
swpk  xs@((Cont j):_) k   = j (Cont k:xs)


m [] = nop
m (x:xs) = (m' x) `composeCPS` (m xs)
    where
        m' '0' = push0
        m' '+' = incr
        m' '-' = decr
        m' 'X' = dbl
        m' '*' = save
        m' '$' = rsr
        m' '~' = cont
        m' '_' = swpk
        composeCPS f g = \x k -> (f x (\s -> (g s k)))


run s = m s [] id

test = run "0+XX"
