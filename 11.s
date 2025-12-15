        AREA Module11, CODE, READONLY
        EXPORT Anomaly_Check_Handler

        IMPORT MAX_PATIENTS
        IMPORT HR_BUFFER
        IMPORT BP_BUFFER
        IMPORT O2_BUFFER
        IMPORT MED_INTERVAL_ARRAY
        IMPORT ERROR_FLAGS          ; Already exists in data.s (array of 3 bytes)
        IMPORT ERROR_FLASH_LOG
        IMPORT ERROR_LOG_INDEX
        IMPORT PATIENT_ARRAY
        IMPORT VITAL_INDEX

; ------------------------------
; Constants
; ------------------------------
SENSOR_STUCK     EQU 1
INVALID_DOSAGE   EQU 2
MEMORY_OVERFLOW  EQU 3

BUF_WORDS        EQU 10              ; 10 entries per buffer
REC_SIZE         EQU 16              ; 16-byte error record
FLASH_BLOCK      EQU 64              ; 64 bytes per patient (4 records max)
MEMORY_LIMIT     EQU 0x20001000      ; Upper memory boundary

; ------------------------------
; Entry Point
; ------------------------------
Anomaly_Check_Handler
        PUSH {R4-R11, LR}           ; Save registers like other modules

        MOV  R4, #0                  ; patient index
        LDR  R5, =MAX_PATIENTS
        LDR  R5, [R5]                ; Get patient count (should be 3)

patient_loop
        CMP  R4, R5
        BGE  handler_done

        ; -------- Check 1: Sensor stuck (same value in all 10 buffer slots) --------
        ; Calculate buffer offset for this patient: index * 40 bytes
        MOV  R6, #40                 ; 10 entries * 4 bytes
        MUL  R7, R4, R6

        ; Check HR buffer
        LDR  R0, =HR_BUFFER
        ADD  R0, R0, R7              ; HR buffer for this patient
        BL   check_sensor_stuck
        CMP  R0, #1
        BEQ  sensor_error

        ; Check BP buffer
        LDR  R0, =BP_BUFFER
        ADD  R0, R0, R7              ; BP buffer for this patient
        BL   check_sensor_stuck
        CMP  R0, #1
        BEQ  sensor_error

        ; Check O2 buffer
        LDR  R0, =O2_BUFFER
        ADD  R0, R0, R7              ; O2 buffer for this patient
        BL   check_sensor_stuck
        CMP  R0, #1
        BEQ  sensor_error

        ; -------- Check 2: Invalid medicine dosage (zero interval) --------
        LDR  R0, =MED_INTERVAL_ARRAY
        LDR  R1, [R0, R4, LSL #2]    ; Get medicine interval for this patient
        CMP  R1, #0
        BEQ  dosage_error

        ; -------- Check 3: Memory overflow (address above boundary) --------
        ; Check if patient struct is within memory bounds
        LDR  R0, =PATIENT_ARRAY
        MOV  R1, #44                 ; Patient struct size
        MUL  R1, R4, R1
        ADD  R0, R0, R1              ; R0 = &patient[i]
        LDR  R1, =MEMORY_LIMIT
        CMP  R0, R1
        BGT  memory_error

        ; Check if error flash log is within bounds
        LDR  R0, =ERROR_FLASH_LOG
        MOV  R1, #FLASH_BLOCK
        MUL  R1, R4, R1
        ADD  R0, R0, R1              ; R0 = error_log_base[i]
        ADD  R0, R0, #63             ; Check end of 64-byte block
        LDR  R1, =MEMORY_LIMIT
        CMP  R0, R1
        BGT  memory_error

        ; Check if vital buffers are within bounds
        LDR  R0, =HR_BUFFER
        ADD  R0, R0, R7              ; HR buffer start for this patient
        ADD  R0, R0, #39             ; Check end of 40-byte buffer
        LDR  R1, =MEMORY_LIMIT
        CMP  R0, R1
        BGT  memory_error

        ; All checks passed for this patient
        B    next_patient

; ------------------------------
; Error Handlers
; ------------------------------
sensor_error
        MOV  R0, #SENSOR_STUCK
        MOV  R1, R4                  ; patient index
        BL   handle_error
        B    next_patient

dosage_error
        MOV  R0, #INVALID_DOSAGE
        MOV  R1, R4
        BL   handle_error
        B    next_patient

memory_error
        MOV  R0, #MEMORY_OVERFLOW
        MOV  R1, R4
        BL   handle_error
        ; Continue to next patient

next_patient
        ADD  R4, R4, #1
        B    patient_loop

handler_done
        POP  {R4-R11, PC}

; ------------------------------
; Check if sensor is stuck (same value in all 10 buffer slots)
; Input: R0 = buffer address for this patient
; Output: R0 = 1 if sensor stuck, 0 if OK
; ------------------------------
check_sensor_stuck
        PUSH {R1-R5, LR}
        
        ; Load first value from buffer
        LDR  R1, [R0]                ; buffer[0]
        
        ; If first value is 0, check if ALL values are 0 (uninitialized)
        CMP  R1, #0
        BNE  check_all_same
        
        ; Check if entire buffer is zeros (uninitialized)
        MOV  R2, #0                  ; index
        
check_zero_loop
        CMP  R2, #BUF_WORDS
        BGE  all_zeros               ; All 10 positions are zero
        LDR  R3, [R0, R2, LSL #2]
        CMP  R3, #0
        BNE  not_stuck               ; Found non-zero value
        ADD  R2, R2, #1
        B    check_zero_loop
        
all_zeros
        ; Buffer is completely uninitialized (all zeros)
        ; Don't flag as sensor error - might be system just started
        MOV  R0, #0
        B    check_done
        
check_all_same
        ; Check if all 10 buffer positions have same non-zero value
        MOV  R2, #1                  ; start from index 1
        
check_same_loop
        CMP  R2, #BUF_WORDS
        BGE  sensor_stuck            ; All 10 positions have same value!
        LDR  R3, [R0, R2, LSL #2]    ; buffer[i]
        CMP  R3, R1                  ; Compare with first value
        BNE  not_stuck               ; Different value found
        ADD  R2, R2, #1
        B    check_same_loop
        
sensor_stuck
        ; All 10 buffer positions have identical non-zero value
        ; Sensor is stuck giving same reading for 10+ cycles
        MOV  R0, #1                  ; ERROR: sensor stuck
        B    check_done
        
not_stuck
        ; Values vary in buffer - sensor is working
        MOV  R0, #0                  ; OK
        
check_done
        POP  {R1-R5, PC}

; ------------------------------
; Handle Error - Set ERROR_FLAG and store in Flash
; Input: R0 = error code, R1 = patient index
; ------------------------------
handle_error
        PUSH {R2-R8, LR}

        ; ----- Set ERROR_FLAG for this patient -----
        LDR  R2, =ERROR_FLAGS
        ADD  R2, R2, R1              ; ERROR_FLAGS[patient_index]
        MOV  R3, #1
        STRB R3, [R2]                ; Set error flag (1 byte)

        ; ----- Store error record in Flash -----
        ; Get base address for this patient's error log
        LDR  R4, =ERROR_FLASH_LOG
        MOV  R5, #FLASH_BLOCK        ; 64 bytes per patient
        MUL  R5, R1, R5
        ADD  R4, R4, R5              ; R4 = base address for patient's error log

        ; Get current log index for this patient
        LDR  R5, =ERROR_LOG_INDEX
        LDR  R6, [R5, R1, LSL #2]    ; current record index (0-3)
        
        ; Check if we have space (max 4 records: 64 bytes / 16 bytes = 4)
        CMP  R6, #4
        BGE  log_full                ; Error log is full
        
        ; Calculate address for this error record
        MOV  R7, #REC_SIZE           ; 16 bytes per record
        MUL  R7, R6, R7
        ADD  R4, R4, R7              ; R4 = address to write this record

        ; ----- Write 16-byte error record -----
        ; Format: [error_code(4), patient_index(4), timestamp(8)]
        STR  R0, [R4, #0]            ; Store error code (4 bytes)
        STR  R1, [R4, #4]            ; Store patient index (4 bytes)
        
        ; Get current timestamp (use a simple counter)
        LDR  R7, =VITAL_INDEX        ; Using VITAL_INDEX as simple timer
        LDR  R7, [R7]                ; Load value (not ideal but simple)
        STR  R7, [R4, #8]            ; Store timestamp low (4 bytes)
        MOV  R7, #0
        STR  R7, [R4, #12]           ; Store timestamp high (4 bytes)

        ; Increment log index for next error
        ADD  R6, R6, #1
        STR  R6, [R5, R1, LSL #2]
        B    error_handled
        
log_full
        ; Error log is full - can't store more errors
        ; Could set a special flag or just ignore
        ; For now, we just don't store the error
        
error_handled
        POP  {R2-R8, PC}

        END
