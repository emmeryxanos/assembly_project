        AREA Module10_Code, CODE, READONLY
		EXPORT Module10_Run
		IMPORT PATIENT_ARRAY
		IMPORT ALERT_COUNT_ARRAY
		IMPORT VITAL_INDEX
		IMPORT BILLING_ARRAY
	    EXPORT init_itm
		EXPORT print_string
		EXPORT print_number
		EXPORT send_char
		EXPORT print_newline

; =================================================
; Constants
; =================================================
ITM_PORT0   EQU 0xE0000000
ITM_TCR     EQU 0xE0000E80
ITM_TER     EQU 0xE0000E00
ITM_TPR     EQU 0xE0000E40
ITM_LAR     EQU 0xE0000FB0

; =================================================
; Module10_Run - Main entry point
; =================================================
Module10_Run
    PUSH {R4-R11, LR}

    ; Initialize ITM for debug output
    BL init_itm

    ; Print header once
    LDR R0, =title_str
    BL print_string
    LDR R0, =sep_str
    BL print_string

    ; Loop through all 3 patients
    MOV R4, #0                  ; Patient index
    MOV R5, #3                  ; Total patients
    LDR R6, =PATIENT_ARRAY      ; Base address of array
    LDR R7, =ALERT_COUNT_ARRAY  ; Base address of alert counts

patient_loop
    CMP R4, R5
    BGE patient_loop_end

    ; Calculate patient address: R6 + (R4 * 44)
    MOV R0, R4
    MOV R1, #44
    MUL R8, R0, R1             ; R8 = index * 44
    ADD R8, R6, R8             ; R8 = current patient address

    ; Print this patient - SAVE LOOP REGISTERS!
    PUSH {R4-R8}                ; Save all loop variables
    MOV R0, R8                  ; Patient struct address
    MOV R1, R4                  ; Patient index
    MOV R2, R7                  ; Alert array address
    BL print_patient_details
    POP {R4-R8}                 ; Restore loop variables

    ; Add separator between patients
    CMP R4, #2                  ; Don't add after last patient
    BGE no_separator
    LDR R0, =sep_str
    BL print_string
no_separator

    ADD R4, R4, #1
    B patient_loop

patient_loop_end
    POP {R4-R11, PC}

; =================================================
; Print Patient Details
; Input: R0 = patient struct address
;        R1 = patient index
;        R2 = ALERT_COUNT_ARRAY address
; =================================================
print_patient_details
    PUSH {R4-R8, LR}
    MOV R4, R0          ; Save patient address
    MOV R5, R1          ; Save patient index
    MOV R6, R2          ; Save alert array address

    ; ----- ID -----
    LDR R0, =id_str
    BL print_string
    LDR R0, [R4, #0]    ; id at offset 0
    BL print_number
    BL print_newline

    ; ----- Name -----
    LDR R0, =name_str
    BL print_string
    LDR R0, [R4, #4]    ; name pointer at offset 4
    BL print_string
    BL print_newline

    ; ----- Age -----
    LDR R0, =age_str
    BL print_string
    LDRB R0, [R4, #8]   ; age at offset 8 (byte)
    BL print_number
    BL print_newline

    ; ----- Ward -----
    LDR R0, =ward_str
    BL print_string
    LDRH R0, [R4, #10]  ; ward at offset 10 (halfword)
    BL print_number
    BL print_newline

    ; ----- Heart Rate (latest) -----
    LDR R0, =hr_str
    BL print_string
    LDR R1, [R4, #24]   ; hr_history pointer at offset 24
    CMP R1, #0          ; Check if pointer is valid
    BEQ hr_invalid
    
    ; Get LATEST reading: read from (VITAL_INDEX - 1)
    LDR R2, =VITAL_INDEX
    LDRB R3, [R2, R5]    ; Current index (0-9)
    
    ; Calculate previous index (latest reading)
    CMP R3, #0
    BNE not_zero_hr
    MOV R3, #9           ; If index=0, wrap to last position (9)
    B calc_offset_hr
not_zero_hr
    SUB R3, R3, #1       ; Previous index = current - 1
calc_offset_hr
    LSL R3, R3, #2       ; Multiply by 4 (bytes per reading)
    
    ; Read HR at previous (latest) index
    LDR R0, [R1, R3]
    BL print_number
    B hr_done
hr_invalid
    LDR R0, =na_str     ; Print "N/A" if invalid
    BL print_string
hr_done
    BL print_newline

    ; ----- Blood Pressure (latest) -----
    LDR R0, =bp_str
    BL print_string
    LDR R1, [R4, #28]   ; bp_history pointer at offset 28
    CMP R1, #0          ; Check if pointer is valid
    BEQ bp_invalid
    
    ; Get LATEST reading (same logic as HR)
    LDR R2, =VITAL_INDEX
    LDRB R3, [R2, R5]    ; Current index
    
    ; Calculate previous index
    CMP R3, #0
    BNE not_zero_bp
    MOV R3, #9
    B calc_offset_bp
not_zero_bp
    SUB R3, R3, #1
calc_offset_bp
    LSL R3, R3, #2
    
    ; Read BP at latest index
    LDR R0, [R1, R3]
    BL print_number
    B bp_done
bp_invalid
    LDR R0, =na_str     ; Print "N/A" if invalid
    BL print_string
bp_done
    BL print_newline

    ; ----- Oxygen Level (latest) -----
    LDR R0, =o2_str
    BL print_string
    LDR R1, [R4, #32]   ; o2_history pointer at offset 32
    CMP R1, #0          ; Check if pointer is valid
    BEQ o2_invalid
    
    ; Get LATEST reading (same logic)
    LDR R2, =VITAL_INDEX
    LDRB R3, [R2, R5]    ; Current index
    
    ; Calculate previous index
    CMP R3, #0
    BNE not_zero_o2
    MOV R3, #9
    B calc_offset_o2
not_zero_o2
    SUB R3, R3, #1
calc_offset_o2
    LSL R3, R3, #2
    
    ; Read O2 at latest index
    LDR R0, [R1, R3]
    BL print_number
    B o2_done
o2_invalid
    LDR R0, =na_str     ; Print "N/A" if invalid
    BL print_string
o2_done
    BL print_newline

    ; ----- Alerts -----
    LDR R0, =alert_str
    BL print_string
    
    ; Save R5, R6 before calling print_number
    PUSH {R5, R6}
    ; Get alert count: alert_array[patient_index]
    LDR R0, [R6, R5, LSL #2]  ; R0 = alert_array[index * 4]
    BL print_number
    POP {R5, R6}               ; Restore R5, R6
    
    BL print_newline

    ; ----- Bill -----
    LDR R0, =bill_str
    BL print_string
    
    ; Get total bill from BILLING_ARRAY
    ; Save R5 before calculation
    PUSH {R5}
    LDR R0, =BILLING_ARRAY      ; Base of billing array
    MOV R1, #16                 ; Billing struct size = 16 bytes
    MUL R2, R5, R1              ; offset = patient_index * 16
    ADD R0, R0, R2              ; R0 = &billing[patient_index]
    LDR R0, [R0, #12]           ; Load total bill from offset 12
    POP {R5}                    ; Restore R5
    
    BL print_bill

    POP {R4-R8, PC}

; =================================================
; Print Bill as dollars.cents
; Input: R0 = amount in cents
; =================================================
print_bill
    PUSH {R4-R6, LR}
    MOV R4, R0          ; Save amount in cents
    
    ; Calculate dollars using divide_10 (for 100)
    MOV R0, R4
    MOV R1, #100
    BL divide_for_bill   ; R0 = dollars, R1 = cents
    MOV R5, R0          ; R5 = dollars
    MOV R6, R1          ; R6 = cents
    
    ; Print dollars
    MOV R0, R5
    BL print_number
    
    ; Print decimal point
    MOV R0, #'.'
    BL send_char
    
    ; Print cents (always 2 digits)
    CMP R6, #10
    BGE two_digits_cents
    
    ; Print leading zero
    MOV R0, #'0'
    BL send_char
    MOV R0, R6
    ADD R0, R0, #'0'
    BL send_char
    B bill_done
    
two_digits_cents
    ; Print 2-digit cents
    MOV R0, R6
    MOV R1, #10
    BL divide_10        ; R0 = tens, R1 = ones
    ADD R0, R0, #'0'
    BL send_char
    MOV R0, R1
    ADD R0, R0, #'0'
    BL send_char
    
bill_done
    BL print_newline
    POP {R4-R6, PC}

; Special division for bill (divide by 100)
divide_for_bill
    PUSH {R2}
    MOV R1, #0          ; Quotient counter
    MOV R2, R0          ; Save original
bill_div_loop
    CMP R2, #100
    BLT bill_div_done
    SUB R2, R2, #100
    ADD R1, R1, #1
    B bill_div_loop
bill_div_done
    MOV R0, R1          ; R0 = dollars (quotient)
    MOV R1, R2          ; R1 = cents (remainder)
    POP {R2}
    BX LR

; =================================================
; Divide by 10
; Input: R0 = number
; Output: R0 = quotient, R1 = remainder
; =================================================
divide_10
    PUSH {R2}
    MOV R1, #0          ; Quotient counter
    MOV R2, R0          ; Save original
div10_loop
    CMP R2, #10
    BLT div10_done
    SUB R2, R2, #10
    ADD R1, R1, #1
    B div10_loop
div10_done
    MOV R0, R1          ; R0 = quotient
    MOV R1, R2          ; R1 = remainder
    POP {R2}
    BX LR

; =================================================
; Print Number (0-999)
; Input: R0 = number
; =================================================
print_number
    PUSH {R4-R6, LR}
    MOV R4, R0          ; Save original number
    
    ; Check for 0
    CMP R4, #0
    BNE not_zero
    MOV R0, #'0'
    BL send_char
    B num_done
    
not_zero
    ; Check if 3 digits (100-999)
    CMP R4, #100
    BLT two_digit_check
    
    ; ----- Handle 3-digit numbers (100-999) -----
    ; Get hundreds digit
    MOV R0, R4
    MOV R1, #100
    BL divide_for_bill   ; R0 = hundreds, R1 = remainder
    MOV R5, R0          ; R5 = hundreds digit (1-9)
    MOV R6, R1          ; R6 = remainder (0-99)
    
    ; Print hundreds digit
    ADD R0, R5, #'0'
    BL send_char
    
    ; Now handle remainder (0-99) as 2-digit number
    MOV R0, R6
    CMP R0, #10
    BLT less_than_10_after_hundreds
    
    ; Remainder = 10, print as 2-digit
    MOV R1, #10
    BL divide_10        ; R0 = tens, R1 = ones
    ADD R0, R0, #'0'
    BL send_char
    MOV R0, R1
    ADD R0, R0, #'0'
    BL send_char
    B num_done
    
less_than_10_after_hundreds
    ; Print "0" then the single digit
    MOV R0, #'0'
    BL send_char
    MOV R0, R6
    ADD R0, R0, #'0'
    BL send_char
    B num_done
    
two_digit_check
    ; Check if 2 digits (10-99)
    CMP R4, #10
    BLT one_digit
    
    ; ----- Handle 2-digit numbers (10-99) -----
    MOV R0, R4
    MOV R1, #10
    BL divide_10        ; R0 = tens, R1 = ones
    ADD R0, R0, #'0'
    BL send_char
    MOV R0, R1
    ADD R0, R0, #'0'
    BL send_char
    B num_done
    
one_digit
    ; ----- Handle 1-digit numbers (0-9) -----
    MOV R0, R4
    ADD R0, R0, #'0'
    BL send_char
    
num_done
    POP {R4-R6, PC}

; =================================================
; ITM Initialization
; =================================================
init_itm
    PUSH {R0-R1, LR}
    LDR R0, =ITM_LAR
    LDR R1, =0xC5ACCE55
    STR R1, [R0]

    LDR R0, =ITM_TCR
    MOV R1, #1
    STR R1, [R0]

    LDR R0, =ITM_TER
    MOV R1, #1
    STR R1, [R0]

    LDR R0, =ITM_TPR
    MOV R1, #0
    STR R1, [R0]
    POP {R0-R1, PC}

; =================================================
; Print String
; Input: R0 = string pointer
; =================================================
print_string
    PUSH {R1, LR}
    MOV R1, R0
ps_loop
    LDRB R0, [R1], #1
    CMP R0, #0
    BEQ ps_done
    BL send_char
    B ps_loop
ps_done
    POP {R1, PC}

; =================================================
; Print Newline
; =================================================
print_newline
    PUSH {LR}
    MOV R0, #'\r'
    BL send_char
    MOV R0, #'\n'
    BL send_char
    POP {PC}

; =================================================
; Send Character to ITM
; Input: R0 = character
; =================================================
send_char
    PUSH {R1-R2, LR}
    LDR R1, =ITM_PORT0
    
    ; Wait for FIFO ready
wait_loop
    LDR R2, =0xE0000E00  ; ITM TER
    LDR R2, [R2]
    TST R2, #1           ; Check port 0 enabled
    BEQ wait_loop
    
    STR R0, [R1]
    POP {R1-R2, PC}

; =================================================
; String Data (placed in literal pool)
; =================================================
    LTORG

title_str   DCB "\r\nICU PATIENT SUMMARY\r\n", 0
sep_str     DCB "----------------------\r\n", 0
id_str      DCB "ID: ", 0
name_str    DCB "Name: ", 0
age_str     DCB "Age: ", 0
ward_str    DCB "Ward: ", 0
hr_str      DCB "HR: ", 0
bp_str      DCB "BP: ", 0
o2_str      DCB "O2: ", 0
alert_str   DCB "Alerts: ", 0
bill_str    DCB "Bill: $", 0
na_str      DCB "N/A", 0

    END
