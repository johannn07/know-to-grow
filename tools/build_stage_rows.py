"""Builds the eight stage select rows from the art already in the repo.

    python tools/build_stage_rows.py      (run from the project root)

Four stages, locked and unlocked. Only four of the eight were ever drawn: the
card has Stage 1 on a green plate and Stages 2-4 on grey, so the other four --
Stage 1 locked, Stages 2-4 unlocked -- are made here rather than drawn.

**These are composited, not illustrated.** Each one is the row cut out of
ui_stage_select_l1.png with its plate and its "Stage N" label recoloured into
the other state, then the right item icon and clean empty stars laid on top.
The recolour matches luminance rank to rank against the opposite row's palette,
so the shading and the leaf pattern survive and only the hue moves. Plate and
label are matched separately, or the label loses its contrast against the plate.

The delivered loose parts could not do this job: their label pill is ratio 5.17
against the 3.12 drawn in the card, and no row plate was delivered at all.

Re-run this if ui_stage_select_l1.png is ever re-exported. If the rows are ever
drawn properly, delete it and drop the eight files in by hand.

Needs pillow, numpy and scipy, which nothing else here does.
"""
from PIL import Image
import numpy as np, os
from scipy import ndimage

card = Image.open("assets/art/ui/stage_select/ui_stage_select_l1.png").convert("RGBA")
ROWS  = {1:(192,560,1430,987), 2:(187,1005,1429,1418), 3:(183,1450,1445,1867), 4:(187,1884,1432,2309)}
DISC  = {1:(89,50,453,399), 2:(92,45,456,396), 3:(92,46,465,399), 4:(92,44,459,399)}
STARS = {1:[(598,230,751,375),(765,230,918,375),(941,230,1094,375)],
         2:[(603,226,744,362),(776,226,917,362),(949,227,1089,362)],
         3:[(613,231,756,371),(789,233,932,372),(964,234,1107,373)],
         4:[(607,226,749,363),(781,226,923,363),(953,228,1095,365)]}
ICON = {1:"shovel", 2:"seed", 3:"water", 4:"sun"}
LUM = np.array([0.299, 0.587, 0.114])

def arr(n): return np.array(card.crop(ROWS[n])).astype(float)

def pill_mask(n):
    """The row's own capsule, separated from the card's beige and its leaves."""
    a = arr(n); r, g, b = a[...,0], a[...,1], a[...,2]
    beige = (r > 228) & (g > 220) & (b > 195)
    solid = ndimage.binary_closing(~beige, np.ones((9,9), bool))
    # The card's vines cross the row and touch the capsule. Opening severs those
    # thin joins so the capsule is picked out on its own, then the edge is
    # restored by dilating the winner back against the original.
    core = ndimage.binary_opening(solid, np.ones((21,21), bool))
    lab, cnt = ndimage.label(core)
    if cnt == 0: return solid
    sizes = ndimage.sum(core, lab, range(1, cnt+1))
    core = (lab == int(np.argmax(sizes)) + 1)
    m = ndimage.binary_dilation(core, np.ones((21,21), bool)) & solid
    return ndimage.binary_fill_holes(m)

def label_mask(n, pill):
    """The 'Stage N' capsule: the darker patch in the pill's upper right."""
    a = arr(n); H, W = a.shape[:2]
    lum = a[..., :3] @ LUM
    band = np.zeros((H, W), bool); band[:int(H*0.52), int(W*0.38):] = True
    region = pill & band
    if region.sum() == 0: return np.zeros((H,W), bool)
    m = region & (lum < np.median(lum[region]) - 6)
    m = ndimage.binary_closing(m, np.ones((13,13), bool))
    lab, cnt = ndimage.label(m)
    if cnt == 0: return m
    sizes = ndimage.sum(m, lab, range(1, cnt+1))
    m = (lab == int(np.argmax(sizes)) + 1)
    return ndimage.binary_fill_holes(m)

def content_mask(n, shape):
    """Icon and stars get replaced, so they never feed or receive a palette."""
    H, W = shape; m = np.zeros((H, W), bool)
    x0,y0,x1,y1 = DISC[n]; m[y0:y1, x0:x1] = True
    for sx0,sy0,sx1,sy1 in STARS[n]: m[sy0:sy1, sx0:sx1] = True
    return m

def palettes(n):
    a = arr(n); pill = pill_mask(n); lab = label_mask(n, pill)
    skip = content_mask(n, a.shape[:2])
    plate = pill & ~lab & ~skip
    out = []
    for m in (plate, lab & ~skip):
        rgb = a[..., :3][m]
        out.append(rgb[np.argsort(rgb @ LUM)])
    return out   # plate palette, label palette

def match(rgb, target):
    if len(rgb) == 0 or len(target) == 0: return rgb
    order = np.argsort(rgb @ LUM)
    rank = np.empty(len(order), int); rank[order] = np.arange(len(order))
    idx = (rank / max(len(order)-1, 1) * (len(target)-1)).round().astype(int)
    return target[idx]

def build(n, locked, plate_pal, label_pal):
    a = arr(n); H, W = a.shape[:2]
    pill = pill_mask(n); lab = label_mask(n, pill)
    skip = content_mask(n, a.shape[:2])
    out = a.copy()
    if plate_pal is not None:
        # Recolour under the icon and stars too. They are excluded when a palette
        # is *sampled*, so they cannot skew it, but leaving them out of the
        # recolour stamps the old colour into a rectangle that shows around the
        # art pasted on top.
        for m, pal in ((pill & ~lab, plate_pal), (lab, label_pal)):
            out[..., :3][m] = match(a[..., :3][m], pal)
    # Only the capsule is the asset; the card's beige and leaves stay behind it.
    out[..., 3] = np.where(pill, 255.0, 0.0)
    im = Image.fromarray(out.clip(0,255).astype(np.uint8), "RGBA")
    icon = Image.open("assets/art/ui/stage_select/source/icon_stage_%s%s.png" % (ICON[n], "_locked" if locked else "")).convert("RGBA")
    x0,y0,x1,y1 = DISC[n]
    im.alpha_composite(icon.resize((x1-x0, y1-y0), Image.LANCZOS), (x0, y0))
    star = Image.open("assets/art/ui/stage_select/icon_star_empty.png").convert("RGBA")
    for sx0,sy0,sx1,sy1 in STARS[n]:
        im.alpha_composite(star.resize((sx1-sx0, sy1-sy0), Image.LANCZOS), (sx0, sy0))
    return im

green_plate, green_label = palettes(1)
grey_plate,  grey_label  = palettes(2)
print(f"palette sizes  green plate {len(green_plate)}, green label {len(green_label)}, "
      f"grey plate {len(grey_plate)}, grey label {len(grey_label)}")
for n in (1,2,3,4):
    for locked in (False, True):
        drawn_locked = (n != 1)
        if locked == drawn_locked:
            im, how = build(n, locked, None, None), "as drawn"
        else:
            pal = (grey_plate, grey_label) if locked else (green_plate, green_label)
            im, how = build(n, locked, *pal), "recoloured"
        name = f"assets/art/ui/stage_select/ui_stage_row_{n}{'_locked' if locked else ''}.png"
        im.save(name, "PNG", optimize=True)
        print(f"  {os.path.basename(name):28s} {im.size[0]:4d}x{im.size[1]:<4d} "
              f"{os.path.getsize(name)//1024:4d} KB  {how}")
