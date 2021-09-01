-----------------------------------------------------------------------------
-- |
-- Module      :  Swarm.Game.Display
-- Copyright   :  Brent Yorgey
-- Maintainer  :  byorgey@gmail.com
--
-- SPDX-License-Identifier: BSD-3-Clause
--
-- Utilities for describing how to display in-game entities in the TUI.
--
-----------------------------------------------------------------------------

{-# LANGUAGE DeriveAnyClass  #-}
{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}
  -- Orphan Hashable instances needed to derive Hashable Display

module Swarm.Game.Display
  (
    -- * The display record
    Priority
  , Display(..)

    -- ** Lenses
  , defaultChar, orientationMap, displayAttr, displayPriority

    -- ** Lookup
  , lookupDisplay

    -- ** Construction
  , defaultEntityDisplay
  , defaultRobotDisplay

  ) where

import           Brick                 (AttrName)
import           Control.Lens          hiding (Const, from)
import           Data.Hashable
import           Data.Map              (Map)
import qualified Data.Map              as M
import           GHC.Generics          (Generic)
import           Linear

import           Swarm.Language.Syntax
import           Swarm.TUI.Attr
import           Swarm.Util

-- | Display priority.  Entities with higher priority will be drawn on
--   top of entities with lower priority.
type Priority = Int

-- | A record explaining how to display an entity in the TUI.
data Display = Display
  { -- | The default character to use for display.
    _defaultChar     :: Char

    -- | For robots or other entities that have an orientation, this map
    --   optionally associates different display characters with
    --   different orientations.  If an orientation is not in the map,
    --   the '_defaultChar' will be used.
  , _orientationMap  :: Map (V2 Int) Char

    -- | The attribute to use for display.
  , _displayAttr     :: AttrName

    -- | This entity's display priority. Higher priorities are drawn
    --   on top of lower.
  , _displayPriority :: Priority
  }
  deriving (Eq, Ord, Show, Generic, Hashable)

-- Some orphan instances we need to be able to derive a Hashable
-- instance for Display
instance (Hashable k, Hashable v) => Hashable (Map k v) where
  hashWithSalt = hashUsing M.assocs
instance Hashable AttrName

makeLenses ''Display

-- | Look up the character that should be used for a display, possibly
--   given an orientation as input.
lookupDisplay :: Maybe (V2 Int) -> Display -> Char
lookupDisplay Nothing disp  = disp ^. defaultChar
lookupDisplay (Just v) disp = M.lookup v (disp ^. orientationMap) ? (disp ^. defaultChar)

-- | Construct a default display for an entity that uses only a single
--   display character, the default entity attribute, and priority 1.
defaultEntityDisplay :: Char -> Display
defaultEntityDisplay c = Display
  { _defaultChar     = c
  , _orientationMap  = M.empty
  , _displayAttr     = entityAttr
  , _displayPriority = 1
  }

-- | Construct a default robot display, with display characters
--   @"■▲▶▼◀"@, the default robot attribute, and priority 10.
defaultRobotDisplay :: Display
defaultRobotDisplay = Display
  { _defaultChar     = '■'
  , _orientationMap  = M.fromList
      [ (east,  '▶')
      , (west,  '◀')
      , (south, '▼')
      , (north, '▲')
      ]
  , _displayAttr     = robotAttr
  , _displayPriority = 10
  }
