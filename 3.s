        AREA Module3, CODE, READONLY
        EXPORT Vital_Alert_Handler

        IMPORT PATIENT_ARRAY
        IMPORT VITAL_INDEX
        IMPORT MAX_PATIENTS
        IMPORT ALERT_COUNT_ARRAY
        IMPORT ALERT_FLAG_ARRAY
        IMPORT ALERT_BUFFERS_BASE

; =================================================
; Vital_Alert_Handler
; =================================================
Vital_Alert_Handler
        PUSH {R4-R12, LR}

        MOV R4, #0                  ; patient index

AlertLoop
        CMP R4, #3                  ; process 3 patients
        BGE AlertDone

; -------------------------------------------------
; Calculate patient struct base
; R5 = &PATIENT_ARRAY[R4]
; -------------------------------------------------
        LDR R5, =PATIENT_ARRAY
        MOV R0, #44                 ; struct size
        MUL R1, R4, R0
        ADD R5, R5, R1

; -------------------------------------------------
; Load rolling vital index
; -------------------------------------------------
        LDR R6, =VITAL_INDEX
        LDRB R7, [R6, R4]           ; current write index (0–9)

        CMP R7, #10
        BGE NextPatient

; -------------------------------------------------
; Calculate latest index = current - 1 (wrap)
; -------------------------------------------------
        MOV R10, R7
        CMP R10, #0
        BNE idx_ok
        MOV R10, #9
        B idx_done
idx_ok
        SUB R10, R10, #1
idx_done

; -------------------------------------------------
; Load buffer pointers from patient struct
; -------------------------------------------------
        LDR R8,  [R5, #24]           ; HR buffer
        LDR R9,  [R5, #28]           ; BP buffer
        LDR R11, [R5, #32]           ; O2 buffer

        CMP R8, #0
        BEQ NextPatient
        CMP R9, #0
        BEQ NextPatient
        CMP R11, #0
        BEQ NextPatient

; -------------------------------------------------
; Load LATEST vitals
; -------------------------------------------------
        LDR R12, [R8,  R10, LSL #2]  ; HR
        LDR R2,  [R9,  R10, LSL #2]  ; BP (SBP)
        LDR R3,  [R11, R10, LSL #2]  ; O2

; -------------------------------------------------
; Check if already alerted ? avoid duplicates
; -------------------------------------------------
        LDR R0, =ALERT_FLAG_ARRAY
        LDRB R1, [R0, R4]
        CMP R1, #1
        BEQ NextPatient

; -------------------------------------------------
; Threshold checks
; -------------------------------------------------
        CMP R12, #120
        BGT RaiseAlert

        CMP R3, #92
        BLT RaiseAlert

        CMP R2, #160
        BGT RaiseAlert

        CMP R2, #90
        BLT RaiseAlert

; -------------------------------------------------
; Vitals normal ? clear alert flag
; -------------------------------------------------
        LDR R0, =ALERT_FLAG_ARRAY
        MOV R1, #0
        STRB R1, [R0, R4]
        B NextPatient

; =================================================
; RAISE ALERT
; =================================================
RaiseAlert
        PUSH {R5}

; -------------------------------------------------
; Set alert flag
; -------------------------------------------------
        LDR R0, =ALERT_FLAG_ARRAY
        MOV R1, #1
        STRB R1, [R0, R4]

; -------------------------------------------------
; Compute alert buffer base for patient
; -------------------------------------------------
        LDR R0, =ALERT_BUFFERS_BASE
        LDR R0, [R0]                ; base address

        MOV R1, #128
        MUL R14, R4, R1             ; per-patient alert space
        ADD R0, R0, R14             ; R0 = patient alert base

; -------------------------------------------------
; Get alert count
; -------------------------------------------------
        LDR R1, =ALERT_COUNT_ARRAY
        LDR R6, [R1, R4, LSL #2]

; -------------------------------------------------
; Compute alert record address
; -------------------------------------------------
        MOV R10, #16
        MUL R10, R6, R10
        ADD R10, R0, R10

; -------------------------------------------------
; Write 16-byte alert record
; -------------------------------------------------
        MOV R0, #1
        STRB R0, [R10, #0]           ; alert type

        STRB R12, [R10, #1]          ; HR (BYTE – safe)
        STRH R2,  [R10, #2]          ; BP
        STRB R3,  [R10, #4]          ; O2

        MOV R0, #0
        STR R0, [R10, #8]            ; timestamp (placeholder)

; -------------------------------------------------
; Increment alert count
; -------------------------------------------------
        ADD R6, R6, #1
        STR R6, [R1, R4, LSL #2]

        POP {R5}

NextPatient
        ADD R4, R4, #1
        B AlertLoop

AlertDone
        POP {R4-R12, PC}

        END
