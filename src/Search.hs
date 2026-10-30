{-# OPTIONS_GHC -Wno-x-partial #-}
-- | The article's pattern, made to run:
--
-- > programa = head . filter cumpleSpec $ muestras llm prompt
--
-- The "model" is a cheap stand-in for an LLM: something that, given a
-- prompt, produces a never-ending stream of candidate programs.
module Search
  ( Prompt, Model
  , samples, enumerator, sampler
  , Example, examples, looksRight
  , typechecks, passesTests, satisfiesProperties, meetsSpec
  , program, vibeProgram
  , counterexample
  ) where

import Data.List (find)
import Test.QuickCheck (Gen, chooseInt, elements, infiniteListOf, oneof, sized)
import Test.QuickCheck.Gen (unGen)
import Test.QuickCheck.Random (mkQCGen)

import Expr

type Prompt = String

-- | A model: a prompt in, an endless stream of candidates out.
type Model = Prompt -> [Expr]

samples :: Model -> Prompt -> [Expr]
samples llm prompt = llm prompt

-- | The most boring model there is: every expression, smallest first.
-- It ignores the prompt.
enumerator :: Model
enumerator _ = concatMap ofSize [1 ..]

-- | A model that samples at random (from a fixed seed, so runs repeat).
-- It ignores the prompt too; a real LLM would condition on it.
sampler :: Int -> Model
sampler seed _ = unGen (infiniteListOf expr) (mkQCGen seed) 6
  where
    expr :: Gen Expr
    expr = sized go
    go n
      | n <= 1 = oneof [pure X, Lit <$> chooseInt (0, 3)]
      | otherwise = oneof
          [ go 1
          , Not <$> go (n - 1)
          , elements [Add, Mod, Equal, Less, And, Or] <*> go (n `div` 2) <*> go (n `div` 2)
          ]

-- | What a person tries by hand: a few inputs and the expected outputs.
type Example = (Int, Bool)

examples :: Int -> [Example]
examples k = [(n, even n) | n <- [0 .. k - 1]]

-- | The vibecoding filter: it typechecks and it looks right on what I tried.
looksRight :: [Example] -> Expr -> Bool
looksRight exs p = typechecks p && passesTests exs p

passesTests :: [Example] -> Expr -> Bool
passesTests exs p = all (\(n, expected) -> eval p n == expected) exs

-- | The specification, as properties. No reference answer, just the three
-- equations that define evenness (the same as the article's esPar):
--
-- > f 0 == True
-- > f 1 == False
-- > f (n + 2) == f n          for every natural n
--
-- They're checked on QuickCheck-generated inputs, from a fixed seed so that
-- the filter stays a pure function. Like QuickCheck, the size grows with each
-- test: small inputs first, where boundary bugs live. (Drawing only large
-- random numbers lets @not (x == 1)@ through: the step property only fails
-- at n = 1.)
satisfiesProperties :: Expr -> Bool
satisfiesProperties p = eval p 0 && not (eval p 1) && all step inputs
  where
    step n = eval p (n + 2) == eval p n
    inputs = [unGen (chooseInt (0, size')) (mkQCGen (2026 + size')) size' | size' <- [0 .. 299]]

meetsSpec :: Expr -> Bool
meetsSpec p = typechecks p && passesTests (examples 3) p && satisfiesProperties p

-- | The article's line.
program :: Expr
program = head . filter meetsSpec $ samples enumerator "is x even?"

-- | The same line with the vibecoding filter instead.
vibeProgram :: [Example] -> Expr
vibeProgram exs = head . filter (looksRight exs) $ samples enumerator "is x even?"

-- | The smallest natural where a candidate disagrees with evenness, if any
-- below the bound.
counterexample :: Int -> Expr -> Maybe Int
counterexample bound p = find (\n -> eval p n /= even n) [0 .. bound]
