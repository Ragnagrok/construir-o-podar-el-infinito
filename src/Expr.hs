-- | A tiny language of candidate programs. A program is an expression over
-- one variable @x :: Int@; to be a candidate for "is x even?" it has to be
-- a 'Bool'.
module Expr
  ( Expr (..), Type (..)
  , typeOf, typechecks
  , eval
  , size, ofSize, upToSize
  , pretty
  ) where

data Expr
  = X
  | Lit Int
  | Add Expr Expr
  | Mod Expr Expr
  | Equal Expr Expr
  | Less Expr Expr
  | Not Expr
  | And Expr Expr
  | Or Expr Expr
  deriving (Eq, Show)

data Type = TInt | TBool
  deriving (Eq, Show)

-- | The type checker: 'Nothing' means ill-typed (e.g. @not 2@, @x + (x == 1)@).
typeOf :: Expr -> Maybe Type
typeOf X         = Just TInt
typeOf (Lit _)   = Just TInt
typeOf (Add a b) = ints a b TInt
typeOf (Mod a b) = ints a b TInt
typeOf (Equal a b) = ints a b TBool
typeOf (Less a b)  = ints a b TBool
typeOf (Not a)   = if typeOf a == Just TBool then Just TBool else Nothing
typeOf (And a b) = bools a b
typeOf (Or a b)  = bools a b

ints :: Expr -> Expr -> Type -> Maybe Type
ints a b t = if typeOf a == Just TInt && typeOf b == Just TInt then Just t else Nothing

bools :: Expr -> Expr -> Maybe Type
bools a b = if typeOf a == Just TBool && typeOf b == Just TBool then Just TBool else Nothing

-- | Is it a candidate for @Int -> Bool@?
typechecks :: Expr -> Bool
typechecks e = typeOf e == Just TBool

data Value = I Int | B Bool

-- | Only meant for well-typed expressions. @x mod 0@ is taken to be 0, so
-- that every candidate is total.
eval :: Expr -> Int -> Bool
eval e x = case go e of
  B b -> b
  I _ -> error "eval: not a Bool"
  where
    go X = I x
    go (Lit n) = I n
    go (Add a b) = I (int a + int b)
    go (Mod a b) = let d = int b in I (if d == 0 then 0 else int a `mod` d)
    go (Equal a b) = B (int a == int b)
    go (Less a b) = B (int a < int b)
    go (Not a) = B (not (bool a))
    go (And a b) = B (bool a && bool b)
    go (Or a b) = B (bool a || bool b)
    int a = case go a of I n -> n; B _ -> error "eval: ill-typed"
    bool a = case go a of B b -> b; I _ -> error "eval: ill-typed"

size :: Expr -> Int
size X = 1
size (Lit _) = 1
size (Not a) = 1 + size a
size (Add a b) = 1 + size a + size b
size (Mod a b) = 1 + size a + size b
size (Equal a b) = 1 + size a + size b
size (Less a b) = 1 + size a + size b
size (And a b) = 1 + size a + size b
size (Or a b) = 1 + size a + size b

-- | Every expression of exactly this size, well-typed or not.
ofSize :: Int -> [Expr]
ofSize n
  | n <= 0 = []
  | n == 1 = X : map Lit [0 .. 3]
  | otherwise =
      [Not e | e <- ofSize (n - 1)]
        ++ [ op a b
           | op <- [Add, Mod, Equal, Less, And, Or]
           , k <- [1 .. n - 2]
           , a <- ofSize k
           , b <- ofSize (n - 1 - k)
           ]

upToSize :: Int -> [Expr]
upToSize n = concatMap ofSize [1 .. n]

pretty :: Expr -> String
pretty = go (0 :: Int)
  where
    go _ X = "x"
    go _ (Lit n) = show n
    go p (Add a b) = bin p 6 a " + " b
    go p (Mod a b) = bin p 7 a " `mod` " b
    go p (Equal a b) = bin p 4 a " == " b
    go p (Less a b) = bin p 4 a " < " b
    go p (And a b) = bin p 3 a " && " b
    go p (Or a b) = bin p 2 a " || " b
    go p (Not a) = paren (p > 9) ("not " ++ go 10 a)
    bin p q a s b = paren (p > q) (go (q + 1) a ++ s ++ go (q + 1) b)
    paren True s = "(" ++ s ++ ")"
    paren False s = s
