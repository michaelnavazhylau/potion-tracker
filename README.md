# Potion Puzzle

A Godot 4 liquid-sorting puzzle with animated fluid levels, constrained pours,
selection feedback, and corks that seal completed single-color potions.

[![Potion Puzzle completed solution demo](demos/potion_solution.gif)](demos/potion_solution.mp4)

The demo above automatically plays through a valid solution. Select a filled
potion, then select a destination. A pour is allowed only when the destination
is empty or its top color matches the source's top color. Consecutive matching
layers move together, subject to the destination's remaining capacity.

## Run the game

1. Open `project.godot` in Godot 4.7 or later.
2. Run the project with <kbd>F5</kbd>.
3. Click or tap one potion to select it, then choose a valid destination.

When a potion becomes full with a single color, a cork drops behind the bottle
rim and seals it. Solve the puzzle by separating every color into its own full,
corked potion.

## Re-record the demo

The deterministic solution driver is in `demos/solution_demo.gd`. Godot's movie
writer can use it to reproduce the full playthrough:

```sh
godot --path . --write-movie demos/potion_solution.avi \
  --fixed-fps 30 --script demos/solution_demo.gd
```
