        AREA Module8, CODE, READONLY
        EXPORT Calc_FinalBill
        IMPORT BILLING_ARRAY
        IMPORT LAB_TEST_COST    ; Array of lab costs
        IMPORT ERROR_FLAGS      ; Array of error flags

Calc_FinalBill
        PUSH {R4-R11, LR}        ; Save registers
        MOV R0, #0              ; patient index
        MOV R9, #3              ; Hardcoded: 3 patients

FinalLoop
        CMP R0, R9
        BGE FinalDone

        ; Clear error flag for this patient
        LDR R4, =ERROR_FLAGS
        MOV R5, #0
        STRB R5, [R4, R0]       ; error_flags[i] = 0

        ; Get billing[i] address (hardcoded size 16)
        LDR R1, =BILLING_ARRAY
        MOV R2, #16             ; Hardcoded billing struct size
        MUL R3, R0, R2
        ADD R1, R1, R3          ; R1 = &billing[i]

        ; Load bill components
        LDR R4, [R1, #0x00]     ; treatment cost
        LDR R5, [R1, #0x04]     ; room cost
        LDR R6, [R1, #0x08]     ; medicine cost

        ; Load lab test cost (array)
        LDR R7, =LAB_TEST_COST
        LDR R7, [R7, R0, LSL #2] ; lab_tests[i]

        ; Initialize accumulator
        MOV R8, #0

        ; Add with overflow checking
        ADDS R8, R8, R4         ; + treatment
        BVS SetError
        ADDS R8, R8, R5         ; + room
        BVS SetError
        ADDS R8, R8, R6         ; + medicine
        BVS SetError
        ADDS R8, R8, R7         ; + lab_tests
        BVS SetError

        ; Store final bill at offset 12
        STR R8, [R1, #0x0C]

        ; Next patient
        ADD R0, R0, #1
        B FinalLoop

SetError
        ; Set error flag
        LDR R4, =ERROR_FLAGS
        MOV R5, #1
        STRB R5, [R4, R0]       ; error_flags[i] = 1

        ; Store error value
        MOV R8, #0xFFFFFFFF
        STR R8, [R1, #0x0C]

        ; Next patient
        ADD R0, R0, #1
        B FinalLoop

FinalDone
        POP {R4-R11, LR}
        BX LR
        END
