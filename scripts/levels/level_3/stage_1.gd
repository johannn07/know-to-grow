extends StageScreen

## Level 3 Stage 1 — the glowing leaves.
##
## The pattern the other four stages copy. Level 3 asks a child to *name* a part
## rather than fix something, so the question is in the artwork: the background
## draws the whole plant with one part in colour and glowing and everything else
## greyed out. The riddle in the bubble is the clue, and the three cards are the
## answer.
##
## It is the first stage with **no tray and no drop zone**. [member
## StageScreen.tap_to_answer] is on, so a card is chosen where it stands. The
## cards sit loose on the garden, which means they always draw themselves, are
## dealt in a new order every play, and a wrong one is darkened where it is
## rather than leaving an empty slot behind — see [OptionCard].
##
## The header is Level 3's own sign, `header_sign_l3.tscn`, which needs 760 px;
## the prompt is the shared blank bubble. Both are filled from
## content/level_3_identifying.tres through [member StageScreen.level_content].
## Level 3 has no fun fact, by decision.
##
## **Where the bubble sits is this stage's own decision.** The glowing part is
## drawn into each background at a different height, and a full-width bubble
## across it would hide the answer. Here the leaves are high, so the bubble is
## low, over the soil beside the sprout. Stages 2 and 3 highlight the stem and
## the roots, which sit lower, so theirs goes at the top instead. Nothing else
## in the layout moves between the five.
##
## Level 3's Correct cards have no Continue drawn on them, as Level 2's do not,
## so the Continue sits below the card and bounces. The Oops card is Level 1's,
## reused wording and all.
