.section .rodata
filename: .asciz "database.dat"
read_mode: .asciz "r"
write_mode: .asciz "w"

fmt_intero_scan: .asciz "%d"
fmt_stringa_scan: .asciz "%127s"

fmt_intestazione_menu:
    .ascii "\n\n*********************************************************************************************\n"
    .ascii "************************************** CLASSIFICA  FIMI *************************************\n"
    .asciz "*********************************************************************************************\n"             
fmt_database: .asciz "TITOLO               ARTISTA              NUMERO_TRACCE     COPIE_VENDUTE     PREZZO    TEMPO\n"
fmt_menu_line: .asciz "_____________________________________________________________________________________________\n"
fmt_menu_entry:
    .asciz "%-20s %-20s %-17d %-17d %-9d %-5d\n"

fmt_menu:
    .ascii "\n|----------MENU'----------\n"
    .ascii "|1: AGGIUNGI ALBUM\n"
    .ascii "|2: ELIMINA ALBUM\n"
    .ascii "|3: VISUALIZZA DATABASE\n"
    .ascii "|4: VISUALIZZA STATISTICHE\n"
    .ascii "|5: ESCI\n"
    .asciz ">>> "

fmt_indentazione_statistiche:
    .ascii "\nScegli la statistica da visualizzare.\n"                          
    .ascii "|1: MEDIA NUMERO TRACCE\n"
    .ascii "|2: MAX COPIE VENDUTE\n"
    .ascii "|3: PREZZO MEDIO\n"
    .ascii "|4: ASCOLTO MEDIO\n"
    .asciz ">>> "

fmt_errorenumero: .asciz "\nNumero inserito non valido. Inserire un altro numero\n"

fmt_menu_titolo: .asciz "\nTitolo: "
fmt_menu_artista: .asciz "Artista: "
fmt_menu_numero_tracce: .asciz "Numero tracce: "
fmt_menu_copie_vendute: .asciz "Copie vendute: "
fmt_menu_prezzo: .asciz "Prezzo album: "
fmt_menu_tempo: .asciz "Tempo di ascolto in ore: "

fmt_error_aggiungi_album: .asciz "\nMemoria insufficiente. Eliminare un album, quindi riprovare.\n\n"
fmt_extended_play: .asciz "\nHai inserito un 'Extended play'. Inserire album con numero tracce maggiore di 5.\n\n"

fmt_elimina_album: .asciz "\nInserisci l'indice dell'album da eliminare (maggiore di 0): "

fmt_mediatracce: .asciz "\nIl numero medio delle tracce è: %d\n"
fmt_maxcopie: .asciz "\nLe copie massime vendute presenti nel database sono: %d\n\n"
fmt_prezzomedio: .asciz "\nIl prezzo medio degli album è: %.2f\n\n"
fmt_ascoltomedio: .asciz "\nIl tempo medio di ascolto degli album è: %.2f\n\n"

fmt_errorestatistiche: .asciz "\nErrore nel calcolo. Nessun album presente nel database.\n\n"



.equ max_album, 10
.equ s_titoloalbum, 20
.equ s_nomeartista, 20
.equ s_numerotracce, 4
.equ s_prezzoalbum, 4
.equ s_copievendute, 4
.equ s_tempo, 4
.equ offset_titoloalbum, 0
.equ offset_nomeartista, offset_titoloalbum + s_titoloalbum
.equ offset_numerotracce, offset_nomeartista + s_nomeartista
.equ offset_copievendute, offset_numerotracce + s_numerotracce
.equ offset_prezzoalbum, offset_copievendute + s_copievendute
.equ offset_tempo, offset_prezzoalbum + s_prezzoalbum
.equ album_size_aligned, 64

.bss
tmp_str: .skip 128
tmp_int: .skip 8
album: .skip album_size_aligned * max_album

.data
n_album: .word 0


.macro stampaintestazione              
    adr x0, fmt_intestazione_menu
    bl printf
.endm

.macro menu formatstring                   
    adr x0, \formatstring
    bl printf
    adr x0, fmt_intero_scan
    ldr x1,=tmp_int
    bl scanf
.endm

.macro leggi_intero stringa_menu   
    adr x0, \stringa_menu
    bl printf

    adr x0, fmt_intero_scan
    adr x1, tmp_int
    bl scanf

    ldr x0, tmp_int
.endm

.macro leggi_stringa stringa_menu 
    adr x0, \stringa_menu
    bl printf

    adr x0, fmt_stringa_scan
    adr x1, tmp_str
    bl scanf

    ldr x0, tmp_str
.endm

.macro salva_in registro, offset, s
    add x0, \registro, \offset
    ldr x1, =tmp_str
    mov x2, \s
    bl strncpy

    add x0, \registro, \offset + \s - 1
    strb wzr, [x0]
.endm


.macro inserimentoffset offset formatstring
    ldr x3, =album
    add x3, x3, \offset
    adr x20, \formatstring
    bl statistichedouble
.endm



.text
.type main, %function
.global main
main:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!

    bl load_data

    main_loop:
        menu fmt_menu
        ldr w0, tmp_int
    
        add_album:
            cmp w0, #1
            bne delete_album
            bl aggiungi_album
            b main_loop
        
        delete_album:
            cmp w0, #2
            bne database
            bl elimina_album
            b main_loop
        
        database:
            cmp w0, #3
            bne stats
            bl stampa_menu
            b main_loop

        stats:
            cmp w0,#4
            bne esci
            b loop_statistiche

        esci:
            cmp w0,#5
            bne errore1
            b end_main 
        
            

    loop_statistiche:
        menu fmt_indentazione_statistiche
        ldr w0, tmp_int

        statistica1:
            cmp w0,#1
            bne statistica2
            bl mediatracce
            b main_loop

        statistica2:
            cmp w0,#2
            bne statistica3
            bl maxcopie
            b main_loop

        statistica3:
            cmp w0,#3
            bne statistica4
            inserimentoffset offset_prezzoalbum fmt_prezzomedio
            b main_loop
            
        statistica4:
            cmp w0,#4
            bne errore2
            inserimentoffset offset_tempo fmt_ascoltomedio
            b main_loop


    errore1:
        adr x0, fmt_errorenumero
        bl printf
        b main_loop
    errore2:
        adr x0, fmt_errorenumero
        bl printf
        b loop_statistiche

    end_main:

    mov w0, #0
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size main, (. -main)


.type load_data, %function              
load_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    
    adr x0, filename
    adr x1, read_mode
    bl fopen

    cmp x0, #0
    beq end_load_data

    mov x19, x0

    ldr x0, =n_album
    mov x1, #4
    mov x2, #1
    mov x3, x19
    bl fread

    ldr x0, =album
    mov x1, album_size_aligned
    mov x2, max_album
    mov x3, x19
    bl fread

    mov x0, x19
    bl fclose

    end_load_data:

    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret
    .size load_data, (. - load_data)


.type save_data, %function              
save_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    
    adr x0, filename
    adr x1, write_mode
    bl fopen

    cmp x0, #0
    beq fail_save_data

        mov x19, x0

        ldr x0, =n_album
        mov x1, #4
        mov x2, #1
        mov x3, x19
        bl fwrite

        ldr x0, =album
        mov x1, album_size_aligned
        mov x2, max_album
        mov x3, x19
        bl fwrite

        mov x0, x19
        bl fclose

        b end_save_data

    fail_save_data:
        adr x0, fmt_error_aggiungi_album
        bl printf

    end_save_data:

    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret
    .size save_data, (. - save_data)
    
    

.type aggiungi_album, %function         
aggiungi_album:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    ldr x19, n_album
    ldr x20, =album
    mov x0, album_size_aligned
    mul x0, x19, x0
    add x20, x20, x0

    cmp x19, max_album
    bge fail_aggiungi_album
    
    leggi_stringa fmt_menu_titolo  
        salva_in x20, offset_titoloalbum, s_titoloalbum

    leggi_stringa fmt_menu_artista
        salva_in x20, offset_nomeartista, s_nomeartista

    leggi_intero fmt_menu_numero_tracce
        cmp x0, #5
        ble extended_play
        str w0, [x20, offset_numerotracce]

    leggi_intero fmt_menu_copie_vendute
        str w0, [x20, offset_copievendute]
        
    leggi_intero fmt_menu_prezzo
        str w0, [x20, offset_prezzoalbum]

    leggi_intero fmt_menu_tempo
        str w0,[x20, offset_tempo]

    add x19, x19, #1
    ldr x20, =n_album
    str x19, [x20]

    bl save_data

    b end_aggiungi_album 

    extended_play:
        adr x0, fmt_extended_play
        bl printf
        b end_aggiungi_album

    fail_aggiungi_album:
        adr x0, fmt_error_aggiungi_album
        bl printf
    end_aggiungi_album:
    

    mov w0, #0
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size aggiungi_album, (. - aggiungi_album)


.type stampa_menu, %function
stampa_menu:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    str x21, [sp, #-8]!
    
    adr x0, fmt_intestazione_menu
    bl printf
    adr x0, fmt_menu_line
    bl printf
    adr x0, fmt_database
    bl printf
    adr x0, fmt_menu_line
    bl printf

    mov x19, #0
    ldr x20, n_album
    ldr x21, =album
    print_loop:
        cmp x19, x20
        bge end_print_loop

        adr x0, fmt_menu_entry
        add x1, x21, offset_titoloalbum
        add x2, x21, offset_nomeartista
        ldr w3, [x21, offset_numerotracce]
        ldr w4, [x21, offset_copievendute]
        ldr w5, [x21,offset_prezzoalbum]
        ldr w6, [x21,offset_tempo]
        bl printf

        add x19, x19, #1
        add x21, x21, album_size_aligned
        b print_loop
    end_print_loop:

    adr x0, fmt_menu_line
    bl printf

    ldr x21, [sp], #8
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size stampa_menu, (. - stampa_menu)



.type elimina_album, %function
elimina_album:
    stp x29, x30, [sp, #-16]!

    bl stampa_menu
    adr x0, fmt_elimina_album
    bl printf

    adr x0, fmt_intero_scan
    ldr x1, =tmp_int
    bl scanf

    ldr x0, tmp_int
    cmp x0, #1
    blt end_elimina_album

    ldr x1, n_album
    cmp x0, x1
    bgt end_elimina_album
    

    sub x5, x0, #1   
    ldr x6, n_album
    sub x6, x6, x0  
    mov x7, album_size_aligned
    ldr x0, =album
    mul x1, x5, x7  
    add x0, x0, x1  
    add x1, x0, x7  
    mul x2, x6, x7  
    bl memcpy

    ldr x0, =n_album
    ldr x1, [x0]
    sub x1, x1, #1
    str x1, [x0]

    bl save_data
    b end_elimina_album

    end_elimina_album:
    
    ldp x29, x30, [sp], #16
    ret
    .size elimina_album, (. - elimina_album)


.type mediatracce, %function
mediatracce:
    stp x29, x30, [sp, #-16]!
    
    ldr w0, n_album
    cmp w0, #0
    beq mediatracce_errore

        mov w1, #0
        mov w2, #0
        ldr x3, =album
        add x3, x3, offset_numerotracce
        loop_tracce:
            ldr w4, [x3]
            add w1, w1, w4
            add x3, x3, album_size_aligned

            add w2, w2, #1
            cmp w2, w0
            blt loop_tracce
        
        udiv w1, w1, w0
        adr x0, fmt_mediatracce
        bl printf

        b end_mediatracce

    mediatracce_errore:
        adr x0, fmt_errorestatistiche
        bl printf
    
    end_mediatracce:

    ldp x29, x30, [sp], #16
    ret
    .size mediatracce, (. - mediatracce)
    

.type statistichedouble, %function
statistichedouble:    
    stp x29, x30, [sp, #-16]!
    
    ldr x0, n_album
    cmp x0, #0
    beq statistica_errore

        fmov d1, xzr
        mov x2, #0
        
        loop_double:
            ldr w4, [x3]
            ucvtf d4, w4
            fadd d1, d1, d4
            add x3, x3, album_size_aligned

            add x2, x2, #1
            cmp x2, x0
            blt loop_double
        
        ucvtf d0, x0
        fdiv d0, d1, d0
        mov x0, x20
        bl printf

        b end_double

    statistica_errore:
       adr x0, fmt_errorestatistiche
       bl printf
    
    end_double:
    
    ldp x29, x30, [sp], #16
    ret
    .size statistichedouble, (. - statistichedouble)


.type maxcopie %function
maxcopie:
    stp x29,x30,[sp,#-16]!
    ldr w0, n_album
    cmp w0, #0
    beq nessunalbum
        mov w1, #0
        mov w2, #0
        ldr x3, =album
        add x3, x3, offset_copievendute
        loop_maxcopie:
            ldr w4,[x3]
            cmp w4, w1
            csel w1,w4,w1,gt
            add x3,x3,album_size_aligned
            add w2,w2,#1
            cmp w2,w0
            blt loop_maxcopie
        adr x0, fmt_maxcopie
        bl printf
        b end_maxcopie
    nessunalbum:
        adr x0,fmt_errorestatistiche
        bl printf
    
    end_maxcopie:

    mov w0,#0
    ldp x29,x30, [sp],#16
    ret
    .size maxcopie, (. - maxcopie)
