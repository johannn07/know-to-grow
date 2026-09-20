extends StageScreen

## Level 3 Stage 2 — the glowing stem.
##
## The stem is lit from the soil up to the growing tip, so it runs down the
## middle of the screen through most of its height. **The bubble goes high**, at
## y 420, where it sits just above the top of the glow.
##
## Its background is the one odd size in the set, 1024 x 1536 against the other
## four's ~852 x 1846. Drawn `KEEP_COVERED` it loses about 840 px off the sides
## rather than off the top and bottom. The stem is centred, so it survives — but
## this is the one to look at first if a new phone ever makes Level 3 look wrong.
##
## Built to Stage 1's numbers — header at 760 px, tap plank at 1478, three
## cards at y 1610 — and it changes only what is written above. See
## `scripts/levels/level_3/stage_1.gd` for how a Level 3 stage works.
