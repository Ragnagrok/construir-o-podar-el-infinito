-- | The same claims as the demo, checked with QuickCheck's own random
-- generation (a fresh seed every run).
module Main (main) where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Test.QuickCheck

import Expr
import Naturals
import Search

data Expect = Holds | Fails

check :: Testable p => Expect -> String -> p -> IO Bool
check expect name p = do
  r <- quickCheckWithResult stdArgs { chatty = False, maxSuccess = 10000 } p
  let ok = case expect of
        Holds -> isSuccess r
        Fails -> not (isSuccess r)
      verdict = case (expect, isSuccess r) of
        (Holds, True)  -> "holds"
        (Fails, False) -> "fails, as expected: " ++ unwords (failingTestCase r)
        (Holds, False) -> "FAILED: " ++ unwords (failingTestCase r)
        (Fails, True)  -> "HELD, and it shouldn't"
  putStrLn ((if ok then "ok   " else "FAIL ") ++ name ++ ": " ++ verdict)
  pure ok

isEvenProgram :: Expr -> NonNegative Int -> Bool
isEvenProgram p (NonNegative n) = eval p n == even n

main :: IO ()
main = do
  results <- sequence
    [ check Holds "two == two'" (two == two')
    , check Holds "evens and evens' agree" (\(NonNegative k) -> take (k `mod` 50) evens == take (k `mod` 50) evens')
    , check Holds "isEven agrees with even" (\(NonNegative k) -> isEven (nats !! (k `mod` 500)) == even (k `mod` 500))
    , check Holds ("the spec's pick (" ++ pretty program ++ ") is even")
        (isEvenProgram program)
    , check Fails ("the vibe pick after three tries (" ++ pretty (vibeProgram (examples 3)) ++ ") is even")
        (isEvenProgram (vibeProgram (examples 3)))
    ]
  unless (and results) exitFailure
