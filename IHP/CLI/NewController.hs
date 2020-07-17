module Main where

import ClassyPrelude
import Data.String.Conversions (cs)
import qualified System.Directory as Directory
import qualified System.Posix.Env.ByteString as Posix
import Control.Monad.Fail
import IHP.IDE.CodeGen.ControllerGenerator
import IHP.IDE.CodeGen.Controller (executePlan)
import qualified Data.Text as Text

main :: IO ()
main = do
    ensureIsInAppDirectory

    args <- map cs <$> Posix.getArgs
    case headMay args of
        Just "" -> usage
        Just appAndControllerName -> do
            generateController appAndControllerName

usage :: IO ()
usage = putStrLn "Usage: new-controller RESOURCE_NAME"


ensureIsInAppDirectory :: IO ()
ensureIsInAppDirectory = do
    mainHsExists <- Directory.doesFileExist "Main.hs"
    unless mainHsExists (fail "You have to be in a project directory to run the generator")

normalizeAppAndControllerName :: Text -> [Text]
normalizeAppAndControllerName appAndControllerName = Text.splitOn "." appAndControllerName

generateController :: Text -> IO ()
generateController appAndControllerName = do
    case Text.splitOn "." appAndControllerName of
        [controllerName] -> do
            planOrError <- buildPlan controllerName "Web"
            case planOrError of
                Left error -> putStrLn error
                Right plan -> executePlan plan
        [applicationName, controllerName] -> do
            planOrError <- buildPlan controllerName applicationName
            case planOrError of
                Left error -> putStrLn error
                Right plan -> executePlan plan
        _ -> usage

    