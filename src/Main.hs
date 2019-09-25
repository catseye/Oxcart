module Main where

import System.Environment
import Language.Oxcart.ConcatEval (run)


main = do
    [fileName] <- getArgs
    c <- readFile fileName
    putStrLn $ show $ run c
