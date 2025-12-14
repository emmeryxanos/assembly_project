		AREA Module6, CODE, READONLY
        EXPORT Calc_RoomRent
        IMPORT PATIENT_ARRAY
        IMPORT BILLING_ARRAY
        IMPORT STAY_DAYS

Calc_RoomRent
        PUSH {R4-R10, LR}
        MOV R0, #0                ; patient index
        MOV R10, #3               ; Hardcoded: 3 patients

RoomLoop
        CMP R0, R10
        BGE RoomDone

        ; ----- GET PATIENT[i] ADDRESS -----
        ; Address = PATIENT_ARRAY + (index * 44) - HARDCODED
        LDR R1, =PATIENT_ARRAY    ; Base address
        MOV R2, #44               ; HARDCODED patient struct size
        MUL R3, R0, R2
        ADD R1, R1, R3            ; R1 = &patient[i]

        ; ----- READ DAILY ROOM RATE -----
        ; Offset 16 (0x10) in patient struct
        LDR R4, [R1, #0x10]       ; R4 = daily room rate

        ; ----- READ STAY-DAYS -----
        LDR R5, =STAY_DAYS
        LDRB R6, [R5, R0]         ; R6 = stay_days[i]

        ; ----- COMPUTE: room_cost = rate × days -----
        MUL R7, R4, R6            ; R7 = base room cost

        ; ----- CHECK FOR 5% DISCOUNT (days > 10) -----
        CMP R6, #10
        BLE NoDiscount

        ; Apply 5% discount: cost - (cost ÷ 20)
        MOV R8, #20
        UDIV R9, R7, R8           ; R9 = cost ÷ 20
        SUB R7, R7, R9            ; R7 = cost - 5%

NoDiscount
        ; ----- GET BILLING[i] ADDRESS -----
        ; Address = BILLING_ARRAY + (index * 16) - HARDCODED
        LDR R8, =BILLING_ARRAY
        MOV R9, #16               ; HARDCODED billing struct size
        MUL R3, R0, R9
        ADD R8, R8, R3            ; R8 = &billing[i]

        ; ----- STORE ROOM COST AT OFFSET 4 -----
        STR R7, [R8, #0x04]

        ; Next patient
        ADD R0, R0, #1
        B RoomLoop

RoomDone
        POP {R4-R10, LR}
        BX LR
        END
