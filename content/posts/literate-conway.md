---
title: "Literate Conway"
date: 2016-06-12T18:27:34-04:00
draft: false
tags:
- haskell
- game of life
- literate programming
---

About a month ago, I sat down to write a Haskell implementation of
[Conway's Game of Life](https://en.wikipedia.org/wiki/Conway's_Game_of_Life).

Taking a literate programming approach, let's walk through my solution.

First things first, let's make a Cell type:

```haskell
type Cell = Bool
```

This is nothing more than a simple type alias. The Bool type is a natural way
to represent the cell, with live cells being True and dead cells being False.
However, this definition allows us to define functions which operate on Cells
rather than Bools, which will make the rest of the program much clearer in its
intentions.

Next, we will need a function to handle the state transition of a single cell,
given its neighbors. In Haskell types, we want:

```haskell
next :: Cell -> [Cell] -> Cell
```

That is, `next` is a function which takes a Cell and a list of its neighbors
and returns what the Cell should be in the next state of the world.

The rules[^1] say:

> At each step in time, the following transitions occur:
> 1. Any live cell with fewer than two live neighbours dies, as if caused by
> under-population.
> 1. Any live cell with two or three live neighbours lives on to the next
> generation.
> 1. Any live cell with more than three live neighbours dies, as if by
> over-population.
> 1. Any dead cell with exactly three live neighbours becomes a live cell,
> as if by reproduction.

Since we have completely orthogonal rules for how live cells and dead cells
transition, we can write two definitions for the `next` function. First, we
will write the simpler case &mdash; the definition for the dead cell.

```haskell
next False neighbors
    | liveCount neighbors == 3 = True
    | otherwise                = False
```

This is almost verbatim from the fourth bullet point from Wikipedia, so let's
move on to the definition of `liveCount`, which should return the number of
Cells that are alive in a list. Since Cell is just an alias for Bool, we can
filter out all of the dead cells by using `filter` in conjuction with `id`. So,
to get the sublist of cells that are alive, we simply:

```haskell
liveCells :: [Cell] -> [Cell]
liveCells cells = filter id cells
```

Notice that the single argument to liveCells appears only as the last variable
in the function definition. We can take advantage of Haskell's currying, by
modifying our function like so:

```haskell
liveCells :: ([Cell] -> [Cell]) -- parentheses are mandatory here!
liveCells = filter id
```

This is called Point-Free Style (PFS). It is point-free because we have written
the function without referring to its argument, or its "point."

Now that we have defined `liveCells`, all `liveCount` needs to do is return the
length of the list returned by `liveCells`. In code:

```haskell
liveCount cells = count $ liveCells cells
```

To simplify this a little, I'm going to remove the `liveCells` function
entirely and just use its body. Therefore:

```haskell
liveCount cells = count $ filter id cells
```

Now, with one small tweak, we can write `liveCount` in PFS as well. We will use
the function composition operator (in Haskell, this is a ".") like so:

```haskell
liveCount :: ([Cell] -> Int)
liveCount = count . filter id
```

This is what function composition looks like in Haskell. If this is new to you,
let me provide an example, in pseudo-Haskell:

```haskell
h = f . g
h(x) == f(g(x))
```

After that lengthy digression, let's now define the `next` function for live
cells. There are three rules, so we will need a few more guard clauses than
before:

```haskell
next False neighbors
    | liveCount neighbors < 2                              = False
    | liveCount neighbors == 2 || liveCount neighbors == 3 = True
    | otherwise                                            = False
```

The final rule collapses into the default guard clause, so it does not
explicitly appear in the definition. For the sake of clarity, we will assume
that the Haskell compiler is smart enough to optimize away the repeated
computations of the live neighbor count.

Now that we have finished handling the transition of a single cell, we need to
transition the entire world.

Before we can do that, though, we need to be able to represent the world, which
in our case is a two dimensional array. Now, we _could_ represent this using
vanilla nested lists (`[[Cell]]`). However, this will likely make the code much
more confusing, and also possibly slower, since we will have to traverse the
same lists over and over. Instead, we will use a package from the Hackage
repositories. You can install it with [cabal](https://www.haskell.org/cabal/).
Simply `cabal install matrix`. Now we can represent the world as a Matrix,
which we can access by row and column.

We need a function that does a step of the entire world in one fell swoop. We
are going to define our function to be:

```haskell
import Data.Matrix
step :: Matrix Cell -> Matrix Cell
```

The first thing we need to be able to do is get a list of a cell's neighbors,
given its position in the world (or The Matrix, if your name is Neo).

First, let's define a function that returns a list of coordinates (tuples) of
all neighboring positions (including the origin position, for simplicity of
expression):

```haskell
allNeighborCoordinates :: Int -> Int -> [(Int, Int)]
allNeighborCoordinates row col = [(row + r, col + c) | r <- [-1..1], c <- [-1..1]]
```

This will return all the adjacent coordinates, including ones that may not even
be in the world! For example, `allNeighborCoordinates 0 0` will include the
coordinate (-1, -1). We need to filter these out, along with the origin
coordinate that will be in the list as well.

Let's define a function that will determine if a coordinate is valid as a
neighbor:

```haskell
validNeighborCoordinate :: Int -> Int -> Int -> Int -> (Int, Int) -> Bool
validNeighborCoordinate r0 c0 rmax cmax (x, y)
    | x == r0 && y == c0 = False -- rule out the origin point
    | x < 1 || x > rmax  = False -- check that the x-coordinate is in range
    | y < 1 || y > cmax  = False -- check that the y-coordinate is in range
    | otherwise          = True
```

The order of arguments is actually important here, for a reason we will see in
just a moment. Now we can define the `neighborsOf` function:

```haskell
-- getElem is defined in the Data.Matrix module
neighborsOf :: Int -> Int -> Int -> Int -> Matrix Cell -> [Cell]
neighborsOf r0 c0 rmax cmax world =
    map (\(x, y) -> getElem x y world) $
        filter (validNeighborCoordinate r0 c0 rmax cmax) $
        allNeighborCoordinates r0 c0
```

Notice how having the coordinate tuple as the last argument to
`validNeighborCoordinate` allows us to more easily use it with `filter`, rather
than having to define an inline lambda. This has no real advantage as far as I
know, though, other than I like it better and think it looks prettier.

We have done enough set up work that we can define the `step` function. I want
to call attention to the `mapRow` function defined in the `Data.Matrix` module
as so:

```haskell
mapRow :: (Int -> a -> a) -- function takes the current column as an additional argument
       -> Int             -- row index to map
       -> Matrix a
       -> Matrix a
```

This function transforms a single row in the matrix and returns the entire
matrix but with that row changed. So, we can move one row at a time, folding on
the intermediate matrices as we go. The only trick is that we want all of the
neighbor computations to be based on the original matrix, not any of the
intermediate states.

```haskell
step :: Matrix Cell -> Matrix Cell -- as a reminder
step world =
    foldl
        (\(intermediate row) ->
            mapRow (\(col cell) ->
                next cell (neighborsOf row col)) row intermediate)
        world
        [1..rmax]
    where rmax = nrows world
          cmax = ncols world
          -- below we bring in the functions we defined earlier, but we can
          -- take advantage of the fact that rmax/cmax are in scope, so we no
          -- longer need to take them as arguments.

          allNeighborCoordinates row col = [(row + r, col + c) | r <- [-1..1], c <- [-1..1]]

          -- also note that these functions operate on the original 'world'
          -- argument, so the neighbor counts are consistent.

          neighborsOf row col =
            map (\(x, y) -> getElem x y world) $
                filter (validNeighborCoordinate r c) $
                allNeighborCoords r c
          validNeighborCoordinate r0 c0 (x, y)
            | x == r0 && y == c0 = False
            | x < 1 || x > rmax  = False
            | y < 1 || y > cmax  = False
            | otherwise          = True

```

With that, we have a complete implementation of Conway's Game of Life.

There is a complete version [on my GitHub](https://github.com/ajm188/conway).
There is some minor renaming in an effort to keep some of the lines shorter,
but beyond that the code is the same. It also includes some code to handle
displaying the world on each iteration, which you will probably be interested
in at some point.

Thanks for following along! Drop me a line if you have any questions or
feedback.

[^1]: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life#Rules
