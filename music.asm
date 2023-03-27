; by Jaakub Kolodziej and Jakub Slomian
kod segment
assume cs:kod,ss:stosik,ds:dane;
;timer
nuta proc
        call licznik
        call tempo
        mov temp, 0
petla1:
        mov temp, cx
        xor cx, cx
        mov ah,86h
        int 15h
        mov cx, temp
        loop petla1
        ret
nuta endp; długość całej nuty


tempo proc
        xor dx, dx

        cmp tmpo, '1' 
        mov dx, 8191; 0,25s
        je return

        cmp tmpo, '2'
        mov dx, 16383; 0,5s
        je return

        cmp tmpo, '3'
        mov dx, 24575; 0,75s
        je return

        cmp tmpo, '4'
        mov dx, 32767; 1s
        je return

        cmp tmpo, '5'
        mov dx, 40958; 1,25s
        je return

        cmp tmpo, '6'
        mov dx, 49150; 1,5s
        je return

        cmp tmpo, '7'
        mov dx, 57343; 1.75s
        je return

        cmp tmpo, '8'
        mov dx, 65535; 2s
        je return

return: ret
tempo endp


licznik proc ;rodzaj nuty
        xor cx, cx

        cmp czas, 'f'; calonuta 
        mov cx, 32
        
        je r
        cmp czas, 'p'; polnuta
        mov cx, 16
        je r
        
        cmp czas, 'c'; cwiercnuta
        mov cx, 8
        je r
        
        cmp czas, 'u'; osemka
        mov cx, 4
        je r
        
        cmp czas, 's'; szesnaastka
        mov cx, 2
        je r
        
        cmp czas, 't'; trzydziestodwojka
        mov cx, 1
        je r
        
        cmp czas, 'L'; 2 nuty
        mov cx, 64
        r: ret
licznik endp


sound proc
        mov ax,ton
        mov dx,42h
        out dx,al
        mov al,ah
        out dx,al

;Wlaczenie glosnika
        mov dx,61h
        in al,dx;
        or al,00000011B
        out dx,al
        ret
endp

;Wylaczenie glosnika
mute proc
        mov dx,61h
        in al,dx
        and al,11111100B
        out dx,al
        ret
endp;

;Odtwarzanie
play proc
        cmp pause, 1
        mov pause, 0
        je pz

        call sound
comp:   call nuta

endplay:call mute
        ret
pz:
        call mute
        jmp comp
play endp


exit proc
        call mute
        mov ax,4c00h
        int 21h
exit endp;


pobPlik proc
        ;STACK  es->ds, ds->ds, ds->ds, es->es
        PUSH es
        PUSH ds
        POP es
        ;pobranie adresu psp ktory zawiera dane o wywolanym programie (w bx)
        MOV ah,62h
        INT 21h
        MOV pspSeg,bx
        PUSH ds
        MOV ds,pspSeg
        ;na ofset 80 w pspSeg jest ilosc znakow ktore uzytkownik wpisal po wywolaniu programu(jako argument)
        MOV si,80h
        XOR ch,ch
        ;dekrementujemy cl bo nie czytamy pierwszego znaku(spacji)
        DEC cl
        MOV ds,bx
        ;zapisujemy argument do zmiennej
        MOV si,82h
        MOV di,offset nazwaPliku
        REP MOVSB
        POP ds
        POP es
        ;ciag musi byc konczony bajtem 0
        MOV nazwaPliku[di],00h
        RET
pobPlik endp


;Program
start:  mov ax,dane
        mov ds,ax
        mov ax,stosik
        mov ss,ax
        mov sp,offset szczyt

        mov ah,62h
        int 21h
        mov es,bx
        mov si,80h
        xor ch,ch
        mov cl,es:[si]
        cmp cl,0        
        je Domyslna        

        dec cl
        inc si
        push cx
        push si
        call pobPlik
        pop si
        pop cx
        lea di,nazwaPliku
        push cx

zapisz: inc si
        mov al,es:[si]
        mov ds:[di],al
        inc di
        loop zapisz
        pop cx
        cmp cl,9
        jge Domyslna
        mov al,9
        sub al,cl
        mov cl,al
        xor ch,ch
        xor al,al

uzupelnij:      
        mov ds:[di],al
        inc di
        loop uzupelnij


Domyslna:       
        lea dx,nazwaPliku
        mov ah,3Dh
        xor al,al
        int 21h
        mov bx,ax
        jnc plikOk
        lea dx,blad
        mov ah,09H
        int 21h
        lea dx,nazwaPliku
        mov ah,09H
        int 21h
        jmp exit


plikOk: xor cx,cx
        xor dx,dx
        mov ah,42h
        mov al,2h
        int 21h
        mov dlugosc,ax

        xor cx,cx
        xor dx,dx
        mov ah,42h
        xor al,al
        int 21h

        mov cx,dlugosc
        lea dx,dzwiek
        mov ah,3FH
        int 21h

        mov ah,3eh
        int 21h

        lea dx,odtwarzam
        mov ah,09H
        int 21h

        mov di,0
        lea bx,dzwiek
        mov cl,ds:[bx+di]
        mov tmpo, cl
        inc di
        inc di


melodia:
        lea bx,dzwiek
        mov dl,ds:[bx+di]
        inc di
        cmp dl,'Q' ; jesli Q to koniec melodii
        je wyjscie
	; ustawianie tonow dla oktawy "0" teoretycznie nie istnieje ale ulatwia zadanie
        cmp dl,'C'
	mov ton,34546 ; 1.19MHz/33Hz
        je oktawa
        
        cmp dl,'D'
        mov ton,30811 ; 1.19MHz/37Hz
        je oktawa
        
        cmp dl,'E'
	mov ton,27805 ; 1.19MHz/41Hz
        je oktawa
        
        cmp dl,'F'
        mov ton,25909 ; 1.19MHz/44Hz
        je oktawa
        
        cmp dl,'G'
        mov ton,23265 ; 1.19MHz/49Hz
        je oktawa
        
        cmp dl,'A'
        mov ton,20727 ; 1.19MHz/55Hz
        je oktawa
        
        cmp dl,'H'
        mov ton,18387 ; 1.19MHz/62Hz
        je oktawa

pauza:  mov pause, 1
        mov ton, 1


oktawa: mov cl,ds:[bx+di]
        inc di
        sub cl,30h
        shr ton,cl ; ustawienie tonu z poprawka na oktawe/dzielenie tonu przez 2^oktawa


graj:   mov dl,ds:[bx+di]
        inc di
        inc di
        mov czas,dl
        call play        
        cmc
        mov al, 00
        mov ah, 1
        int 16h
        jnz wyjscie
        jmp melodia

wyjscie: call exit

kod ends;


dane segment

dzwiek db 3000 dup('$')

pspSeg dw ?
pause dw 0
ton dw 0
czas db 0
tmpo db 0
dlugosc dw 0
temp dw 0

odtwarzam db 'Odtwarzanie pliku: '
nazwaPliku db 127 dup(0)
db 5 dup('$')
blad db 'Brak pliku$'
brakArg    db "Brak argumentow",13,10,'$'

dane ends


stosik segment stack
dw 100h dup(0)
szczyt label word
stosik ends
end start
