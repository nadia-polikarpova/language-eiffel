module Main where

import Control.Exception as E
import Control.Monad

import qualified Data.ByteString.Char8 as BS
import Data.List

import Language.Eiffel.PrettyPrint
import Language.Eiffel.Parser.Parser

import System.Directory
import System.FilePath

relativePaths = [".", ".."]

testDirectory dir = do
  allFiles <- getDirectoryContents dir
  let eFiles = filter ((== ".e") . snd . splitExtension) allFiles
  return $ map (combine dir) eFiles

allTestFiles :: IO [FilePath]
allTestFiles = do
  pwd <- getCurrentDirectory
  subdirs <- getDirectoryContents pwd
  subdirs' <- filterM doesDirectoryExist (subdirs \\ relativePaths)
  fileNames <- mapM testDirectory subdirs'
  return (concat fileNames)

test content = 
    let parse bstr = case parseClass (BS.pack bstr) of
                       Left e -> error (show e)
                       Right c -> c
        roundTrip = parse . show . toDoc . parse
    in parse content == roundTrip content

testFile fileName = do
  str <- readFile fileName
  let response = do
        pass <- evaluate $ test str
        if pass 
          then putStrLn $ "Passed: " ++ fileName
          else putStrLn $ "Failed: " ++ fileName ++ ", ASTs differ"
  E.catch response
          ( \ (ErrorCall s) -> putStrLn $ "Failed: " ++ fileName ++ ", parsing failed with:\n" ++ s)
main = do
  allTestFiles >>= mapM_ testFile