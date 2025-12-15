        AREA Module5, CODE, READONLY
        EXPORT Calc_TreatCost
        IMPORT PATIENT_ARRAY
        IMPORT BILLING_ARRAY
        IMPORT TREATMENT_TABLE
        IMPORT MAX_PATIENTS

Calc_TreatCost
        PUSH {R4-R11, LR}
        
        MOV R0, #0                  ; patient index
        MOV R10, #3
        
TreatLoop
        CMP R0, R10
        BGE TreatDone
        
        ; ----- PATIENT ADDRESS -----
        LDR R1, =PATIENT_ARRAY
        MOV R2, #44
        MUL R3, R0, R2              ; R3 = patient offset
        ADD R1, R1, R3              ; R1 = &patient[i] ? SAVE THIS!
        
        ; ----- READ TREATMENT CODE -----
        LDRB R4, [R1, #12]          ; offset 12
        
        ; ----- GET COST FROM TABLE -----
        LSL R5, R4, #2              ; code * 4
        LDR R6, =TREATMENT_TABLE
        LDR R7, [R6, R5]            ; cost
        
        ; ----- BILLING ADDRESS -----
        LDR R8, =BILLING_ARRAY
        MOV R9, #16
        MUL R11, R0, R9             ; ? USE R11, NOT R3!
        ADD R8, R8, R11             ; R8 = &billing[i]
        
        ; ----- STORE COST -----
        STR R7, [R8, #0]
        
        ADD R0, R0, #1
        B TreatLoop

TreatDone
        POP {R4-R11, LR}
        BX LR
