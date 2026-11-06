; Vector-06C Boot Code for Basket Master
; Loads at 0100, jumps to adapter init
; Target: CPC-style four-pen build with native two-plane video

        org     0x0100
        
        di
        ld      sp,0x7F00       ; stack at 7F00 (below soft VRAM at 8000)
        jp      ADAPTER_INIT    ; jump to adapter initialization

; Entry point address - adapter init is at 0200
ADAPTER_INIT    equ     0x0200
