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

Module10_Run
        PUSH {R4-R7, LR}          ; Save loop variables

        BL init_itm               ; Init ITM for debug

        ; Print header
        LDR R0, =title_str
        BL print_string
        LDR R0, =sep_str
        BL print_string

        MOV R4, #0                ; patient index
        MOV R5, #3                ; total patients
        LDR R6, =PATIENT_ARRAY    ; base of patient array
        LDR R7, =ALERT_COUNT_ARRAY ; base of alert count

patient_loop
        CMP R4, R5
        BGE patient_loop_end

        ; Calculate patient struct address safely
        MOV R0, R4
        MOV R1, #44
        MUL R8, R0, R1            ; R8 = offset
        ADD R8, R6, R8            ; R8 = patient address

        ; Call print function safely
        MOV R0, R8                ; patient address
        MOV R1, R4                ; patient index
        MOV R2, R7                ; alert array address
        BL print_patient_details

        ; Separator between patients
        CMP R4, #2
        BGE no_separator
        LDR R0, =sep_str
        BL print_string
no_separator

        ADD R4, R4, #1
        B patient_loop

patient_loop_end
        POP {R4-R7, PC}

