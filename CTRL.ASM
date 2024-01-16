        locals  @@

PrePal  macro    ; DS:SI Ä Pal Area
local   WaitBOff,WaitBOn
        mov     dx,3DAh
        in      al,dx
        test    al,8
        jz      WaitBOn
WaitBOff: in     al,dx
        test    al,8
        jnz     WaitBOff
WaitBOn:
        in      al,dx
        test    al,8
        jz      WaitBOn
        mov     dx,3C8h
        mov     al,0
        out     dx,al
        mov     cx,0FFh*3
        inc     dx
        endm

SetPal  macro
        PrePal
        cld
        .186
        rep     outsb
        .8086
        endm

ClrPal  macro
local   LP
        PrePal
    LP: out    dx,al
        loop   LP
        endm

CODE    segment
        assume  cs:CODE,ds:CODE
        org     100h
START:

%OUT     - Pass begin

 PrgType                equ     90710FEh
 VersionC               equ     00130h

;----------------------------------------------------------------------------
 cmRet                  equ     000C3h
 cmIRet                 equ     000CFh
 cmPushf                equ     0009Ch
 cmMovAlC               equ     000B0h
 cmMovAxC               equ     000B8h
 cmMovCxC               equ     000B9h
 cmMovDxC               equ     000BAh
 cmMovSiC               equ     000BEh
 cmJmpShort             equ     000EBh
 cmMovWCM               equ     006C7h
 cmLongNop              equ     0C086h
 cmCall                 equ     000E8h
 cmMovSP                equ     000BCh

;----------------------------------------------------------------------------

 AskConst               equ     0A05Eh
 AnsConst               equ     03D15h

 fmAdv                  equ     0000000000000001b
 fmHidm                 equ     0000000000000010b

;----------------------------------------------------------------------------

 faArchive              equ     100000b

;----------------------------------------------------------------------------

 StSize                 equ     300h

;----------------------------------------------------------------------------

 AdvSample              equ     offset SetScreen_End-offset SetScreen


;*****************************
;*   Standart RSKI header    *
;*****************************
old88o   equ     100h       ;*
old88s   equ     102h       ;*
         jmp     INSTALL    ;*
         org     104h       ;*
Program  dd      PrgType    ;*
RSKIVer  dw      VersionC   ;*
OldEvent db      (?)        ;*
;*****************************

i10     proc
        pushf
        call    dword ptr cs:old10o
        ret
i10     endp

GRABScreen proc near
        mov     ax,offset WriteScreen
        call    BrutalAction
        ret
GRABScreen endp

IOWork        db      0
Grabbing      db      0

KeyboardHandler proc

@@kfCTRL equ    1
@@kfALT  equ    2

pressed dd      0
BrkEnable db    0

@@KBDFlags db   0
@@GRAB_ASTERISK db 0
Int13Grabbing   db 0


@@Check_CTRL_ALT:
         mov    al,@@KBDFlags
         and    al,@@kfCTRL or @@kfALT
         cmp    al,@@kfCTRL or @@kfALT
         jz     @@CABoth
         inc    sp
         inc    sp
         jmp    @@JustEXIT
@@CABoth:ret

@@Check_CTRL:
         test   @@KBDFlags,@@kfCTRL
         jnz    @@cCTRL
         inc    sp
         inc    sp
         jmp    @@JustEXIT
@@cCTRL: ret


@@KeyTable:
         dw     offset @@UnknownPress        ; 0
         dw     offset @@UnknownRelease
         dw     offset @@kCTRLp              ; 1
         dw     offset @@kCTRLr
         dw     offset @@kALTp               ; 2
         dw     offset @@kALTr
         dw     offset @@kASTERISKp          ; 3
         dw     offset @@kASTERISKr
         dw     offset @@kBp                 ; 4
         dw     offset @@kBr
         dw     offset @@kPp                 ; 5
         dw     offset @@kPr
         dw     offset @@kDp                 ; 6
         dw     offset @@UnknownRelease
         dw     offset @@k1p                 ; 7
         dw     offset @@k1r
         dw     offset @@k2p                 ; 8
         dw     offset @@k2r
         dw     offset @@k3p                 ; 9
         dw     offset @@k3r
         dw     offset @@k4p                 ; 10
         dw     offset @@k4r
         dw     offset @@k5p                 ; 11
         dw     offset @@k5r
         dw     offset @@k6p                 ; 12
         dw     offset @@k6r
         dw     offset @@k7p                 ; 13
         dw     offset @@k7r
         dw     offset @@k8p                 ; 14
         dw     offset @@k8r
         dw     offset @@k9p                 ; 15
         dw     offset @@k9r
         dw     offset @@k0p                 ; 16
         dw     offset @@k0r
         dw     offset @@kIp                 ; 17
         dw     offset @@kIr

@@kXLat  db     00,00,00,07,08,09,10,11,12,13,14,15,16,00,00,00
         db     00,00,00,00,00,00,00,17,00,05,00,00,00,01,00,00
         db     06,07,00,00,00,00,00,00,00,00,00,00,00,00,00,00
         db     04,00,00,00,00,00,00,03,02,00,00,00,00,00,00,00
         db     00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
         db     00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
         db     00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
         db     00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

RealInt9:
        pushf
        cli
        push    ax bx ds

        push    cs
        pop     ds

        mov     al,OldEvent

        call    SetEvent

        cmp     al,1
        jnz     @@NewEvent
        jmp     @@JustEXIT

@@NewEvent:
        mov     bx,offset @@kXLat

        in      al,60h

        cmp     al,80h
        jnb     @@Release

        xlat

        mov     bl,al
        mov     bh,0
        shl     bx,1
        shl     bx,1
        jmp     short @@JMP

@@Release:
        sub     al,80h
        xlat

        mov     bl,al
        mov     bh,0
        shl     bx,1
        shl     bx,1
        inc     bx
        inc     bx

@@JMP:
        jmp     word ptr [@@KeyTable+bx]


@@UnknownPress:
@@UnknownRelease:

@@JustEXIT:
        pop     ds bx ax
        popf
        jmp     dword ptr cs:old88o

@@kCTRLp:
        or      @@KBDFlags,@@kfCTRL
        jmp     @@JustEXIT

@@kCTRLr:
        and     @@KBDFlags,not @@kfCTRL
        mov     @@GRAB_ASTERISK,0
        jmp     @@JustEXIT

@@kALTp:
        or      @@KBDFlags,@@kfALT
        jmp     @@JustEXIT

@@kALTr:
        and     @@KBDFlags,not @@kfALT
        jmp     @@JustEXIT

@@kASTERISKp:
        call    @@Check_CTRL
        jmp     @@GRAB_Screen

@@kASTERISKr:
         test   @@KBDFlags,@@kfCTRL
         jnz    @@EAT_KEY
         mov    @@GRAB_ASTERISK,0
         jmp    @@JustEXIT

@@kIp:
        call    @@Check_CTRL_ALT
        jmp     @@WriteEGAPal
@@kIr:



@@kBp:
@@kBr:

@@kPp:
@@kPr:

        jmp     @@JustEXIT
@@kDp:
        call    @@Check_CTRL_ALT
        db      0EAh
        dw      0FFF0h,0F000h

@@k0p:
@@k0r:
@@k1p:
@@k1r:
@@k2p:
@@k2r:
@@k3p:
@@k3r:
@@k4p:
@@k4r:
@@k5p:
@@k5r:
@@k6p:
@@k6r:
@@k7p:
@@k7r:
@@k8p:
@@k8r:
@@k9p:
@@k9r:
@@k0p:
@@k0r:

@@I13Grb:
        mov     Int13Grabbing,1

@@EAT_KEY:
@@@:

        jmp     @@JustEXIT

@@GRAB_Screen:
        mov     @@GRAB_ASTERISK,1
        cmp     IOwork,1
        je      @@I13Grb
        cmp     Grabbing,1
        je      @@toEK
        call    GRABScreen
@@toEK: jmp     @@EAT_KEY

@@WriteEGAPal:
        mov     ax,offset @@WEGAPal
        call    BrutalAction
        jmp     @@JustEXIT

@@WEGAPal:
        push    ax bx cx dx si di ds es

        push    cs
        pop     ds

        push    cs
        pop     es

        mov     dx,offset PalArea

        mov     ax,1009h
        call    i10


        mov     dx,offset PalFName
        mov     cx,faArchive
        mov     ax,3C00h
        int     21h

        mov     bx,ax

        mov     dx,offset PalArea
        mov     ah,40h
        mov     cx,16
        int     21h

        mov     ah,3Eh
        int     21h


        pop     es ds di si dx cx bx ax
        ret

IRQ1_End proc   near
        in      al,61h
        or      al,10000000b
        out     61h,al
        and     al,01111111b
        out     61h,al
        mov     al,20h
        out     20h,al
        ret
IRQ1_End endp


@@BrkMsg   db   'ÄÍ[ Program execution broken by CTRL ]ÍÄ',10,13,'$'
@@16Result dw   0
@@BossWait db   0

@@GetKey:
        push    ds
        xor     ax,ax
        mov     ds,ax
        mov     bx,9*4

        push    [bx]
        push    [bx+2]
        push    bx

        mov     ax,cs:old9o_0
        mov     [bx],ax
        mov     ax,cs:old9s_0
        mov     [bx+2],ax

        mov     bx,16h*4
        push    [bx]
        push    [bx+2]
        push    bx


        call    IRQ1_End

        mov     al,1
        call    SetEvent

        xor     ax,ax
        pushf
        call    dword ptr cs:old16o
        mov     cs:@@16Result,ax

        pop     bx
        pop     [bx+2]
        pop     [bx]
        pop     bx
        pop     [bx+2]
        pop     [bx]

        mov     al,1
        call    SetEvent
        pop     ds
        ret

KeyboardHandler endp

BrutalAction    proc
        mov     @@BrutalPtr,ax
        mov     @@ForSS,ss
        mov     @@ForSP,sp
        push    cs
        pop     ss
        mov     sp,offset StackArea

        call    IRQ1_End

        push    ds
        xor     ax,ax
        mov     ds,ax
        mov     bx,13h*4
        push    [bx]
        push    [bx+2]
        mov     ax,cs:old13o
        mov     [bx],ax
        mov     ax,cs:old13s
        mov     [bx+2],ax
        push    bx
        mov     bx,21h*4
        push    [bx]
        push    [bx+2]
        mov     ax,cs:old21o
        mov     [bx],ax
        mov     ax,cs:old21s
        mov     [bx+2],ax
        call    word ptr cs:@@BrutalPtr
        pop     [bx+2]
        pop     [bx]
        pop     bx
        pop     [bx+2]
        pop     [bx]
        pop     ds

        mov     al,1
        call    SetEvent
        mov     ss,ds:@@ForSS
        db      cmMovSP
@@ForSP dw      0
        ret
@@ForSS     dw  0
@@BrutalPtr dw  0
BrutalAction    endp


MemoPal proc    near
        push    ds
        pop     es

        mov     dx,offset PalArea
        push    dx
        xor     bx,bx
        mov     cx,85*3
        mov     ax,1017h
        call    i10
        pop     si
        ret     ; SI - PALAREA
MemoPal endp

GetSCRMode proc near
        mov     ah,15
        call    i10
        and     al,7Fh
        mov     l_ScrM,al
        ret
        endp

SetEvent proc   near
        push    ds
        mov     ds,cs:old88s
        mov     OldEvent,al
        pop     ds
        ret
SetEvent endp


m_13Body_B:
        push    si
        add     si,7D00h*2
        SetPal
        pop     si

        mov     cx,7D00h
        mov     ax,0A000h
        mov     es,ax
        rep     movsw
m_13Body_E:

CGA_B:
        mov     cx,1F40h/2
        push    cx
        mov     ax,0B800h
        mov     es,ax
        rep     movsw
        mov     di,2000h
        pop     cx
        rep     movsw
CGA_E:

CO80_B:
        mov     cx,2000
        mov     ax,0B800h
        mov     es,ax
        rep     movsw
        mov     ah,1
db      cmMovCXc
CO80CurSize dw  ?
        int     10h
        mov     ah,2
        mov     bh,0
db      cmMovDXc
CO80CurPos dw  ?
        int     10h
CO80_E:

EnoughCut dw    0
PanNum    db    0

P4_WFile:
        mov     bx,offset AdvRequired
        push    [bx]
        mov     word ptr [bx],0
        mov     P4_WORDS,di
        mov     ax,word ptr CutNo_Hi
        mov     cx,3

IncCutNo3:
        call    IncCutNo
        loop    IncCutNo3
        xchg    word ptr CutNo_Hi,ax
        mov     EnoughCut,ax

P4_LOOP:
        mov     dx,3CEh
        mov     al,5
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        dec     dx
        mov     al,4
        out     dx,al
        inc     dx
        mov     al,PanNum
        out     dx,al

        mov     ax,offset P4_BodyE-offset P4_BodyB
        mov     bx,offset P4_BodyB
        mov     cx,offset WriBlock-offset A_WCall
        mov     si,0A000h

        call    WFile_

        mov     ax,EnoughCut
        cmp     word ptr CutNo_Hi,ax
        jz      EXIT_P4_LOOP
        call    IncCutNo
        shl     P4_Ldr_PanNum,1
        inc     PanNum
        jmp     short P4_LOOP

EXIT_P4_LOOP:
        pop     AdvRequired
        ret

WriFile_NoPal:
        mov     cx,offset WriBlock-offset A_WCall

SPan_WFile:
        mov     ax,offset SP_E-offset SP_B
        mov     bx,offset SP_B

        mov     ADDRESS,si
        mov     SPan_WORDS,di

WFile_:
        mov     Bdy_cx,ax
        mov     Bdy_si,bx
        mov     WCall,cx
        call    FOpen

        push    si
        push    di

        xor     di,di
        mov     cx,offset LdrBeg_E-offset LdrBeg_B
        mov     si,offset LdrBeg_B
        rep     movsb

        call    AddScreenMode

        db      cmMovCxC
Bdy_Cx  dw      0
        db      cmMovSiC
Bdy_Si  dw      0
        rep     movsb

        call    Add_FWaitKey

        mov     cx,offset LdrEnd_E-offset LdrEnd_B
        mov     si,offset LdrEnd_B
        rep     movsb

        mov     cx,di

        mov     si,offset L_DatB-offset LdrBeg_B
        sub     di,3
        mov     [si],di

        pop     di
        pop     si

        mov     ah,40h
        cwd
        int     21h

        db      cmCall
WCall   dw      0
A_WCall:

        call    CloseF
        ret

AddScreenMode:
        cmp     byte ptr AdvRequired,AdvSample
        jnz     Exit_AddScreenMode
        mov     si,offset SetScreen
        mov     cx,AdvSample
        rep     movsb
Exit_AddScreenMode:
        ret

Add_FWaitKey:
        cmp     byte ptr AdvRequired,AdvSample
        jnz     Exit_Add_FWaitKey
        mov     si,offset FWaitKey
        mov     cx,offset FWaitKey_End-offset FWaitKey
        rep     movsb
Exit_Add_FWaitKey:
        ret


LdrBeg_B:
        call LdrCal
l_Samp  db      '$cut$'
l_Flg   dw      000000000000001b
l_ScrM  db      0
l_DatB  dw      0
l_Ver   dw      1
LdrCal:
        pop     bp
        push    cs
        pop     ds
        mov     si,ds:l_Datb[bp]-offset LdrBeg_B-3
        add     si,bp
        xor     di,di
        cld
LdrBeg_E:


LdrEnd_B:
        ret
LdrEnd_E:


SP_B:
        db      cmMovAxC
ADDRESS dw      0
        mov     es,ax

        db      cmMovCxC
SPan_WORDS dw   0

        rep     movsw
SP_E:


SetScreen:
        mov     ah,15
        int     10h
        mov     ah,0
        push    ax
        mov     al,ds:l_ScrM[bp]-offset LdrBeg_B-3
        int     10h
SetScreen_End:


FWaitKey:
        xor     ax,ax
        int     16h
        pop     ax
        int     10h
FWaitKey_End:



P4_BodyB:
        mov     ax,0A000h
        mov     es,ax
        mov     dx,3CEh
        mov     al,5
        out     dx,al
        inc     dx
        xor     al,al
        out     dx,al
        mov     dx,3C4h
        mov     al,2
        out     dx,al
        inc     dx
        db      cmMovAlC
P4_Ldr_PanNum db 1
        out     dx,al
        db      cmMovCxC
P4_WORDS dw     0
        rep     movsw
P4_BodyE:

m0D_B:
        mov     ax,0A000h
        mov     es,ax
        mov     ah,1

m0D_Floop:
        mov     dx,3CEh
        mov     al,5
        out     dx,al
        inc     dx
        xor     al,al
        out     dx,al

        mov     dx,3C4h
        mov     al,2
        out     dx,al
        inc     dx
        mov     al,ah
        out     dx,al
        mov     cx,0FA0h

        rep     movsw
        shl     ah,1
        cmp     ah,10000b
        jnz     m0D_Floop
m0D_E:


m0D_WFile:

        xor     cx,cx

m0D_Loop:
        mov     dx,3CEh
        mov     al,5
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        dec     dx
        mov     al,4
        out     dx,al
        inc     dx
        mov     al,cl
        out     dx,al

        call    WriBlock

        inc     cx
        cmp     cl,4
        jnz     m0D_Loop
        ret

WriteScreen     proc
        pushf
        cli
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    ds
        push    es

        push    cs
        pop     ds
        push    cs
        pop     es

        mov     Grabbing,1

        call    Hide_Mouse

        call    GetSCRMode

        cmp     al,3
        jnz     NOT_CO80

        mov     ah,3
        mov     bh,0
        call    i10
        mov     CO80CurSize,cx
        mov     CO80CurPos,dx
        mov     ax,offset CO80_E-offset CO80_B
        mov     bx,offset CO80_B
        mov     cx,offset WriBlock-offset A_WCall
        mov     si,0B800h
        mov     di,2000
        call    WFile_
        jmp     short Exit_WrtScrn

NOT_CO80:
        cmp     al,4
        jnz     NOT_CGA_Color4

CGA_:
        mov     ax,offset CGA_E-offset CGA_B
        mov     bx,offset CGA_B
        mov     cx,offset CGA_WFile-offset A_WCall
        mov     si,0B800h
        mov     di,1F40h/2
        call    WFile_
        jmp     short Exit_WrtScrn

NOT_CGA_Color4:
        cmp     al,5
        jz      CGA_
        cmp     al,6
        jz      CGA_
        cmp     al,11h
        jnz     NOT_MCGA_MONO

        mov     si,0A000h
        mov     di,4B00h
        call    WriFile_NoPal
        jmp     short Exit_WrtScrn

NOT_MCGA_MONO:
        cmp     al,10h
        jnz     NOT_EGA_10h

        mov     di,36B8h
        call    P4_WFile
        jmp     short Exit_WrtScrn

NOT_EGA_10h:
        cmp     al,13h
        jnz     NOT_MCGA_256
        mov     ax,offset m_13Body_E-offset m_13Body_B
        mov     bx,offset m_13Body_B
        mov     cx,offset m_13SetPal-offset A_WCall
        mov     si,0A000h
        mov     di,07D00h
        call    WFile_
        jmp     short Exit_WrtScrn

NOT_MCGA_256:
        cmp     al,0Dh
        jnz     NOT_EGA_0Dh
        mov     ax,offset m0D_E-offset m0D_B
        mov     bx,offset m0D_B
        mov     cx,offset m0D_WFile-offset A_WCall
        mov     si,0A000h
        mov     di,0FA0h
        call    WFile_
        jmp     short Exit_WrtScrn

NOT_EGA_0Dh:
        cmp     al,12h
        jnz     Not_VgaHi
        mov     di,4B00h
        call    P4_WFile
        jmp     short Exit_WrtScrn

Not_VgaHi:

Exit_WrtScrn:
        push    cs
        pop     ds

        call    Show_Mouse

        mov     P4_Ldr_PanNum,1

        call    IncCutNo
        mov     PanNum,0
        mov     Grabbing,0

        pop     es
        pop     ds
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        popf
        ret
WriteScreen     endp

m_13SetPal      proc
        call    WriBlock
        xor     si,si

AgainWP13:
        push    bx
        mov     bx,si
        mov     cx,85
        mov     ax,1017h
        cwd
        call    i10
        pop     bx
        mov     ah,40h
        cwd
        mov     cx,0FFh
        int     21h
        add     si,85
        cmp     si,85*3
        jnz     AgainWP13
        ret
m_13SetPal      endp


comment #
CO80_GRAB:
        call    FOpen
        ;write DI bytes from SI:DX
        mov     si,0B800h
        mov     di,80*25
        call    WriBlock
        call    CloseF

        jmp     short Exit_WrtScrn
        #

CGA_WFile       proc
        call    WriBlock
        mov     dx,2000h
        call    WriBlock_
        ret
CGA_WFile       endp


WriBlock:
        xor     dx,dx

WriBlock_:      ;write DI*2 bytes from SI:DX
        push    cx
        push    ds
        mov     ds,si
        mov     cx,di
        shl     cx,1
        mov     ah,40h
        int     21h
        pop     ds
        pop     cx
        ret

Int24:
        mov     al,3
        iret

FOpen:
        push    ax
        push    bx
        push    ds
        xor     ax,ax
        mov     ds,ax
        mov     bx,24h*4
        mov     ax,[bx]
        mov     cs:old24o,ax
        mov     ax,[bx+2]
        mov     cs:old24s,ax
        mov     [bx],offset Int24
        mov     [bx+2],cs
        pop     ds
        pop     bx
        pop     ax
        mov     ax,3C00h
        mov     dx,offset fname
        mov     cx,faArchive
        int     21h
        mov     bx,ax
        ret

CloseF:
        push    ax
        push    ds
        xor     ax,ax
        mov     ds,ax

        dw      cmMovWCM
        dw      24h*4
old24o  dw      0

        dw      cmMovWCM
        dw      24h*4+2
old24s  dw      0

        pop     ds
        pop     ax
        mov     ah,3Eh
        int     21h
        ret

AdvRequired     dw 0FFFFh

Hide_Mouse:
        cmp     HideMouse,0
        jz      HM_ret
        mov     ax,2
        int     33h
HM_ret: ret

Show_Mouse:
        cmp     HideMouse,0
        jz      SM_ret
        mov     ax,1
        int     33h
SM_ret: ret


HideMouse db 0FFh

BossFName  db   'BOSS.SCR',0
PalFName   db   'EGA.PAL',0
fname      db   '$CUT$_'
CutNo_Hi   db   '0'
CutNo_Lo   db   '0'
Cont_fname db   '.com',0

IncCutNo:
        push    ax
        mov     al,CutNo_Lo
        mov     ah,CutNo_Hi
        call    PICutNo
        mov     CutNo_Hi,ah
        mov     CutNo_Lo,al
        pop     ax
        ret

PICutNo:
        cmp     al,'9'
        jnz     NotCutLo9
        mov     al,'A'
        ret
NotCutLo9:
        cmp     al,'Z'
        jnz     NotCutLoZ
        mov     al,'0'
        cmp     ah,'Z'
        jnz     NotCutHiZ
        mov     ah,'0'
        ret
NotCutHiZ:
        cmp     ah,'9'
        jnz     NotCutHi9
        mov     ah,'A'
        ret
NotCutHi9:
        inc     ah
        ret
NotCutLoZ:
        inc     al
        ret

BrkDisable:
        mov     cs:BrkEnable,0
        ret

CmpExit:
        call    BrkDisable
        jmp     short Exit21

New21:
        pushf
        cmp     ax,4B00h
        jz      CmpExec
        cmp     ah,0
        jz      CmpExit
        cmp     ah,4Ch
        jz      CmpExit
        cmp     ah,31h
        jz      CmpExit
Exit21:
        popf
        db      0EAh
old21o  dw      0
old21s  dw      0

CmpExec:
        push    ds
        push    es
        push    si
        push    di
        push    cx

        xor     si,si
        mov     di,offset IntTbl

        mov     ds,si
        push    cs
        pop     es

        mov     cx,200h

        cld
        rep     movsw

        pop     cx
        pop     di
        pop     si
        pop     es
        pop     ds

        mov     cs:BrkEnable,1

        jmp     short Exit21

New20:
        call    BrkDisable
        db      0EAh
Old20o  dw      0
Old20s  dw      0

New27:
        call    BrkDisable
        db      0EAh
Old27o  dw      0
Old27s  dw      0

        even


old9o_0 dw      0
old9s_0 dw      0

old13o  dw      0
old13s  dw      0

old16o  dw      0
old16s  dw      0

old10o  dw      0
old10s  dw      0

RSKIinst db     0
RSKImethod db   0

        org     $+StSize

StackArea:
IntTbl  dw      200h   dup (?)
PalArea db      100h*3 dup (?)

WithoutManager:


IRQ2:
        int     0Ah
        iret
        int     0Bh
        iret
        int     0Ch
        iret
        int     0Dh
        iret
        int     0Eh
        iret
        int     0Fh
        iret
        int     08h
        iret
        call    ClearEvent
        pushf
        push    cs
        call    RealInt9
        int     9
        iret
IRQTable_End:

int88:
        iret

ClearEvent proc near
        push    ax
        mov     al,0
        call    SetEvent
        pop     ax
        int     88h
        ret
ClearEvent endp

New16:
        pushf
        cmp     ax,AskConst
        jnz     NOT_CHECKING
        cmp     cx,ax
        jnz     NOT_CHECKING
        cmp     bx,ax
        jnz     NOT_CHECKING
        mov     ax,AnsConst
        mov     bx,ax
        mov     cx,ax
        popf
        iret
NOT_CHECKING:
        popf
        jmp     dword ptr cs:old16o

int13_soft proc
        call    ReplaceI9
int13_hard:
        mov     cs:IOwork,1
        pushf
        call    dword ptr cs:old13o
        mov     cs:IOwork,0
        cmp     cs:Int13Grabbing,0
        jz      @@End
        mov     cs:Int13Grabbing,0
        push    ax bx ds
        push    cs
        pop     ds
        call    GRABScreen
        pop     ds bx ax
@@End:  iret
int13_soft endp

ShortVar:

int9_0:
        call    ClearEvent
        pushf
        push    cs
        call    RealInt9
        jmp     dword ptr cs:old9o_0

int9_1:
        call    ClearEvent
        pushf
        push    cs
        call    RealInt9
        db      0EAh
old9o_1 dw      0
old9s_1 dw      0


ReplaceI9 proc near
        pushf
        push    ax bx cx es ds

        push    cs
        pop     ds

        xor     ax,ax
        mov     es,ax

        mov     bx,es:[9*4]
        mov     cx,es:[9*4+2]

        mov     ax,cs
        cmp     ax,cx

        jnz     @@SetNew9_
        cmp     bx,offset Int9_0
        jnz     @@SetNew9

@@GoodBye_:
        pop     ds es cx bx ax
        popf
        ret

@@SetNew9:
        cmp     bx,offset Int9_1
        jz      @@GoodBye_
@@SetNew9_:
        mov     ds:old9o_1,bx
        mov     ds:old9s_1,cx

        mov     es:[9*4],offset Int9_1
        mov     es:[9*4+2],ds

        jmp     short @@GoodBye_
ReplaceI9 endp

int8:
        call    ReplaceI9
        db      0EAh
old8o   dw      0
old8s   dw      0

int10:
        call    ReplaceI9
        jmp     dword ptr cs:old10o

INSTALL:
        push    cs
        pop     ds

        jmp     short PRGBEG

CheckVer:
        push    ds
        mov     ds,cs:ResSEG
        cmp     RSKIVer,VersionC
        pop     ds
        jnz     WRNGver
        stc
        ret
WRNGver:
        clc
        ret

PRGBEG:

        cli
        cld

        xor     ax,ax
        mov     ds,ax

        push    ds
        call    CheckMem
        pop     ds


        call    CheckPresence
        jc      NotSorry_
        cmp     cs:RSKIinst,1
        jz      NotSorry_

        mov     dx,cs
        mov     bx,9*4
        push    [bx]
        push    [bx+2]

        mov     [bx],dx
        mov     [bx+2],dx

        int     8
        mov     ah,1
        int     13h
        int     28h


        cmp     [bx],dx
        jnz     Sorry_
        cmp     [bx+2],dx
        jz      NotSorry_

        jmp     short NotSorry_

Sorry_:
        pop     [bx+2]
        pop     [bx]


        push    cs
        pop     ds
        lea     dx,MSG0
        mov     ah,9h
        int     21h
        lea     dx,MSG_SO
        mov     ah,9h
        int     21h
Program_Exit:
        lea     dx,LINE
        mov     ah,9h
        int     21h
        sti
        mov     ax,4C00h
        int     21h

NotSorry_:
        pop     [bx+2]
        pop     [bx]
        jmp     Fck1
GetResidentSeg:
        mov     ax,cs:ResSeg
        ret

ChkPort:
        mov     al,0Fh
        out     dx,al
        inc     dx
        in      al,dx
        mov     ah,al
        mov     al,66h
        out     dx,al
        jmp     short $+2
        in      al,dx
        xchg    al,ah
        out     dx,al
        cmp     ah,66h
        je      ExChk
        stc
ExChk:
        ret

GetDisp:
        mov     ax,1A00h
        int     10h
        cmp     al,1Ah
        jne     EGA?
        cmp     bl,7
        jne     nVGAm
        lea     dx,VGAm
        ret
nVGAm:
        cmp     bl,8
        jne     nVGAc
        lea     dx,VGAc
        ret
nVGAc:
        cmp     bl,0Ah
        jne     nMCGAdc
        lea     dx,MCGAdc
        ret
nMCGAdc:
        cmp     bl,0Bh
        jne     nMCGAam
        lea     dx,MCGAam
        ret
nMCGAam:
        cmp     bl,0Ch
        jnz     EGA?
        lea     dx,MCGAac
        ret
EGA?:
        mov     ah,12h
        mov     bl,10h
        int     10h
        cmp     bl,10h
        je      CGA?
        cmp     bh,1
        jne     nEGAm
        lea     dx,EGAm
        ret
nEGAm:
        or      bl,bl
        jne     nEGA64
        lea     dx,EGA64
        ret
nEGA64:
        lea     dx,EGA128
        ret
CGA?:
        mov     dx,3D4h
        call    ChkPort
        jnb     dCGA
        mov     dx,3B4h
        call    ChkPort
        jnb     Mono
        lea     dx,Incom
        ret
dCGA:
        lea     dx,CGA
        ret
Mono:
        mov     dl,0BAh
        in      al,dx
        and     al,80h
        mov     ah,al
        mov     cx,8000h
InPrt:
        in      al,dx
        and     al,80h
        cmp     ah,al
        loopz   InPrt
        jcxz    dMDA
        lea     dx,Herc
        ret
dMDA:
        lea     dx,MDA
        ret

ResSeg  dw      0
Alr__   db      0
Hack_o  dw      0
Hack_s  dw      0

CheckMem:
        call    CheckRSKI
        jc      RSKIAlrInst
        mov     al,0
        mov     cs:RSKIinst,0
        jmp     short CheckMEnd
RSKIAlrInst:
        mov     cs:RSKIinst,1
        xor     ax,ax
        mov     ds,ax
        mov     cx,ds:[88h*4+2]
        mov     bx,offset Program
CheckRSKIprg:
        mov     ds,cx
        mov     ax,cs:[bx]
        cmp     ax,[bx]
        jnz     NextProgram
        mov     ax,cs:[bx+2]
        cmp     ax,[bx+2]
        jnz     NextProgram
        mov     cs:ResSeg,cx
        mov     al,1
        jmp     short CheckMEnd

NextProgram:
        mov     ax,ds:old88s
        cmp     ax,cx
        jnz     ChkNextRSKI
        mov     al,0
        jmp     short CheckMEnd

ChkNextRSKI:
        mov     cx,ax
        jmp     short CheckRSKIprg

CheckMEnd:
        mov    cs:Alr__,al
        ret


CheckPresence:
        cmp    cs:Alr__,1
        jz     Alr__l
        clc
        ret
Alr__l:
        stc
        ret

AfterFck1:
        push    cs
        pop     ds
        lea     dx,MSG0
        mov     ah,9
        int     21h
        call    CheckPresence
        jc      AlrInst

To_Inst:
        jmp     INST
WasAlrInst      db      0
AlrInst:
        mov     cs:WasAlrInst,1
        call    CheckVer
        jc      RightVer
        jmp     W_Msg3
RightVer:
        mov     si,81h
NB1:    lodsb
        cmp     al,' '
        jz      NB1
        cmp     al,'u'
        jz      UnInstall
        cmp     al,'U'
        jz      UnInstall
        cmp     al,'h'
        jz      a_DisplayHelp
        cmp     al,'H'
        jz      a_DisplayHelp
        jmp     NormPar

a_DisplayHelp:
        jmp     DisplayHelp
UnInstall:
        call    GetResidentSeg
        mov     es,ax
        xor     ax,ax
        mov     ds,ax

        mov     ax,es

        cmp     ds:[20h*4],offset New20
        jnz     CantUnInst_
        cmp     ds:[20h*4+2],ax
        jnz     CantUnInst_

        cmp     ds:[21h*4],offset New21
        jnz     CantUnInst_
        cmp     ds:[21h*4+2],ax
        jnz     CantUnInst_

        cmp     ds:[27h*4],offset New27
        jnz     CantUnInst_
        cmp     ds:[27h*4+2],ax
        jnz     CantUnInst_

        cmp     es:RSKIinst,0
        jz      UnInstAllVec

        cmp     ds:[88h*4],offset RealInt9
        jnz     CantUnInst_
        cmp     ds:[88h*4+2],ax
        jnz     CantUnInst_

        mov     ax,es:old88o
        mov     ds:[88h*4],ax
        mov     ax,es:old88s
        mov     ds:[88h*4+2],ax
        jmp     Release

UnInstAllVec:
        mov     ax,es:old88o
        cmp     ax,ds:[88h*4]
        jnz     CantUManager
        mov     ax,es:old88s
        cmp     ax,ds:[88h*4+2]
        jz      UnInstallManager
CantUManager:
        mov     dx,offset CUman
        jmp     PrtStrMSG_N

UnInstallManager:
        mov     ax,es
        cmp     ds:[16h*4],offset New16
CantUnInst_:
        jnz     CantUnInst
        cmp     ds:[16h*4+2],ax
        jnz     CantUnInst

        cmp     es:RSKIMethod,1
        jz      UnInstSoft

        push    ax
        push    es

        mov     cx,0008h

        call    MoveIRQ

        xor     ax,ax
        mov     es,ax
        mov     di,0F0h*4
        mov     cx,16
        cld
        rep     stosw

        mov     al,0
        out     21h,al



        pop     es
        pop     ax
        jmp     Release

UnInstSoft:
        mov     ax,es
        cmp     ds:[8*4],offset int8
        jnz     CantUnInst
        cmp     ds:[8*4+2],ax
        jnz     CantUnInst
        cmp     ds:[9*4],offset int9_0
        jnz     CantUnInst
        cmp     ds:[9*4+2],ax
        jnz     CantUnInst
        cmp     ds:[10h*4],offset int10
        jnz     CantUnInst
        cmp     ds:[10h*4+2],ax
        jnz     CantUnInst
        cmp     ds:[13h*4],offset int13_soft
        jnz     CantUnInst
        cmp     ds:[13h*4+2],ax
        jz      CanUnInst

CantUnInst:
        jmp     PCantUnInst

CheckRSKI:
        mov     ax,AskConst
        mov     bx,ax
        mov     cx,ax
        int     16h
        cmp     ax,AnsConst
        jnz     NotInstRSKI
        cmp     ax,bx
        jnz     NotInstRSKI
        cmp     ax,cx
        jnz     NotInstRSKI
        stc
        ret
NotInstRSKI:
        clc
        ret

CanUnInst:
        mov     ax,es:old8o
        mov     ds:[8*4],ax
        mov     ax,es:old8s
        mov     ds:[8*4+2],ax

        mov     ax,es:old9o_0
        mov     ds:[9*4],ax
        mov     ax,es:old9s_0
        mov     ds:[9*4+2],ax

        mov     ax,es:old10o
        mov     ds:[10h*4],ax
        mov     ax,es:old10s
        mov     ds:[10h*4+2],ax

        mov     ax,es:old13o
        mov     ds:[13h*4],ax
        mov     ax,es:old13s
        mov     ds:[13h*4+2],ax

        mov     ax,es:old88o
        mov     ds:[88h*4],ax
        mov     ax,es:old88s
        mov     ds:[88h*4+2],ax

Release:
        mov     ax,es:old16o
        mov     ds:[16h*4],ax
        mov     ax,es:old16s
        mov     ds:[16h*4+2],ax

        mov     ax,es:old20o
        mov     ds:[20h*4],ax
        mov     ax,es:old20s
        mov     ds:[20h*4+2],ax

        mov     ax,es:old21o
        mov     ds:[21h*4],ax
        mov     ax,es:old21s
        mov     ds:[21h*4+2],ax

        mov     ax,es:old27o
        mov     ds:[27h*4],ax
        mov     ax,es:old27s
        mov     ds:[27h*4+2],ax

        push    es
        mov     ah,49h
        int     21h
        pop     es
        push    cs
        pop     ds
        jnc     SRelease_

        lea     dx,CNR_MSG
        mov     ah,9
        jmp     short PrtStrMSG_N


SRelease_:
        lea     dx,SU_MSG
PrtStrMSG_N:
        mov     ah,9h
        int     21h
        lea     dx,line
        mov     ah,9
        int     21h
        mov     ax,4C00h
        sti
        int     21h

PCantUnInst:
        push    cs
        pop     ds
        lea     dx,CUI_MSG
        jmp     short PrtStrMSG_N

W_Msg3:
        lea     dx,MSG3
        jmp     PrtStrMSG

NormPar:

        mov     si,81h
a_NextByte:
        lodsb

        cmp     al,' '
        jz      a_NextByte
        cmp     al,0Dh
        jnz     a_NotInst__
        jmp     short AlrI__
a_NotInst__:
        cmp     al,'/'
        jz      a_Frac
        cmp     al,'-'
        jz      a_Frac
        jmp     short a_ParError

a_Frac:
        lodsb

        cmp     al,'g'
        jz      a_OptG
        cmp     al,'G'
        jz      a_OptG

        cmp     al,'m'
        jz      a_OptM
        cmp     al,'M'
        jz      a_OptM

        jmp     short a_ParError

a_OptG:
        db      cmJmpShort
a_aOG   db      0
a_cc:   mov     a_aOG,offset a_ParError-offset a_cc
        lodsb
        cmp     al,'+'
        jz      a_SetPls
        cmp     al,'-'
        jz      a_SetMns

        jmp     short a_ParError

a_OptM:
        db      cmJmpShort
a_aOM   db      0
a_ccM:  mov     a_aOM,offset a_ParError-offset a_ccM
        lodsb
        cmp     al,'+'
        jz      a_MSetPls
        cmp     al,'-'
        jz      a_MSetMns

        jmp     short a_ParError


a_SetPls:
        call    G_SP
        jmp     short a_NextByte

a_SetMns:
        call    G_SM
        jmp     short a_NextByte

a_MSetPls:
        call    M_SP
        jmp     short a_NextByte

a_MSetMns:
        call    M_SM
        jmp     short a_NextByte

a_ParError:
        lea     dx,PErrM
        jmp     short PrtStrMsg

AlrI__:
        push    ds
        call    GetResidentSeg
        mov     ds,ax
        mov     bx,offset AdvRequired
        cmp     cs:[bx],0FFFFh
        jz      DontSetAdv
        mov     ax,cs:[bx]
        mov     [bx],ax
DontSetAdv:
        cmp     word ptr [bx],0
        push    cs
        pop     ds
        jz      Grp__Not
        lea     dx,SetScr_ON_
        jmp     short PrtStrMSG0
Grp__Not:lea    dx,SetScr_OFF_

PrtStrMsg0: mov ah,9
        int     21h
        push    ds
        call    GetResidentSeg
        mov     ds,ax
        mov     bx,offset HideMouse
        cmp     byte ptr cs:[bx],0FFh
        jz      DontHidm
        mov     al,cs:[bx]
        mov     [bx],al
DontHidm:
        cmp     byte ptr [bx],0
        push    cs
        pop     ds
        jz      Hid__Not
        lea     dx,HM_ON_
        jmp     short PrtStrMSG
Hid__Not:lea    dx,HM_OFF_

PrtStrMsg:
        mov     ah,9
        int     21h
        cmp     WasAlrInst,1
        jnz     ToLine
        lea     dx,MSG1
        mov     ah,9
        int     21h
ToLine: lea     dx,LINE
        mov     ah,9
        int     21h
        mov     ax,4C00h
        sti
        int     21h

G_SP:
        mov     AdvRequired,AdvSample
        or      l_Flg,fmAdv
        ret

G_SM:
        mov     AdvRequired,0
        mov     ax,fmAdv
        not     ax
        and     l_Flg,ax
        ret

M_SP:
        mov     HideMouse,0FFh
        or      l_Flg,fmHidm
        ret

M_SM:
        lahf
        mov     HideMouse,0
        mov     ax,fmHidm
        not     ax
        and     l_Flg,ax
        ret

DisplayGrpHelp:
        call    GetDisp
        mov     ah,9
        int     21h

DisplayHelp:
        lea     dx,Help_MSG
        mov     ah,9
        int     21h
        jmp     ToLine

INST:
        mov     es,ds:[2Ch]
        mov     ah,49h
        int     21h


        mov     AdvRequired,AdvSample
        mov     HideMouse,0

        mov     si,81h

FNextByte: lodsb
        cmp     al,'h'
        jz      DisplayHelp
        cmp     al,'H'
        jz      DisplayHelp
        cmp     al,'u'
        jz      TryUnload_
        cmp     al,'U'
        jz      TryUnload_
        cmp     al,'i'
        jz      NextByte
        cmp     al,'I'
        jz      NextByte
        cmp     al,' '
        jz      FNextByte
        cmp     al,0Dh
        jz      DisplHelp
        jmp     short NotInst__
TryUnLoad_: jmp TryUnLoad
DisplHelp: jmp  DisplayGrpHelp
NextByte: lodsb
        cmp     al,'s'
        jz      Softmethod
        cmp     al,'S'
        jz      Softmethod
        cmp     al,'h'
        jz      Hardmethod
        cmp     al,'H'
        jnz     JustInstall


Hardmethod:
        mov     RSKImethod,2
        jmp     short methodDone

Softmethod:
        mov     RSKImethod,1

methodDone:
        lodsb
JustInstall:
        cmp     al,' '
        jz      methodDone
        cmp     al,0Dh
        jnz     NotInst__
ToInst: jmp     short Inst_
NotInst__:
        cmp     al,'/'
        jz      Frac
        cmp     al,'-'
        jz      Frac
        jmp     short ParError

Frac:
        lodsb

        cmp     al,'g'
        jz      OptG
        cmp     al,'G'
        jz      OptG

        cmp     al,'m'
        jz      OptM
        cmp     al,'M'
        jz      OptM


        jmp     short ParError

OptG:
        db      cmJmpShort
_aOG    db      0
_cc:    mov     _aOG,offset ParError-offset _cc

        lodsb
        cmp     al,'+'
        jz      SetPls
        cmp     al,'-'
        jz      SetMns

        jmp     short ParError

OptM:
        db      cmJmpShort
aOM     db      0
ccM:    mov     aOM,offset ParError-offset ccM
        lodsb
        cmp     al,'+'
        jz      MSetPls
        cmp     al,'-'
        jz      MSetMns

        jmp     short ParError


SetPls:
        call    G_SP
        jmp     short methodDone

SetMns:
        call    G_SM
        jmp     short methodDone

MSetPls:
        call    M_SP
        jmp     short methodDone

MSetMns:
        call    M_SM
        jmp     short methodDone


ParError:
        lea     dx,PErrM
        jmp     PrtStrMsg

TryUnload:
        mov     word ptr cInt27,cmLongNop
        lea     dx,WNI_MSG
        mov     ah,9
        int     21h
        lea     dx,line
        mov     ah,9
        int     21h
        sti
        mov     ax,4C00h
        int     21h

WriteZAB_MSG:
        mov     dx,offset ZAB_MSG
        mov     ah,9
        int     21h
        ret

Inst_:
        mov     ax,0FADEh
        int     21h
        cmp     ax,0FADDh
        jnz     NotZabol
        cmp     RSKImethod,0
        jnz     NotDefaMeth
        mov     RSKImethod,1
        call    WriteZAB_MSG
        mov     dx,offset crlf
        mov     ah,9
        int     21h
        jmp     short AfterZabol
NotDefaMeth:
        cmp     RSKImethod,2
        jnz     AfterZabol
        call    WriteZAB_MSG
        jmp     Program_Exit
NotZabol:
        cmp     RSKImethod,0
        jnz     AfterZabol
        mov     RSKImethod,2

AfterZabol:
        cli
        cmp     AdvRequired,0
        jz      SetScr__T_OFF
        lea     dx,SetScr_ON_
        jmp     short WMSG_
SetScr__T_OFF:
        lea     dx,SetScr_OFF_
WMSG_:  mov     ah,9
        int     21h

        cmp     HideMouse,0
        jz      HM__T_OFF
        lea     dx,HM_ON_
        jmp     short WMSMG_
HM__T_OFF:
        lea     dx,HM_OFF_
WMSMG_: mov     ah,9
        int     21h

        lea     dx,MSG2
        mov     ah,9
        int     21h
        cmp     RSKIinst,1
        jz      RSKI_was_inst

        lea     dx,RSKIman
        mov     ah,9
        int     21h

RSKI_was_inst:
        mov     ax,3510h
        int     21h
        mov     old10o,BX
        mov     old10s,ES

        mov     ax,3513h
        int     21h
        mov     old13o,BX
        mov     old13s,ES

        mov     ax,3516h
        int     21h
        mov     old16o,BX
        mov     old16s,ES

        mov     ax,3520h
        int     21h
        mov     old20o,BX
        mov     old20s,ES

        mov     dx,offset New20
        mov     ax,2520h
        int     21h

        mov     ax,3521h
        int     21h
        mov     old21o,BX
        mov     old21s,ES

        mov     dx,offset New21
        mov     ax,2521h
        int     21h

        mov     ax,3527h
        int     21h
        mov     old27o,BX
        mov     old27s,ES

        mov     dx,offset New27
        mov     ax,2527h
        int     21h

        cmp     RSKIinst,0
        jz      SetAllVectors

        mov     ax,3588h
        int     21h
        mov     ds:old88o,BX
        mov     ds:old88s,ES
        lea     dx,RealInt9
        mov     ax,2588h
        int     21h

        jmp     SkipAllVectors

Intr    db      0

MoveIRQ:
        in      al,20h
        inc     al
        jz      Intr0
        mov     ch,2
Intr0:  mov     al,11h
        or      al,ch
        xor     al,2
        out     20h,al
        mov     al,cl
        out     21h,al
        mov     ax,409h
        cmp     ch,0
        jz      Intr1
        mov     ax,104h
Intr1:  out     21h,al
        mov     al,ah
        out     21h,al
        mov     al,0FFh
        out     21h,al
        ret

SetAllVectors:
        cmp     RSKImethod,2
        jnz     SetSoftInts

        mov     cx,00F0h
        call    MoveIRQ

        push    es
        xor     ax,ax
        mov     es,ax


        mov     di,0F2h*4
        mov     ax,offset IRQ2
        mov     dx,cs
        mov     cx,6

NxtIRQ: stosw
        mov     bx,ax
        mov     ax,dx
        stosw
        lea     ax,[bx+3]
        loop    NxtIRQ

        mov     di,0F0h*4
        mov     cx,2
NxtIRQ_:stosw
        mov     bx,ax
        mov     ax,dx
        stosw
        lea     ax,[bx+3]
        loop    NxtIRQ_

        mov     al,0
        out     21h,al
        pop     es

        jmp     short SetReqOnly


SetSoftInts:
        mov     ax,3508h
        int     21h
        mov     old8o,BX
        mov     old8s,ES
        lea     dx,int8
        mov     ax,2508h
        int     21h

        lea     dx,int13_soft
        mov     ax,2513h
        int     21h

        lea     dx,int10
        mov     ax,2510h
        int     21h

SetReqOnly:

        lea     dx,int88
        mov     ax,2588h
        int     21h
        mov     ds:old88o,offset Int88
        mov     ds:old88s,cs

SkipAllVectors:
        cmp     RSKIMethod,2
        jnz     DontSetH13
        lea     dx,int13_hard
        mov     ax,2513h
        int     21h

DontSetH13:
        xor     ax,ax
        mov     ds,ax

        mov     bx,9*4

        mov     ax,[bx]
        mov     cs:old9o_0,ax
        mov     ax,[bx+2]
        mov     cs:old9s_0,ax

        cmp     cs:RSKIinst,1
        jz      SkipSetI9
        cmp     cs:RSKImethod,2
        jz      SkipSetI9

        mov     [bx],offset int9_0
        mov     [bx+2],cs

SkipSetI9:

AftrSV:
        push    cs
        pop     ds
        cmp     RSKIinst,1
        jnz     CheckLdMeth
        mov     dx,offset WithoutManager
        jmp     short LoadFromINSTALL
CheckLdMeth:
        mov     dx,offset New16
        mov     ax,2516h
        int     21h

        mov     dx,offset KB_MSG
        mov     ah,9
        int     21h

        cmp     RSKImethod,1
        jnz     RSKIMeth2

        mov     dx,offset RSKI_S
        mov     ah,9
        int     21h
        mov     dx,offset INSTALL
        jmp     short LoadFromINSTALL


RSKIMeth2:
        mov     dx,offset RSKI_H
        mov     ah,9
        int     21h
        mov     dx,offset ShortVar

LoadFromINSTALL:
        push    dx
        lea     dx,LINE
        mov     ah,9
        int     21h
        pop     dx

        sti
cInt27: int     27h
        mov     ax,4C00h
        int     21h

Fck1:
        jmp     AfterFck1



MSG0    db 10,13,'ÄÄÄRSKI',40 dup('Ä'),' Kishinev, RSsoftware ÄÄÄÄÄÄ',10,13
        db 'CTRL Screen Capture   ver 1.44 alpha  '
        db 'Copyright (C) 1992-94 by MasyutinMax~',10,13
LINE    db 75 dup('Ä')
crlf    db 10,13,'$'
MSG2    db 10,13,'Installed',10,13
        db 'Advanced ScrGrab  Ä ON. Hot key <CTRL>-<PrtScr>',10,13
        db 'Advanced Restart  Ä ON. Hot key <CTRL>-<Alt>-"D"',10,13
        db 'Advanced Pause    Ä ON. Hot key <CTRL>-<Alt>-"P"',10,13
        db 'Break current program  - <CTRL>-<Alt>-"B"',10,13
        db 'Clear internal counter - <CTRL>-<Alt>-"C"',10,13
        db 10,13,'$'
RSKIman db 10,13,'RSKI manager was not installed yet Ä CRTL becames the RSKI manager',10,13,'$'
MSG1    db 'CTRL present in memory.',10,13,'$'
MSG3    db 'Incorrect CTRL version already intalled.',10,13,'$'
MSG_SO  db 'Sorry, but INT 9 is occupied by other resident program, loaded before CTRL.'
        db 10,13,'Release it, please, from memory and try again.'
        db 10,13,10,13,'           *** CTRL not installed ***',10,13,'$'
CUI_MSG db 'Sorry, but it is impossible to release CTRL from memory, because the',10,13
        db 'interrupt vectors, used by CTRL are pointing to other program.',10,13
        db 'Release it from memory and try again.',10,13,'$'
SU_MSG  db 'CTRL uninstalled successfuly.',10,13,'$'
CNR_MSG db 'An error occured uninstalling CRTL from memory',10,13,'$'
WNI_MSG db 'CTRL was not installed.',10,13,'$'
CUman   db 'Can not remove RSKI manager',10,13,'$'
PErrM   db 'Invalid parameter string',10,13,'$'
SetScr_ON_      db 'SetScreen  Ä ON',10,13,'$'
SetScr_OFF_     db 'SetScreen  Ä OFF',10,13,'$'
HM_ON_          db 'Hide mouse Ä ON',10,13,'$'
HM_OFF_         db 'Hide mouse Ä OFF',10,13,'$'
Help_Msg db 'Usage     :  CTRL [command] [switches]',10,13,10,13
        db 'Commands  :   I  Ä install CTRL to memory',10,13
        db '              IH Ä install using new, "hardware" method',10,13
        db '              IS Ä install using old, software method',10,13
        db '              U  Ä unload CTRL from memory',10,13
        db '              H  Ä display this help screen',10,13
        db 'Switches  :  /G-|+  Ä Graphics screen set for CUT-files',10,13
        db '             /M-|+  Ä Hide mouse cursor before writing',10,13,10,13
        db 'Examples :',10,13
        db 'CTRL I /M+ /G-   Ä Install CTRL with hidding mouse and no Grp set screen',10,13
        db 'CTRL U           Ä Uninstall CTRL from memory',10,13
        db 'CTRL /M-         Ä Switch hide mouse flag off',10,13,10,13
        db 'Thanks !',10,13,'$'
ZAB_MSG db 'Suspected TSRI program present in memory - looks like one of something',10,13
        db 'by Friends software - "hardware" method impossible',10,13,'$'
KB_MSG  db 'Keyboard intercept method is now $'
RSKI_H  db '"hardware"',10,13,'$'
RSKI_S  db 'software',10,13,'$'
CUH_MSG db '"Hardware" method uninstallation doesn''t allowed in current version',13,10,'$'

VGAm    db 'VGA with analog monochrome display detected.',13,10,'$'
VGAc    db 'VGA with analog color display detected.',13,10,'$'
MCGAdc  db 'MCGA with digital color display detected.',13,10,'$'
MCGAam  db 'MCGA with analog monochrome display detected.',13,10,'$'
MCGAac  db 'MCGA with analog color display detected.',13,10,'$'
EGAm    db 'EGA with monochrome display detected.',13,10,'$'
EGA64   db 'EGA with color display and 64K video RAM detected.',13,10,'$'
EGA128  db 'EGA with color display and 128K+ video RAM detected.',13,10,'$'
CGA     db 'CGA with color or monochrome display detected.',13,10,'$'
Herc    db 'Hercules graphics or graphics plus display detected.',13,10,'$'
MDA     db 'MDA with monochrome display detected.',13,10,'$'
Incom   db 'Incompatible video subsystem.',13,10,'$'


%OUT    - Pass end
%OUT

CODE    ends
        end     START