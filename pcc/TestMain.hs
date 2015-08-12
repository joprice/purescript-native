-------------------------------------------------------------------------------
--
-- Module      :  Main
-- Copyright   :  (c) 2015 Andy Arvanitis and other contributors
-- License     :  MIT
--
-- Maintainer  :  Andy Arvanitis
-- Stability   :  experimental
-- Portability :
--
--
--
-------------------------------------------------------------------------------
module Main where

import Data.List
import Control.Applicative
import Control.Monad

import System.Process
import System.FilePath
import System.Directory

-------------------------------------------------------------------------------
testsDir :: IO (FilePath, FilePath)
-------------------------------------------------------------------------------
testsDir = do
  baseDir <- getCurrentDirectory
  return (baseDir </> "pcc-tests", baseDir)

-------------------------------------------------------------------------------
main :: IO ()
-------------------------------------------------------------------------------
main = do

  (outputDir, baseDir) <- testsDir

  outputDirExists <- doesDirectoryExist outputDir
  when outputDirExists $ removeDirectoryRecursive outputDir
  createDirectory outputDir

  fetchPackages

  let srcDir = outputDir </> "src"
  createDirectory srcDir

  let buildDir = outputDir </> "build"
  createDirectory buildDir

  let makefile = outputDir </> "Makefile"
  writeFile makefile makefileText

  let passingDir = baseDir </> "examples" </> "passing"
  passingTestCases <- sort . filter (".purs" `isSuffixOf`) <$> getDirectoryContents passingDir

  let tests = filter (`notElem` skipped) passingTestCases

  -- Run the tests
  --
  forM_ tests $ \inputFile -> do
    --
    -- Compile PureScript file
    --
    putStrLn $ "Compiling test " ++ inputFile ++ " ..."
    setCurrentDirectory outputDir
    copyFile (passingDir </> inputFile) (srcDir </> inputFile)
    callProcess "make" ["clean", "main"]
    --
    -- Build and run C++ files
    --
    setCurrentDirectory buildDir
    callProcess "cmake" ["../output"]
    callProcess "make" []
    callProcess (buildDir </> "Main") []

    removeFile (srcDir </> inputFile)

  -- TODO: support failing test cases
  --
  -- let failing = baseDir </> "examples" </> "failing"
  -- failingTestCases <- sort . filter (".purs" `isSuffixOf`) <$> getDirectoryContents failing
  --

  setCurrentDirectory baseDir
  putStrLn "pcc-tests finished"
  putStrLn $ "Total tests available: " ++ show (length passingTestCases)
  putStrLn $ "Tests run: " ++ show (length tests)
  putStrLn $ "Tests skipped: " ++ show (length skipped)

-------------------------------------------------------------------------------
repo :: String
-------------------------------------------------------------------------------
repo = "git://github.com/pure14/"

-------------------------------------------------------------------------------
packages :: [String]
-------------------------------------------------------------------------------
packages =
  [ "purescript-eff"
  , "purescript-prelude"
  , "purescript-assert"
  , "purescript-st"
  , "purescript-console"
--  , "purescript-functions"
  ]

-------------------------------------------------------------------------------
fetchPackages :: IO ()
-------------------------------------------------------------------------------
fetchPackages = do
  (outputDir, baseDir) <- testsDir
  let packageDir = outputDir </> "packages"
  createDirectory packageDir
  setCurrentDirectory packageDir
  forM_ packages $ \package ->
    callProcess "git" ["clone", repo ++ package ++ ".git"]
  setCurrentDirectory baseDir

-------------------------------------------------------------------------------
makefileText :: String
-------------------------------------------------------------------------------
makefileText = intercalate "\n" lines'
  where lines' = [ "PCC := '../.cabal-sandbox/bin/pcc'"
                 , "MODULE_DIR='packages'"
                 , "SOURCE_DIR='src'"
                 , "MODULES := $(shell find $(MODULE_DIR) -name '*.purs' | grep -v \\/test\\/ | grep -v \\/example\\/ | grep -v \\/examples\\/)"
                 , "SOURCES := $(shell find $(SOURCE_DIR) -name '*.purs')"
                 , "all: main"
                 , "main:"
                 , "\t$(PCC) $(MODULES) $(SOURCES)"
                 , "clean:"
                 , "\t@rm -rf output/*"
                 ]

-------------------------------------------------------------------------------
skipped :: [String]
-------------------------------------------------------------------------------
skipped =
  [ "652.purs"
  , "CaseInDo.purs"
  , "Church.purs"
  , "Collatz.purs"
  , "DataAndType.purs"
  , "Do.purs"
  , "Dollar.purs"
  , "Eff.purs"
  , "EmptyDataDecls.purs"
  , "EmptyRow.purs"
  , "EmptyTypeClass.purs"
  , "ExtendedInfixOperators.purs" -- uses package purescript-functions
  , "Fib.purs" -- ST
  , "FinalTagless.purs"
  , "IfThenElseMaybe.purs"
  , "IntAndChar.purs"
  , "KindedType.purs"
  , "Let.purs"
  , "Let2.purs"
  , "LetInInstance.purs"
  , "LiberalTypeSynonyms.purs"
  , "MPTCs.purs"
  , "Monad.purs"
  , "MonadState.purs"
  , "MultiArgFunctions.purs" -- uses package purescript-functions
  , "MutRec.purs"
  , "MutRec2.purs"
  , "MutRec3.purs"
  , "Nested.purs"
  , "Newtype.purs"
  , "NewtypeEff.purs"
  , "NewtypeWithRecordUpdate.purs" -- extend obj
  , "NestedWhere.purs"
  , "ObjectGetter.purs"
  , "ObjectSynonym.purs"
  , "ObjectUpdate.purs" -- extend obj
  , "ObjectUpdate2.purs" -- extend obj
  , "ObjectUpdater.purs" -- extend obj
  , "ObjectWildcards.purs"
  , "Objects.purs"
  , "OperatorSections.purs"
  , "Operators.purs"
  , "PartialFunction.purs" -- assertThrows ?
  , "Person.purs"
  , "Rank2Data.purs"
  , "Rank2Object.purs"
  , "Rank2TypeSynonym.purs"
  , "Rank2Types.purs" -- TCO issue
  , "Patterns.purs"
  , "RebindableSyntax.purs"
  , "ReservedWords.purs" -- extend obj
  , "RowConstructors.purs"
  , "RowPolyInstanceContext.purs" -- extend obj
  , "RuntimeScopeIssue.purs"
  , "ScopedTypeVariables.purs"
  , "Sequence.purs"
  , "SequenceDesugared.purs"
  , "Superclasses2.purs"
  , "Superclasses3.purs"
  , "TCOCase.purs"
  , "TailCall.purs"
  , "TopLevelCase.purs"
  , "TypeClasses.purs"
  , "TypeSynonymInData.purs"
  , "TypeSynonyms.purs"
  , "TypedWhere.purs"
  , "UnderscoreIdent.purs"
  , "UnknownInTypeClassLookup.purs"
  , "Where.purs"
  ]
