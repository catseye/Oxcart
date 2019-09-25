module Language.Oxcart.Store where

import qualified Data.Map.Strict as Map


data Elem = Num Integer
          | Cont ([Elem] -> [Elem])

instance Show Elem where
    show (Num n)         = show n
    show (Cont k)        = "#k"

type Op = [Elem] -> ([Elem] -> [Elem]) -> [Elem]

data Store = Store {
    index :: Integer,
    array :: Map.Map Integer [Elem]
} deriving (Show)



empty = Store{ index=0, array=Map.empty }

push v st@Store{ index=index, array=array } =
    let
        stack = Map.findWithDefault [] index array
        stack' = (v:stack)
        array' = Map.insert index stack' array
    in
        st{ array=array' }

pop st@Store{ index=index, array=array } =
    case Map.findWithDefault [] index array of
        (v:stack') ->
            (Just v, st{ array=Map.insert index stack' array })
        _ ->
            (Nothing, st)
