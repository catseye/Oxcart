module Language.Oxcart.Store where

import qualified Data.Map.Strict as Map


data Elem = Num Int
          | Cont (Store -> Store)

instance Show Elem where
    show (Num n)         = show n
    show (Cont k)        = "#k"

data Store = Store {
    index :: Integer,
    array :: Map.Map Integer [Elem]
}

instance Show Store where
    show Store{ index=index, array=array } =
        concat $ map renderStack (Map.toList array)
        where
            renderStack (i, []) = ""
            renderStack (i, s) =
              (
                (if index == i then ">" else " ") ++
                (if i < 0 then "" else " ") ++
                (show i) ++ ":" ++ (show s) ++ "\n"
              )

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

shift amount st@Store{ index=index } = st{ index=index + amount }
moveTo index st = st{ index=index }
