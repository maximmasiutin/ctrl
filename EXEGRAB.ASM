        p386

        segment CODE use16
        assume  cs:CODE,ds:CODE
        org     100h

Start:
        jmp     Install
        org     300h

eh_MZ      db  'MZ'
eh_PartPag dw   ?  ; length of partial page at end
eh_PageCnt dw   ?  ; length of image in 512-byte pages, including the header
eh_ReloCnt dw   0  ; number of items in relocation table
eh_HdrSize dw   2  ; size of header in 16-byte paragraphs
eh_MinMem  dw   16 ; minimum memory needed above end of program (paragraphs)
eh_MaxMem  dw   16 ; maximum memory needed above end of program (paragraphs)
eh_ReloSS  dw   ?  ; segment offset of stack segment (for setting SS)
eh_ExeSP   dw   ?  ; value for SP register (stack pointer) when started
eh_ChkSum  dw   0  ; file checksum (negative sum of all words in file)
eh_ExeIP   dw   0  ; value for IP register (instruction pointer) when started
eh_ReloCS  dw   0  ; segment offset of code segment (for setting CS)
eh_TablOff dw   0  ; file-offset of first relocation item
eh_Overlay dw   0  ; overlay number (0 for base module)
eh_Unused  db   'GRAB'

VideoMode       db      ?

IRQ2 dw 00ACDh,0CDCFh,0CF0Bh,00CCDh,0CDCFh,0CF0Dh,00ECDh,0CDCFh,0CF0Fh
IRQ0 db 0CDh,008h,0CFh
IRQ1:
	push    ax
        in      al,60h
        cmp     al,58h
        je      GrabKey
        cmp     al,0D8h
        je      EatKey
        pop     ax
        int     9
        iret

GrabKey:
        pusha
        push    ds es
        pop     ds es
        popa

EatKey:
        in      al,61h
        or      al,80h
        out     61h,al
        and     al,7Fh
        out     61h,al
        mov     al,20h
        out     20h,al
        pop     ax
        iret

Int10:
        cmp     ah,0
        jz      SVM
        cmp     ah,0Fh
        jne     Old10
        pushf
        call    [cs:Old10a]
        mov     [cs:VideoMode],al
        iret
SVM:
        mov     [cs:VideoMode],al
Old10:  db      0EAh
Old10a  dd      ?
EndTSR:

Install:
        cld

	lea     dx,[PTitle]     ; Write Title Info
        mov     ah,9
        int     21h

	pushf                   ; Standart 386 CPU Detection
        pop     bx
        and     bh,0Fh
        push    bx
        popf
        pushf
        pop     cx
        and     ch,0Fh
        cmp     ch,0Fh
        je      N386
        inc     ax
        or      bh,0F0h
        push    bx
        popf
        pushf
        pop     cx
        and     ch,0F0h
        jne     CPU386

N386:
	lea     dx,[N386Msg]    ; CPU 386+ not detected : write message
	jmp     WriteExit       ; and Exit

CPU386:
	mov     si,80h          ; Get ParamStrSize from DTA
        lodsb
        cmp     al,0
        jz      LoadCMD

SkpCMDSpc:
	lodsb                   ; Analyze ParamStr
        cmp     al,' '
        je      SkpCMDSpc       ; Skip Space
        and     al,0DFh         ; UpCase
        cmp     al,'U'
        jz      UnloadCMD

        lea     dx,[Help]       ; Write HELP Info

WriteExit:
        mov     ah,9
        int     21h
        ret                     ; Exit program

UnloadCMD:

        push    0
	pop     es

	mov     es,[es:0F0h*4+2]
	lea	si,[IRQ2]
	mov	di,si
	mov	cx,5
	rep	cmpsd
	jcxz	Unload

	lea	dx,[CUMsg]
	jmp	WriteExit

Unload:
	mov     ah,08h
	call    MoveIRQ         ; Restore IRQ0 vector to Int 08h etc
	mov	ah,49h		; Release memory, occupied by TSR EXEGRAB
	int	21h
	lea	dx,[UnlMsg]
	jmp	WriteExit

LoadCMD:
	mov     es,[2Ch]        ; Release DOS Environment block
	mov     ah,49h
	int     21h

	cli                     ; Prepare IRQ Environment

	push    0
	pop     es

	les     di,[es:0F2h*4]
	lea     si,[IRQ2]
	mov     cx,9
	rep     cmpsw
	push	0
	pop	es

	jcxz    SetIRQ1Only

	mov     ah,0F0h
	call    MoveIRQ         ; Set IRQ0 vector to Int 0F0h etc

	mov     di,0F2h*4
	lea     ax,[IRQ2]
	mov     dx,cs
	mov     cx,6

	call    RollIRQ

	mov     di,0F0h*4
	mov     cx,2

	call    RollIRQ

	jmp     IntOK

SetIRQ1Only:
	mov     [word ptr es:0F1h*4+0],offset IRQ1
	mov     [word ptr es:0F1h*4+2],cs
	sti
	lea     dx,[Joined]
	mov     ah,9
	int     21h

IntOK:
	sti
	lea     dx,[EndTSR]
	int     27h

MoveIRQ:
	mov     al,11h
        out     20h,al
        mov     al,ah
        out     21h,al
        mov     al,4
        out     21h,al
	mov     al,1
	out     21h,al
	ret

RollIRQ:
	stosw
	mov     bx,ax
	mov     ax,dx
	stosw
	lea     ax,[bx+3]
	loop    RollIRQ
	ret

PTitle  db 'Video EXE Grabber  Version 1.0  Copyright (C) 1994 by FRIENDS Software',13,10,'$'
Help    db 'Usage: ~EXEGRAB [U]~  Option ~U~ unloads EXEGRAB from memory.',13,10,'$'
N386Msg db 'This program requires CPU 386 or later',13,10,'$'
Joined  db 'Joined by IRQ controller',13,10,'$'
CUMsg	db 'EXEGRAB couldnt be found on memory',13,10,'$'
UnlMsg	db 'EXEGRAB unloaded OK',13,10,'$'

	ends    CODE
	end     Start