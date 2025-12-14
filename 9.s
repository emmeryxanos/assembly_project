		AREA Module9, CODE, READONLY
		EXPORT Sort_By_Alerts

		IMPORT PATIENT_ARRAY
		IMPORT ALERT_COUNT_ARRAY
		IMPORT MAX_PATIENTS
		IMPORT PATIENT_SIZE

; =====================================================
; Sort_By_Alerts
; Bubble sort patients by alert count (descending)
; =====================================================
Sort_By_Alerts
    PUSH {R0-R12, LR}

    ; Load constants
    LDR R0, =PATIENT_ARRAY          ; Patient structs base
    LDR R1, =ALERT_COUNT_ARRAY      ; Alert counts
    MOV R2, #3                      ; 3 patients (hardcoded)
    MOV R3, #44                     ; Patient struct size = 44 bytes

    ; Bubble sort for 3 patients
    MOV R4, #0                      ; pass counter

outer_loop
    CMP R4, #2                      ; passes < 2?
    BGE sort_done

    MOV R5, #0                      ; j = 0
    MOV R6, #2                      ; N-1 = 2
    SUB R6, R6, R4                  ; limit = N-1-pass

inner_loop
    CMP R5, R6
    BGE next_pass

    ; Load alert counts for comparison
    LDR R7, [R1, R5, LSL #2]        ; alert[j]
    ADD R8, R5, #1
    LDR R9, [R1, R8, LSL #2]        ; alert[j+1]

    ; Compare: if alert[j] >= alert[j+1], no swap (descending order)
    CMP R7, R9
    BGE no_swap

    ; ========== SWAP ALERT COUNTS FIRST ==========
    STR R9, [R1, R5, LSL #2]        ; alert[j] = old alert[j+1]
    STR R7, [R1, R8, LSL #2]        ; alert[j+1] = old alert[j]

    ; ========== SWAP PATIENT STRUCTS ==========
    ; Calculate addresses of patient j and j+1
    MOV R10, R5
    MUL R10, R10, R3                ; offset_j = j * 44
    ADD R10, R0, R10                ; addr_j = base + offset_j
    
    MOV R11, R8
    MUL R11, R11, R3                ; offset_j1 = (j+1) * 44
    ADD R11, R0, R11                ; addr_j1 = base + offset_j1

    ; Swap 11 words (44 bytes)
    MOV R12, #11                    ; word counter

swap_loop
    LDR R14, [R10]                  ; temp = struct_j[word]
    LDR R7,  [R11]                  ; load struct_j1[word]
    
    STR R7,  [R10], #4              ; struct_j[word] = struct_j1[word]
    STR R14, [R11], #4              ; struct_j1[word] = temp
    
    SUBS R12, R12, #1
    BNE swap_loop

no_swap
    ADD R5, R5, #1                  ; j++
    B inner_loop

next_pass
    ADD R4, R4, #1                  ; pass++
    B outer_loop

sort_done
    POP {R0-R12, PC}
    END
