extends StageScreen

## Level 4 Stage 1 — what the roots do.
##
## The pattern the other four stages copy. Level 4 asks what a part is *for*,
## so the background names the part the way Level 3's do — the whole plant in
## its pot, with the one part glowing — and the three cards are wide function
## strips rather than part names.
##
## It is tapped like Level 3, with [member StageScreen.tap_to_answer] on and no
## drop zone, but it **keeps its card order**: [member
## StageScreen.keep_card_order] is on. The Correct card names the answer by a
## drawn letter, "Correct Match: B", so the cards stay A, B, C from the top, as
## the art numbers them.
##
## The header is Level 2's sign at 660 px — Level 4's delivered blank is the
## same drawing — reading "Stage 1" / "Roots". The "Tap the correct function
## card." plank sits straight under it rather than above the cards, because
## the three stacked cards need the bottom of the screen to themselves.
##
## **Where the bubble sits is this stage's own decision**, as in Level 3. The
## roots glow inside the pot, low on the screen, so the bubble is high, over
## the leaves; Stages 2-5 highlight parts above the pot and put it low.
## Nothing else in the layout moves between the five.
##
## The Correct card has no Continue drawn on it, so Continue sits below the
## card and bounces. The Oops card is Level 1's, reused wording and all.
