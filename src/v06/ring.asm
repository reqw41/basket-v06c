; Replay ring of the port: 14 records of 79 bytes (the 93EB game state) at
; 1B8F..1FE0, written in a circle. The MSX writer (A969) shifted the whole
; ring down a record every iteration once it was full (an LDIR of 1106
; bytes, ~45k cycles on the i8080) and playback (A991) read 14 records from
; 1B8F. Here the writer wraps; playback starts at the oldest record (the
; next to overwrite) once the ring has wrapped, else at 1B8F as the MSX,
; and reads 14 records in a circle. The ring is port memory (not compared
; with the MSX; 93D4 is in the msx_lockstep IGNORE list).
RING_FIRST      equ     0x1B8F
RING_END        equ     0x1FE1
RING_REC        equ     0x4F            ; RING_PTR, RING_STATE, RING_END_FLAG: cfg/labels.json

; A96E (after `ld a,(9400) / and a / ret nz`): record the state.
RING_PUSH:
        ld      hl,(RING_PTR)
        ex      de,hl
        ld      hl,RING_STATE
        ld      bc,RING_REC
        call    MEM_COPY
        ex      de,hl
        call    ring_wrap
        jp      nz,rp_store
        ld      a,1
        ld      (RING_WRAPPED),a
rp_store:
        ld      (RING_PTR),hl
        ret

; HL past a record: Z and HL = RING_FIRST at the end of the ring.
ring_wrap:
        ld      a,l
        cp      RING_END & 255
        ret     nz
        ld      a,h
        cp      RING_END >> 8
        ret     nz
        ld      hl,RING_FIRST
        ret

; A962 (a recording starts): `ld hl,1B8F / ld (93D4),hl / ret`.
RING_RESET:
        xor     a
        ld      (RING_WRAPPED),a
        ld      hl,RING_FIRST
        ld      (RING_PTR),hl
        ret

; A859 (playback starts; was `ld hl,1B8F / ld (93D4),hl`).
RING_REPLAY:
        ld      a,14
        ld      (RING_LEFT),a
        ld      a,(RING_WRAPPED)
        or      a
        ret     nz                      ; 93D4 = the oldest record
        ld      hl,RING_FIRST
        ld      (RING_PTR),hl
        ret

; A991: the next record into 93EB; 93D3 = 1 after the 14th.
RING_PULL:
        ld      hl,(RING_PTR)
        ld      de,RING_STATE
        ld      bc,RING_REC
        call    MEM_COPY
        call    ring_wrap
        ld      (RING_PTR),hl
        ld      hl,RING_LEFT
        dec     (hl)
        ret     nz
        ld      a,1
        ld      (RING_END_FLAG),a
        ret
