module Action (add, query, list, edit, dump) where

import           System.IO
import           System.Process
import           Control.DeepSeq (deepseq)

import           Util (nameFromUrl, run, withTempFile)
import           Options (Options)
import qualified Options
import           Database (Entry(..))
import qualified Database

add :: String -> Options -> IO ()
add url_ opts = do
  login_ <- genLogin
  password_ <- genPassword
  addEntry $ Entry {entryName = nameFromUrl url_, entryLogin = login_, entryPassword = password_, entryUrl = url_}
  where
    genLogin :: IO String
    genLogin = fmap init $ readProcess "pwgen" ["-s"] ""

    genPassword :: IO String
    genPassword = fmap init $ readProcess "pwgen" ["-s", "20"] ""

    addEntry :: Entry -> IO ()
    addEntry entry =
      -- An Entry may have pending exceptions (e.g. invalid URL), so we force
      -- them with `deepseq` before we read the database.  This way the user
      -- gets an error before he has to enter his password.
      entry `deepseq` do
        db <- Database.open $ Options.databaseFile opts
        case Database.addEntry db entry of
          Left err  -> fail err
          Right db_ -> Database.save db_

query :: String -> Options -> IO ()
query kw opts = do
  db <- Database.open $ Options.databaseFile opts
  case Database.lookupEntry db kw of
    Nothing -> putStrLn "no match"
    Just x  -> do
      putStrLn $ entryUrl x
      open (entryUrl x)
      xclip (entryLogin x)
      xclip (entryPassword x)
  where
    xclip :: String -> IO ()
    xclip input = readProcess "xclip" ["-l", "2", "-quiet"] input >> return ()

    open :: String -> IO ()
    open url = run "gnome-open" [url]

list :: Options -> IO ()
list opts = do
  db <- Database.open $ Options.databaseFile opts
  mapM_ putStrLn $ Database.entrieNames db

edit :: Options -> IO ()
edit Options.Options {Options.databaseFile = databaseFile} = withTempFile $ \fn h -> do
  putStrLn $ "using temporary file: " ++ fn
  Database.decrypt databaseFile >>= hPutStr h >> hClose h
  run "vim" ["-n", "-i", "NONE", "-c", "set nobackup", "-c", "set ft=dosini", fn]
  readFile fn >>= Database.encrypt databaseFile
  run "shred" [fn]

dump :: Options -> IO ()
dump opts = Database.decrypt databaseFile >>= putStr
  where databaseFile = Options.databaseFile opts