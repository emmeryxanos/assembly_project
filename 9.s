	    AREA Module9, CODE, READONLY
        EXPORT Sort_By_Alerts

        IMPORT PATIENT_ARRAY
        IMPORT ALERT_COUNT_ARRAY
        IMPORT STAY_DAYS
        IMPORT ERROR_FLAGS
        IMPORT ALERT_FLAG_ARRAY
        IMPORT BILLING_ARRAY
        IMPORT LAB_TEST_COST
        IMPORT VITAL_INDEX


; Sort_By_Alerts
; Bubble sort by ALERT_COUNT (descending)
; MAX_PATIENTS = 3
; PATIENT_SIZE = 44 bytes


Sort_By_Alerts
        PUSH {R4-R11, LR}

        ; Load base addresses
        LDR R4, =PATIENT_ARRAY
        LDR R5, =ALERT_COUNT_ARRAY
        LDR R6, =STAY_DAYS
        LDR R7, =ERROR_FLAGS
        LDR R8, =ALERT_FLAG_ARRAY
        LDR R9, =BILLING_ARRAY
        LDR R10, =LAB_TEST_COST
        LDR R11, =VITAL_INDEX

        MOV R0, #0              ; i = 0 (outer loop)

outer_loop
        CMP R0, #2              ; i < MAX-1
        BGE sort_done

        MOV R1, #0              ; j = 0
        MOV R2, #2
        SUB R2, R2, R0          ; limit = 2 - i

inner_loop
        CMP R1, R2
        BGE next_pass

        ; Compare ALERT_COUNT[j] and ALERT_COUNT[j+1]
        LDR R12, [R5, R1, LSL #2]   ; alert[j]
        ADD R14, R1, #1             ; j+1
        LDR R3,  [R5, R14, LSL #2]  ; alert[j+1]

        CMP R12, R3
        BGE no_swap

        ; Swap patients at indices R1 and R14
        PUSH {R0-R3, R12, R14}      ; Save all loop variables
        MOV R0, R1                  ; index_a = j
        MOV R1, R14                 ; index_b = j+1
        BL swap_patients_helper
        POP {R0-R3, R12, R14}       ; Restore loop variables

no_swap
        ADD R1, R1, #1
        B inner_loop

next_pass
        ADD R0, R0, #1
        B outer_loop

sort_done
        POP {R4-R11, LR}
        BX LR

; =====================================================
; Helper function: swap_patients_helper
; Input: R0 = index_a, R1 = index_b
; Uses: R2, R3, R12, R14 as temporaries
; Preserves: R4-R11 (array base addresses)
; =====================================================
swap_patients_helper
        PUSH {R4-R11, LR}       ; Save base addresses and LR

        ; Reload base addresses (they might be corrupted by caller)
        LDR R4, =PATIENT_ARRAY
        LDR R5, =ALERT_COUNT_ARRAY
        LDR R6, =STAY_DAYS
        LDR R7, =ERROR_FLAGS
        LDR R8, =ALERT_FLAG_ARRAY
        LDR R9, =BILLING_ARRAY
        LDR R10, =LAB_TEST_COST
        LDR R11, =VITAL_INDEX

        ; Save indices
        MOV R2, R0              ; R2 = index_a
        MOV R3, R1              ; R3 = index_b

; SWAP ALERT_COUNT 
        LDR R12, [R5, R2, LSL #2]   ; alert[index_a]
        LDR R14, [R5, R3, LSL #2]   ; alert[index_b]
        STR R14, [R5, R2, LSL #2]
        STR R12, [R5, R3, LSL #2]

; SWAP STAY_DAYS 
        LDRB R12, [R6, R2]
        LDRB R14, [R6, R3]
        STRB R14, [R6, R2]
        STRB R12, [R6, R3]

; SWAP ERROR_FLAGS 
        LDRB R12, [R7, R2]
        LDRB R14, [R7, R3]
        STRB R14, [R7, R2]
        STRB R12, [R7, R3]

; SWAP ALERT_FLAG_ARRAY 
        LDRB R12, [R8, R2]
        LDRB R14, [R8, R3]
        STRB R14, [R8, R2]
        STRB R12, [R8, R3]

;  SWAP VITAL_INDEX 
        LDRB R12, [R11, R2]
        LDRB R14, [R11, R3]
        STRB R14, [R11, R2]
        STRB R12, [R11, R3]

; SWAP LAB_TEST_COST 
        LDR R12, [R10, R2, LSL #2]
        LDR R14, [R10, R3, LSL #2]
        STR R14, [R10, R2, LSL #2]
        STR R12, [R10, R3, LSL #2]

; SWAP BILLING_ARRAY (16 bytes) 
        MOV R12, #16
        MUL R14, R2, R12
        ADD R14, R9, R14        ; billing[index_a]

        MUL R12, R3, R12
        ADD R12, R9, R12        ; billing[index_b]

        ; Swap 4 words (16 bytes)
        LDR R0, [R14]
        LDR R1, [R12]
        STR R1, [R14]
        STR R0, [R12]

        LDR R0, [R14, #4]
        LDR R1, [R12, #4]
        STR R1, [R14, #4]
        STR R0, [R12, #4]

        LDR R0, [R14, #8]
        LDR R1, [R12, #8]
        STR R1, [R14, #8]
        STR R0, [R12, #8]

        LDR R0, [R14, #12]
        LDR R1, [R12, #12]
        STR R1, [R14, #12]
        STR R0, [R12, #12]

;  SWAP PATIENT STRUCT (44 bytes) 
        MOV R12, #44
        MUL R14, R2, R12
        ADD R14, R4, R14        ; patient[index_a]

        MUL R12, R3, R12
        ADD R12, R4, R12        ; patient[index_b]

        ; Swap 11 words (44 bytes)
        MOV R0, #11             ; word counter

patient_swap_loop
        LDR R1, [R14]           ; temp = patient_a[word]
        LDR R2, [R12]           ; load patient_b[word]
        STR R2, [R14], #4       ; patient_a[word] = patient_b[word]
        STR R1, [R12], #4       ; patient_b[word] = temp
        SUBS R0, R0, #1
        BNE patient_swap_loop

        POP {R4-R11, PC}        ; Return from helper

        END
