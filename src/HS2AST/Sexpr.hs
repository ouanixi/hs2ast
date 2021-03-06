{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances  #-}
{-# LANGUAGE RankNTypes         #-}

module HS2AST.Sexpr where

import           CoAxiom                     as C
import qualified Data.AttoLisp               as L
import           Data.ByteString             (ByteString)
import           Data.ByteString.Char8       (unpack)
import           Data.Data
import           Data.Generics
import           Data.Generics.Uniplate.Data
import           Data.Maybe
import qualified Data.Stringable             as S
import           DataCon
import           HS2AST.Types
import           HsBinds
import           Literal
import           Module
import           Name
import           SrcLoc
import           TyCon                       as T
import           TypeRep
import           Unique
import           Var


mkLeaf :: String -> L.Lisp
mkLeaf x = L.String (S.fromString x)

mkNode :: [L.Lisp] -> L.Lisp
mkNode xs = L.List xs



convertBinding :: HsBindLR Name Name -> Maybe L.Lisp
convertBinding = simpleAst

-- | Convert Data instances to s-expressions
toSexp :: Data a => a -> Maybe L.Lisp
toSexp x = let tail = gmapQ toSexp  x
               head = toSx  x
               in  case head of
                    Nothing -> Nothing
                    Just y  -> Just (mkNode (y : catMaybes tail))

toSx :: Data a =>  a -> Maybe L.Lisp
toSx x = let l = strConstr x
         in  Just l

simpleAst :: Data a => a -> Maybe L.Lisp
simpleAst = toSexp

strConstr :: Data a => a -> L.Lisp
strConstr = extQ (extQ (extQ (extQ (mkLeaf . show . toConstr)
            showBS) showVar) showDataCon) showTycon



showTycon :: T.TyCon -> L.Lisp
showTycon t = let name = T.tyConName t
                  mdpkg = getModPkg (nameModule_maybe name)
              in case mdpkg of
                Just(m, p)   -> mkNode [mkLeaf "TyCon" ,mkNode[mkNode [mkLeaf "name", mkLeaf $ show name], mkNode [mkLeaf "mod", mkLeaf m]
                              , mkNode[mkLeaf "pkg", mkLeaf p]]]
                Nothing      -> mkNode [mkLeaf "TyCon" ,mkNode [mkLeaf "name", mkLeaf $ show name]]



showDataCon :: DataCon -> L.Lisp
showDataCon d = let name = getName d
                    mdpkg = getModPkg (nameModule_maybe name)
                in case mdpkg of
                    Just(m, p)   -> mkNode [mkLeaf "DataCon" ,mkNode[mkNode [mkLeaf "name", mkLeaf $ show name], mkNode [mkLeaf "mod", mkLeaf m]
                                  , mkNode[mkLeaf "pkg", mkLeaf p]]]
                    Nothing      -> mkNode [mkLeaf "DataCon" ,mkNode [mkLeaf "name", mkLeaf $ show name]]



showVar :: Var -> L.Lisp
showVar v = let name = getName v
                mdpkg = getModPkg (nameModule_maybe name)
            in case mdpkg of
                Just(m, p)   -> mkNode [mkLeaf "Var" ,mkNode[mkNode [mkLeaf "name", mkLeaf $ show name], mkNode [mkLeaf "mod", mkLeaf m]
                              , mkNode[mkLeaf "pkg", mkLeaf p]]]
                Nothing      -> mkNode [mkLeaf "Var" ,mkNode [mkLeaf "name", mkLeaf $ show name]]



getModPkg :: Maybe Module -> Maybe (String, String)
getModPkg Nothing = Nothing
getModPkg (Just m) = Just (moduleNameString (moduleName m), packageKeyString  (modulePackageKey m))

showBS :: ByteString -> L.Lisp
showBS bs = mkNode (mkLeaf "BS" : mkLeaf (unpack bs) : [])
