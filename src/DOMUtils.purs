module DOMUtils where

import Prelude (Unit)
import DOM (DOM)
import Control.Monad.Eff (Eff)

-- | Execute the given function as soon as the document is ready.
foreign import ready :: forall eff f.
                        Eff (dom :: DOM | eff) f ->
                        Eff (dom :: DOM | eff) Unit
