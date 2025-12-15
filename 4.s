        AREA Module4, CODE, READONLY
        EXPORT Medicine_Scheduler

        IMPORT MED_INTERVAL_ARRAY
        IMPORT MED_LAST_ADMIN_ARRAY
        IMPORT DOSAGE_DUE_ARRAY
        IMPORT CURRENT_TIME_COUNTER

Medicine_Scheduler
        PUSH {R4-R8, LR}        ; Save registers
        MOV R4, #0              ; patient index
        MOV R8, #3              ; Hardcoded: 3 patients (instead of MAX_PATIENTS)

MedLoop
        CMP R4, R8
        BGE MedDone

        ; Load interval[i]
        LDR R0, =MED_INTERVAL_ARRAY
        LDR R5, [R0, R4, LSL #2]   ; dosage interval

        ; Load last_admin[i]
        LDR R1, =MED_LAST_ADMIN_ARRAY
        LDR R6, [R1, R4, LSL #2]   ; last administered timestamp

        ; Compute next_due = last + interval
        ADD R7, R6, R5

        ; Load current time
        LDR R0, =CURRENT_TIME_COUNTER
        LDR R0, [R0]

        ; Compare with next_due
        CMP R0, R7
        BLT NotDue

        ; Set DOSAGE_DUE flag
        LDR R2, =DOSAGE_DUE_ARRAY
        MOV R3, #1
        STRB R3, [R2, R4]
        
        ; IMPORTANT: Update last_admin to current time (medicine administered)
        STR R0, [R1, R4, LSL #2]
        B NextP

NotDue
        LDR R2, =DOSAGE_DUE_ARRAY
        MOV R3, #0
        STRB R3, [R2, R4]

NextP
        ADD R4, R4, #1
        B MedLoop

MedDone
        POP {R4-R8, LR}
        BX LR
        END
