module Lib where

import Data.List (group, groupBy, sortBy)
import Data.Maybe (catMaybes)
import Control.Applicative ((<$>))

-- Suits don't have an `Ord` instance, as there's no notion of Suit order
data Suit =
      Hearts
    | Clubs
    | Diamonds
    | Spades
    deriving (Eq, Show)

data Rank =
      One
    | Two
    | Three
    | Four
    | Five
    | Six
    | Seven
    | Eight
    | Nine
    | Ten
    | Jack
    | Queen
    | King
    | Ace
    deriving (Eq, Bounded, Enum, Ord, Show)

data Card =
    Card Rank Suit
    deriving (Eq, Show)

-- Card ordering doesn't take into account Suits, so we need to provide
-- a custom `Ord` instance
instance Ord Card where
    compare (Card r _) (Card r' _) = compare r r'

-- Sadly we can't specify the size of the hand.  This isn't Idris... :-(
type Hand = [Card]

-- Various type aliases to make the use of `Rank` in `BestHand` clearer
type HighRank = Rank
type LowRank = Rank
type ThreeRank = Rank
type TwoRank = Rank

-- A 'Best Hand' consists of the best available cards and possibly one or more
-- 'Kickers' (the remaining cards that decide in the event of a 'best cards'
-- tie).  The assumptions we make about the `BestCards` and `Kickers` types
-- allow us to use the default derived `Ord` instance to detect winning hands.
data BestHand =
    HighCard Rank Kickers
  | OnePair Rank Kickers
  | TwoPairs HighRank LowRank Kickers
  | ThreeOfAKind Rank Kickers
  | Straight Rank
    -- TODO - Consider how we compare two flushes
  | Flush
  | FullHouse ThreeRank TwoRank
  | FourOfAKind Rank Kickers
  | StraightFlush Rank
  | RoyalFlush
  deriving (Eq, Ord, Show)

type Kickers = [Rank]


-- Takes a hand of 5 cards and creates the best hand from it
bestHand :: Hand -> BestHand
bestHand = maximum . possibleHands
    where possibleHands h = catMaybes $ handMatchers <*> [h]

-- A list of 'hand matchers' - functions that can be used to 'match' hands.  By
-- applying this list of functions to a hand, we'll get a list of `Maybe
-- BestHand`, where each list entry is either `Nothing` if the hand doesn't
-- match, or a `Just` with the type of matching hand.
handMatchers :: [Hand -> Maybe BestHand]
handMatchers = [highCardMatcher,
                onePairMatcher,
                twoPairsMatcher,
                threeOfAKindMatcher,
                straightMatcher,
                flushMatcher,
                fullHouseMatcher,
                fourOfAKindMatcher,
                straightFlushMatcher,
                royalFlushMatcher]

sameSuit :: Card -> Card -> Bool
sameSuit (Card _ s) (Card _ s') = s == s'

sameRank :: Card -> Card -> Bool
sameRank (Card r _) (Card r' _ ) = r == r'

rank :: Card -> Rank
rank (Card r _) = r


-- Given a Hand, extracts the Ranks of the Cards in the Hand, in decreasing order
sortedRanks :: Hand -> [Rank]
sortedRanks h = rank <$> sortBy (flip compare) h



-- Hand Matchers for the various possible BestHands

highCardMatcher :: Hand -> Maybe BestHand
highCardMatcher h = Just $ HighCard (head $ sortedRanks h) (tail $ sortedRanks h)

onePairMatcher :: Hand -> Maybe BestHand
-- TODO: Complete implementation
onePairMatcher h = Nothing

twoPairsMatcher :: Hand -> Maybe BestHand
-- TODO: Complete implementation
twoPairsMatcher h = Nothing

threeOfAKindMatcher :: Hand -> Maybe BestHand
-- TODO: Complete implementation
threeOfAKindMatcher h = Nothing

straightMatcher :: Hand -> Maybe BestHand
straightMatcher h
    | allPredecessors (sortedRanks h) = Just $ Straight (head (sortedRanks h))
    | otherwise = Nothing

flushMatcher :: Hand -> Maybe BestHand
flushMatcher h
    | length (groupBy sameSuit h) == 1 = Just Flush
    | otherwise = Nothing

fullHouseMatcher :: Hand -> Maybe BestHand
fullHouseMatcher h = do
    ThreeOfAKind t _ <- threeOfAKindMatcher h
    OnePair p _ <- onePairMatcher h
    return $ FullHouse t p

fourOfAKindMatcher :: Hand -> Maybe BestHand
-- TODO: Complete implementation
fourOfAKindMatcher h = Nothing

straightFlushMatcher :: Hand -> Maybe BestHand
straightFlushMatcher h = do
    _ <- flushMatcher h
    Straight r <- straightMatcher h
    return $ StraightFlush r

royalFlushMatcher :: Hand -> Maybe BestHand
royalFlushMatcher h = do
    StraightFlush r <- straightFlushMatcher h
    if r == Ace then Just RoyalFlush
                else Nothing


-- Predicate that tests whether each entry in a list is the immediate predecessor
-- of the previous entry in the list.
allPredecessors :: (Bounded a, Eq a, Enum a) => [a] -> Bool
allPredecessors []  = True
allPredecessors [x] = True
allPredecessors (x:y:ys)
    | x == minBound = False
    | otherwise = (y == pred x) && allPredecessors (y:ys)