module Main where

import System.Environment
import Language.Oxcart (run)


main = do
    [fileName] <- getArgs
    c <- readFile fileName
    putStrLn $ show $ run c
