module Test.Main where

import AST
import Parser

import Prelude
import Data.Either
import Data.List

import Text.Parsing.StringParser

import Control.Monad.Eff
import Control.Monad.Eff.Console

test :: forall a eff. (Show a, Eq a) => String -> Parser a -> String -> a -> Eff (console :: CONSOLE | eff ) Unit
test name p input expected = case runParser p input of
  Left  (ParseError err) -> print $ "Fail (" ++ name ++ "): " ++ err
  Right result           -> 
    if result == expected
      then print $ "Success (" ++ name ++ ")"
      else print $ "Fail (" ++ name ++ "): " ++ show result ++ " /= " ++ show expected

aint :: Int -> Expr
aint i = Atom $ AInt i

aname :: String -> Expr
aname s = Atom $ Name s

main :: forall eff. Eff (console :: CONSOLE | eff) Unit
main = do
  test "0" int "0" (AInt 0)
  test "1" int "1" (AInt 1)
  test "all" int "0123456789" (AInt 123456789)
  test "high" int "999999999999999999" (AInt 2147483647)

  test "a" variable "a" (Name "a")
  test "lower" variable "a_bcdefghijklmnopqrstuvwxyz_" (Name "a_bcdefghijklmnopqrstuvwxyz_")
  test "upper" variable "a'BCDEFGHIJKLMNOPQRSTUVWXYZ'" (Name "a'BCDEFGHIJKLMNOPQRSTUVWXYZ'")
  test "special" variable "_____''''" (Name "_____''''")

  test "1" expression "1" (Atom (AInt 1))
  test "add" expression "1 + 2" (Binary Add (Atom (AInt 1)) (Atom (AInt 2)))
  test "precedence" expression "1 * 2 + 3 * 4" (Binary Add 
                                    (Binary Mul (Atom (AInt 1)) (Atom (AInt 2)))
                                    (Binary Mul (Atom (AInt 3)) (Atom (AInt 4))))
  test "whitespaces" expression 
    "1   \n   -    \t   ( f   )    \t\t\t\t                     \n\n\n             `div`     _ignore"
    (Binary Sub (Atom (AInt 1)) (Binary Div (Atom (Name "f")) (Atom (Name "_ignore"))))
  test "brackets" expression "(  1  +  2  )  *  3" (Binary Mul (Binary Add (aint 1) (aint 2)) (aint 3))
  test "brackets2" expression "( (  1  +  2  - 3  )  *  4 * 5 * 6)"
    (Binary Mul 
      (Binary Mul
        (Binary Mul
          (Binary Sub 
            (Binary Add (aint 1) (aint 2))
            (aint 3))
          (aint 4))
        (aint 5))
      (aint 6))
  test "many brackets" expression "(   (( ((  f )) *  ( (17   )) ) ))" (Binary Mul (Atom (Name "f")) (aint 17))

  test "if_then_else" expression "if x then y else z" (IfExpr (aname "x") (aname "y") (aname "z"))
  test "nested if" expression "if(if 1 then 2 else 3)then y else z" (IfExpr (IfExpr (aint 1) (aint 2) (aint 3)) (aname "y") (aname "z"))
  test "iffy1" expression "iffy" (aname "iffy")
  test "iffy2" expression "if 10 + 20 then iffy * iffy else ((7))"
    (IfExpr 
      (Binary Add (aint 10) (aint 20))
      (Binary Mul (aname "iffy") (aname "iffy"))
      (aint 7))
  test "iffy3" expression "iffy + if iffy then iffy else iffy"
    (Binary Add (aname "iffy") (IfExpr (aname "iffy") (aname "iffy") (aname "iffy")))
  test "nested if 2" expression "if if x then y else z then if a then b else c else if i then j else k"
    (IfExpr
      (IfExpr (aname "x") (aname "y") (aname "z"))
      (IfExpr (aname "a") (aname "b") (aname "c"))
      (IfExpr (aname "i") (aname "j") (aname "k")))

  test "apply1" expression "f 1" (App (aname "f") (singleton (aint 1)))
  test "apply2" expression "f x y z 12 (3 + 7)"
    (App (aname "f") (toList [aname "x", aname "y", aname "z", aint 12, Binary Add (aint 3) (aint 7)]))
  test "fibonacci" expression "fib (n - 1) + fib (n - 2)"
    (Binary Add
      (App (aname "fib") (toList [Binary Sub (aname "n") (aint 1)]))
      (App (aname "fib") (toList [Binary Sub (aname "n") (aint 2)])))
  test "predicate" expression "if p 10 then 10 else 20"
    (IfExpr
      (App (aname "p") (singleton (aint 10)))
      (aint 10)
      (aint 20))
  test "stuff" expression "f a (1 * 2) * 3"
    (Binary Mul
      (App (aname "f") (toList [aname "a", Binary Mul (aint 1) (aint 2)]))
      (aint 3))
