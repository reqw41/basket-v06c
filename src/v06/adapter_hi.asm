; Adapter unit in the space freed by the sprite mirror references
; (ADAPTER_HI, after MIR_REV). Its entries are labels (cfg/labels.json,
; tools/link_labels.py); the unit flows and nothing in it is pinned.
        include "labels_adapter_hi.inc"
        include "cells.inc"
        org     ADAPTER_HI
        include "color_sprite.asm"
        include "joy_p.asm"
        include "aligned_sprite_row.asm"
        include "clipped_player_object.asm"
        include "damage_publish.asm"
        include "ring.asm"
ADAPTER_HI_END:
