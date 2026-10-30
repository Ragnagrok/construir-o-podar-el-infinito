{-# OPTIONS_GHC -Wno-x-partial #-}
-- | The article's first example: two ways to get to two.
module Naturals
  ( N (..)
  , two, nats, two'
  , isEven, evens, evens'
  , infinity, lessThan
  , toInt
  ) where

data N = Z | S N
  deriving (Eq, Show)

two :: N
two = S (S Z)            -- built: from the base, up to where I want

nats :: [N]
nats = iterate S Z       -- all the naturals: a list that never ends

two' :: N
two' = head . tail . tail $ nats   -- I don't build two: I observe it

isEven :: N -> Bool
isEven Z         = True
isEven (S Z)     = False
isEven (S (S n)) = isEven n

evens, evens' :: [N]
evens  = iterate (S . S) Z    -- generate exactly what I want
evens' = filter isEven nats   -- start from everything, keep what's useful

-- | Because of laziness, N isn't purely inductive: this is a valid value.
infinity :: N
infinity = S infinity

-- | Lazy enough to compare anything finite with 'infinity'.
lessThan :: N -> N -> Bool
lessThan _     Z     = False
lessThan Z     (S _) = True
lessThan (S m) (S n) = lessThan m n

toInt :: N -> Int
toInt Z     = 0
toInt (S n) = 1 + toInt n
