;  Gabriella Haines, Tommy, Sebashtian
; Final Project: Character Frequency Counter
; LC-3 Program: Character Frequency Counter with Full ASCII Support
; Features: Input handling, ASCII classification, stack usage, subroutines, overflow checks, comments

; ======================
; Data Memory Allocation (move before .ORIG x3000 to avoid PC-relative issues)
; ======================
.ORIG x4000
STR_ARR        .BLKW #50
FREQ_TABLE     .BLKW #128   ; one for each ASCII character
STACK_SPACE    .BLKW #100   ; reserve actual stack space
.END

.ORIG x3000

; ======================
; Constants and Pointers
; ======================
ASCII_0        .FILL x0030          ; ASCII code for '0'
CARRIAGE_RETURN .FILL x000A         ; Carriage return (ENTER)
COLON          .FILL x003A          ; ':' character
SPACE          .FILL x0020          ; ' ' space character
NEWLINE        .FILL x000A          ; newline for output formatting
MAX_LEN        .FILL #50            ; maximum input length
NEG_50         .FILL #-50           ; used for overflow check
NEG_26         .FILL #-26
ASCII_127      .FILL x007F          ; max ASCII character value (127)
ASCII_A        .FILL x0041          ; 'A'
ASCII_Z        .FILL x005A          ; 'Z'
ASCII_a        .FILL x0061          ; 'a'
ASCII_z        .FILL x007A          ; 'z'
ASCII_TAB      .FILL x0009          ; tab character

STR_PTR        .BLKW #1             ; pointer to start of STR_ARR (writeable)
STR_LEN        .BLKW #1             ; stores string length
INDEX          .BLKW #1             ; input string index
UPPER_CNT      .BLKW #1
LOWER_CNT      .BLKW #1
SPACE_CNT      .BLKW #1
SYMBOL_CNT     .BLKW #1

; ======================
; Program Entry
; ======================
LEA R0, PROMPT
PUTS                        ; prompt user for name

AND R2, R2, #0              ; index = 0
ST R2, INDEX                ; store initial index

LEA R1, STR_ARR
ST R1, STR_PTR              ; store base pointer of string array

LEA R6, STACK_SPACE         ; load address of stack
ADD R6, R6, #100            ; move to top of stack

; ======================
; Input Loop
; ======================
INPUT_LOOP
    GETC                    ; read character from keyboard
    OUT                     ; echo character to screen

    LD R3, CARRIAGE_RETURN
    NOT R3, R3
    ADD R3, R3, R0          ; compare R0 with carriage return
    BRz DONE_INPUT          ; if ENTER, end input

    JSR STORE_INPUT         ; otherwise, store character
    BR INPUT_LOOP

DONE_INPUT
    JSR GET_LENGTH          ; finalize length
    JSR COUNT_FREQ          ; count character frequency
    JSR PRINT_FREQ          ; print frequency report
    JSR PRINT_STATS         ; print category counts

    LEA R0, END_MSG
    PUTS
    HALT

; ======================
; Subroutine: STORE_INPUT
; Stores R0 to STR_ARR[index], checks for overflow
; ======================
STORE_INPUT
    JSR SAVE_REGS

    LD R1, STR_PTR          ; base of STR_ARR
    LD R2, INDEX            ; current index
    LD R3, MAX_LEN

    NOT R3, R3
    ADD R3, R2, R3
    BRzp OVERFLOW_ERR       ; if index >= MAX_LEN, error

    ADD R4, R1, R2
    STR R0, R4, #0          ; STR_ARR[index] = char

    ADD R2, R2, #1
    ST R2, INDEX            ; update index

    JSR RESTORE_REGS
    RET

; ======================
; Subroutine: GET_LENGTH
; Stores final index value to STR_LEN
; ======================
GET_LENGTH
    LD R1, INDEX
    ST R1, STR_LEN
    RET

; ======================
; Subroutine: COUNT_FREQ
; Counts ASCII character frequencies in STR_ARR
; ======================
COUNT_FREQ
    LD R1, STR_PTR          ; pointer to string
    AND R2, R2, #0          ; i = 0
    LD R3, STR_LEN          ; total string length

CF_LOOP
    NOT R4, R2
    ADD R4, R3, R4
    ADD R4, R4, #1
    BRn CF_END              ; if i >= length, end loop

    ADD R5, R1, R2
    LDR R6, R5, #0          ; current char

    ; Bounds check: skip if char < 0 or >= 128
    BRn SKIP_CHAR           ; if negative ASCII value
    LD R7, ASCII_127
    NOT R7, R7
    ADD R7, R6, R7
    BRzp SKIP_CHAR          ; if char >= 128

    ; Category classification
    LD R7, ASCII_A
    NOT R7, R7
    ADD R7, R6, R7
    BRn NOT_UPPER
    LD R7, ASCII_Z
    NOT R7, R7
    ADD R7, R6, R7
    BRp NOT_UPPER
    LD R7, UPPER_CNT
    ADD R7, R7, #1
    ST R7, UPPER_CNT
    BR SKIP_CLASS
NOT_UPPER
    LD R7, ASCII_a
    NOT R7, R7
    ADD R7, R6, R7
    BRn NOT_LOWER
    LD R7, ASCII_z
    NOT R7, R7
    ADD R7, R6, R7
    BRp NOT_LOWER
    LD R7, LOWER_CNT
    ADD R7, R7, #1
    ST R7, LOWER_CNT
    BR SKIP_CLASS
NOT_LOWER
    LD R7, SPACE
    NOT R7, R7
    ADD R7, R6, R7
    BRz IS_SPACE
    LD R7, ASCII_TAB
    NOT R7, R7
    ADD R7, R6, R7
    BRz IS_SPACE
    BR NOT_SPACE
IS_SPACE
    LD R7, SPACE_CNT
    ADD R7, R7, #1
    ST R7, SPACE_CNT
    BR SKIP_CLASS
NOT_SPACE
    LD R7, SYMBOL_CNT
    ADD R7, R7, #1
    ST R7, SYMBOL_CNT
SKIP_CLASS

    ; Increment frequency table
    LEA R7, FREQ_TABLE
    ADD R7, R7, R6          ; address = FREQ_TABLE + char
    LDR R5, R7, #0          ; current freq
    ADD R5, R5, #1          ; increment freq
    STR R5, R7, #0          ; store updated freq

SKIP_CHAR
    ADD R2, R2, #1
    BR CF_LOOP

CF_END
    RET

; ======================
; Subroutine: PRINT_FREQ
; Displays character and its frequency
; ======================
PRINT_FREQ
    LEA R1, FREQ_TABLE
    AND R2, R2, #0          ; i = 0

PF_LOOP
    LD R3, ASCII_127
    NOT R3, R3
    ADD R3, R2, R3
    BRzp PF_END             ; stop after 127 chars

    ADD R4, R1, R2
    LDR R5, R4, #0          ; FREQ[i]
    BRz SKIP_PRINT          ; skip if freq = 0

    ; Check if i is printable character (32-126)
    LD R3, SPACE
    NOT R3, R3
    ADD R3, R2, R3
    BRn SKIP_PRINT

    LD R3, ASCII_127
    NOT R3, R3
    ADD R3, R2, R3
    BRzp SKIP_PRINT

    AND R0, R0, #0
    ADD R0, R2, #0          ; ASCII char to R0
    OUT                     ; output character

    LD R0, COLON
    OUT
    LD R0, SPACE
    OUT

    ; print decimal value of R5
    AND R0, R0, #0
    ADD R0, R5, #0
    JSR PRINT_DECIMAL

    LD R0, NEWLINE
    OUT

SKIP_PRINT
    ADD R2, R2, #1
    BR PF_LOOP

PF_END
    RET

; ======================
; Subroutine: PRINT_STATS
; Print counts of categories
; ======================
PRINT_STATS
    LEA R0, STAT_MSG1
    PUTS
    LD R0, UPPER_CNT
    JSR PRINT_DECIMAL

    LEA R0, STAT_MSG2
    PUTS
    LD R0, LOWER_CNT
    JSR PRINT_DECIMAL

    LEA R0, STAT_MSG3
    PUTS
    LD R0, SPACE_CNT
    JSR PRINT_DECIMAL

    LEA R0, STAT_MSG4
    PUTS
    LD R0, SYMBOL_CNT
    JSR PRINT_DECIMAL

    LD R0, NEWLINE
    OUT
    RET

; ======================
; Subroutine: SAVE_REGS / RESTORE_REGS (unchanged)
; Subroutine: PRINT_DECIMAL (unchanged)
; Error Handler: OVERFLOW_ERR (unchanged)

; ======================
; Messages
; ======================
PROMPT         .STRINGZ "Please enter your full name: "
END_MSG        .STRINGZ "\nThank you for using the program."
OVERFLOW_MSG   .STRINGZ "\nError: Input exceeds 50 characters."
STAT_MSG1      .STRINGZ "\nUppercase letters: "
STAT_MSG2      .STRINGZ "\nLowercase letters: "
STAT_MSG3      .STRINGZ "\nWhitespace characters: "
STAT_MSG4      .STRINGZ "\nSymbol characters: "

