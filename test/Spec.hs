module Main (main) where

import           Test.Hspec.ShouldBe

import qualified OptionsSpec
import qualified LockSpec
import qualified DatabaseSpec
import qualified ActionSpec
import qualified CipherSpec

main :: IO ()
main = hspecX $ do
  describe "Lock"     LockSpec.spec
  describe "Options"  OptionsSpec.spec
  describe "Database" DatabaseSpec.spec
  describe "Action"   ActionSpec.spec
  describe "Cipher"   CipherSpec.spec
