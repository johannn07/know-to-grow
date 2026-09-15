extends StageScreen

## Level 1 Stage 4 — Give Sunlight. The last stage of the level.
##
## Everything this stage shows is set in stage_4.tscn: the garden and the garden
## it becomes, the header, the speech bubble, the tool tray, the three item cards
## and both feedback cards. Move them, swap the art, retune the layout — none of
## it needs code.
##
## One thing the scene cannot check for you: **the cards must stay in the same
## order as the items drawn in the tray**, because each card is anchored over the
## slot beneath it. Reorder the cards and they will cover the wrong labels.
##
## Two things are different here. The Correct card is borrowed from Level 2 —
## the Figma file has no "Correct Answer! / Sun" in the Level 1 frame — and
## Level 2's cards carry no Continue button, so `correct_button_rect` is set to
## the whole card and the child taps anywhere on it. And there is no next stage:
## finishing this one leaves for `done_scene_path`, which is the hub until the
## Level 1 completion screen is built.
##
## The drag, the feedback card and the 160 px hotspot are handled by
## [StageScreen]. Put anything this stage does differently here; `on_correct` and
## `on_wrong` are there to be overridden.
