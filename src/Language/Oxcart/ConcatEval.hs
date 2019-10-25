module Language.Oxcart.ConcatEval where

import Language.Oxcart.Store

--
-- Given two continuation-passing-style functions,
-- return a function that composes them in continuation-passing style.
-- This operation is associative, and the set has an identity element,
-- so this has all the relevant properties of conventional function composition.
--

composeCPS f g = \x k -> (f x (\s -> (g s k)))


--
-- Type of our operations in Oxcart.
--

type Op = Store -> (Store -> Store) -> Store


--
-- Helper function.
--

carry delta st =
    let
        (Just v, st') = pop st
        st'' = (shift delta st')
        st''' = push v st''
    in
        st'''


--
-- Some basic operations.  These are all type Op.
--


nop st k = k st
push0 st k = k $ push (Num 0) st
incr st k = let (Just (Num n), st') = pop st in k (push (Num (n+1)) st')
decr st k = let (Just (Num n), st') = pop st in k (push (Num (n-1)) st')
dup st k = let (Just v, st') = pop st in k (push v (push v st'))
pop' st k = let (Just v, st') = pop st in k st'
swap st k = 
    let
        (Just a, st') = pop st
        (Just b, st'') = pop st'
    in
        k $ push b (push a st'')

left st k = k $ shift (-1) st
right st k = k $ shift 1 st
cleft st k = k $ carry (-1) st
cright st k = k $ carry 1 st
reset st k = k $ moveTo 0 st
swch st k =
    let
        (Just (Num n), st') = pop st
        (Just v, st'') = pop st'
    in
        case (n, v) of
            (0, (Num d))  -> k (shift (fromIntegral d) st'')
            (_, _)        -> k st''
tele st k =
    let
        (Just (Num n), st') = pop st
        (Just v, st'') = pop st'
        st''' = moveTo (fromIntegral n) st''
    in
        k $ push v st'''

save st k = k $ push (Cont k) st
rsr st k =
    let
        (Just (Num n), st') = pop st
        (Just v, st'') = pop st'
    in
        case (n, v) of
            (0, _)        -> k st''
            (_, (Cont j)) -> j st''
            (_, _)        -> k st''


-- cont  xs@((Cont j):_) _   = j xs
-- swpk  xs@((Cont j):_) k   = j (Cont k:xs)


--
-- Map characters to basic operations, so we can denote programs
-- with strings.
--

m :: String -> Op
m [] = nop
m (x:xs) = (m' x) `composeCPS` (m xs)
    where
        m' '0' = push0
        m' '^' = incr
        m' 'v' = decr
        m' ':' = dup
        m' '$' = pop'
        m' '\\' = swap

        m' '<' = left
        m' '>' = right
        m' '(' = cleft
        m' ')' = cright
        m' '\'' = reset
        m' 'Y' = swch
        m' 'T' = tele

        m' 'S' = save
        m' '%' = rsr
        -- m' '~' = cont
        -- m' '_' = swpk
        m' ' ' = nop
        m' '\n' = nop

run :: String -> Store
run s = m s empty id
