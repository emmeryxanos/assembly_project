




		AREA DataSection, DATA, READWRITE

        EXPORT MAX_PATIENTS
        EXPORT PATIENT_SIZE
        EXPORT BILL_SIZE
        EXPORT PATIENT_ARRAY
        EXPORT BILLING_ARRAY
        EXPORT TREATMENT_TABLE
        EXPORT HR_BUFFER
        EXPORT BP_BUFFER 
        EXPORT O2_BUFFER
        EXPORT VITAL_INDEX
        EXPORT HR_SENSORS
        EXPORT BP_SENSORS 
        EXPORT O2_SENSORS
        EXPORT STAY_DAYS
        EXPORT ALERT_COUNT_ARRAY
        EXPORT ALERT_BUFFERS_BASE
        EXPORT ALERT_RECORD_SIZE
        EXPORT ALERT_FLAG_ARRAY
        EXPORT LAB_TEST_COST    
        EXPORT ERROR_FLAGS   
        EXPORT CURRENT_TIME_COUNTER
        EXPORT MED_INTERVAL_ARRAY
        EXPORT MED_LAST_ADMIN_ARRAY
        EXPORT DOSAGE_DUE_ARRAY
		EXPORT RANDOM_IDS
        EXPORT RANDOM_AGES
        EXPORT RANDOM_WARDS
        EXPORT TREATMENT_CODES
        EXPORT ROOM_RATES
        EXPORT NameList
        EXPORT Name1
        EXPORT Name2
        EXPORT Name3
		EXPORT MedListPointers
        EXPORT ML1
        EXPORT ML2  
        EXPORT ML3
		EXPORT ERROR_FLASH_LOG   
        EXPORT ERROR_LOG_INDEX   

; Constants stored as memory words
MAX_PATIENTS    DCD 3
PATIENT_SIZE    DCD 44
BILL_SIZE       DCD 16

; Arrays
PATIENT_ARRAY   SPACE 44 * 3 
BILLING_ARRAY   SPACE 16 * 3

; Buffers
HR_BUFFER       SPACE 4 * 10 * 3   ; 120 bytes
BP_BUFFER       SPACE 4 * 10 * 3
O2_BUFFER       SPACE 4 * 10 * 3

VITAL_INDEX     SPACE 3            ; 1 byte per patient

ALERT_RECORD_SIZE   DCD 16         ; 16 bytes per alert record
ALERT_BUFFER_SPACE  SPACE 128 * 3  ; Allocate 384 bytes
ALERT_BUFFERS_BASE  DCD ALERT_BUFFER_SPACE
ALERT_COUNT_ARRAY   SPACE 4*3
ALERT_FLAG_ARRAY    SPACE 3

; Internal clock counter
CURRENT_TIME_COUNTER DCD 0

; Individual sensor readings for 3 patients
HR_SENSOR1 DCD 101
HR_SENSOR2 DCD 100
HR_SENSOR3 DCD 102

BP_SENSOR1 DCD 120
BP_SENSOR2 DCD 220
BP_SENSOR3 DCD 122

O2_SENSOR1 DCD 98
O2_SENSOR2 DCD 97
O2_SENSOR3 DCD 95

; Arrays of sensor addresses
HR_SENSORS DCD HR_SENSOR1, HR_SENSOR2, HR_SENSOR3
BP_SENSORS DCD BP_SENSOR1, BP_SENSOR2, BP_SENSOR3
O2_SENSORS DCD O2_SENSOR1, O2_SENSOR2, O2_SENSOR3

ERROR_FLAGS     SPACE 3
ERROR_FLASH_LOG   SPACE 192         ; 64 bytes × 3 patients
ERROR_LOG_INDEX   DCD 0, 0, 0       ; 4 bytes per patient (max 4 records)


; Lab test costs (32-bit per patient)
LAB_TEST_COST   DCD 2000, 3500, 1500

; Medicine scheduling
MED_INTERVAL_ARRAY      DCD 6, 8, 12
MED_LAST_ADMIN_ARRAY    DCD 0, 0, 0
DOSAGE_DUE_ARRAY        DCB 0, 0, 0

STAY_DAYS DCB 7, 15, 3

; Lookup table
TREATMENT_TABLE DCD 0,10000,15000,20000,25000

; ========================================
; INITIALIZATION DATA - MUST BE BEFORE END!
; ========================================

; Patient ID
RANDOM_IDS      DCD 143, 256, 187

; Age
RANDOM_AGES     DCB 19, 28, 23

; Ward Number
RANDOM_WARDS    DCW 12, 22, 7
                ALIGN 4  ; Important: align after DCW

; Treatment Code
TREATMENT_CODES DCB 2, 3, 1
                ALIGN 4  ; Align for safety

; Room Rate
ROOM_RATES      DCD 1500, 2300, 1800

; NAME LIST (pointers)
NameList        DCD Name1, Name2, Name3

Name1           DCB "RAIMA",0
                ALIGN 4
Name2           DCB "AYMAN",0
                ALIGN 4
Name3           DCB "TANVIR",0
                ALIGN 4

; MEDICINE LIST POINTERS
MedListPointers DCD ML1, ML2, ML3

; Fixed medicine data
ML1 DCD 500, 2, 300, 1, 0, 0      ; Patient 1: 2 medicines + terminator
ML2 DCD 800, 1, 400, 3, 0, 0      ; Patient 2: 2 medicines + terminator  
ML3 DCD 1500, 1, 0, 0, 0, 0       ; Patient 3: 1 medicine + terminator

        END
