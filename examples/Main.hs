{-# OPTIONS_GHC -Wno-x-partial #-}
-- | The article, run: two ways to get to two, and a generator with two
-- different filters.
module Main (main) where

import Expr
import Naturals
import Search

main :: IO ()
main = do
  section "Two ways to get to two"
  line ("two == two'                       " ++ show (two == two'))
  line ("take 5 evens == take 5 evens'     " ++ show (take 5 evens == take 5 evens'))
  line ("two `lessThan` infinity           " ++ show (two `lessThan` infinity))

  section "The space, and what the types prune before looking"
  let space = upToSize 5
      typed = filter typechecks space
  line (show (length space) ++ " expressions up to size 5; "
        ++ show (length typed) ++ " of them are Int -> Bool programs")

  section "The vibecoding filter: it looks right on what I tried"
  mapM_ vibe [3, 4, 5, 6, 8]

  section "The spec as a filter: head . filter meetsSpec $ samples llm prompt"
  report program

  section "A different model (random, seed 7), both filters"
  line ("tried 0..2:  " ++ pad (pretty randomVibe) ++ verdict randomVibe)
  line ("spec:        " ++ pad (pretty randomSpec) ++ verdict randomSpec)

  section "The ratchet: each check only removes candidates"
  let candidates = upToSize 7
      welltyped = filter typechecks candidates
      vibed = filter (passesTests (examples 3)) welltyped
      specd = filter satisfiesProperties vibed
      wrong = length . filter (\p -> counterexample 1000 p /= Nothing)
  line (show (length candidates) ++ " candidates up to size 7")
  line (show (length welltyped) ++ " typecheck")
  line (show (length vibed) ++ " also pass 0, 1, 2; " ++ show (wrong vibed) ++ " of them are wrong")
  line (show (length specd) ++ " also satisfy the properties; " ++ show (wrong specd) ++ " of them are wrong")
  where
    randomVibe = head . filter (looksRight (examples 3)) $ samples (sampler 7) "is x even?"
    randomSpec = head . filter meetsSpec $ samples (sampler 7) "is x even?"
    section s = putStrLn ("\n" ++ s)
    line = putStrLn . ("  " ++)
    vibe k = do
      let p = vibeProgram (examples k)
      line ("tried 0.." ++ show (k - 1) ++ ":  " ++ pad (pretty p) ++ verdict p)
    report p = line (pad (pretty p) ++ verdict p)
    verdict p = case counterexample 100000 p of
      Nothing -> "correct up to 100000"
      Just n  -> "wrong at x = " ++ show n
    pad s = take 34 (s ++ repeat ' ')
