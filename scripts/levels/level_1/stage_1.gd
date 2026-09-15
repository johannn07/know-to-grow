extends StageScreen

## Level 1 Stage 1 — Dig the Hole.
##
## Everything this stage shows is set in stage_1.tscn: the garden and the garden
## it becomes, the header, the speech bubble, the tool tray, the three item cards
## and both feedback cards. Move them, swap the art, retune the layout — none of
## it needs code.
##
## One thing the scene cannot check for you: **the cards must stay in the same
## order as the items drawn in the tray**, because each card is anchored over the
## slot beneath it. Reorder the cards and they will cover the wrong labels.
##
## The drag, the feedback card and the 160 px hotspot are handled by
## [StageScreen]. Put anything this stage does differently here; `on_correct` and
## `on_wrong` are there to be overridden.
