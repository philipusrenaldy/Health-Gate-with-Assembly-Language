ORG 00H
LCD	EQU P1			;Direktif untuk pin D0-D7 pada LCD yang dihubungkan pada port P1
ADC	EQU P2			;Direktif untuk pin DB0-DB7 pada ADC yang dihubungkan pada port P2
IR	BIT P3.0		;Direktif untuk pin OUT pada IR yang dihubungkan pada port P3.0
E	BIT P3.1		;Direktif untuk pin enable pada LCD yang dihubungkan pada port P3.1
RS	BIT P3.2		;Direktif untuk pin RS pada LCD yang dihubungkan pada port P3.2
RD_	BIT P3.3		;Direktif untuk pin RD' pada ADC yang dihubungkan pada port P3.3
WR_	BIT P3.4		;Direktif untuk pin WR' pada ADC yang dihubungkan pada port P3.4
INTR_	BIT P3.5		;Direktif untuk pin INTR' pada ADC yang dihubungkan pada port P3.5

LCDINIT	EQU 38H			;Direktif untuk mengatur LCD untuk menggunakan 2 baris dan matriks 5x7
LCDON	EQU 0CH			;Direktif untuk menghidupkan LCD
LCDINC	EQU 06H			;Direktif untuk mengatur cursor LCD ke mode increment
LCDCLR	EQU 01H			;Direktif untuk mengosongkan LCD
LCD1ST	EQU 80H			;Direktif untuk memindahkan cursor LCD ke baris pertama, kolom pertama
LCD2ND	EQU 0C0H		;Direktif untuk memindahkan cursor LCD ke baris kedua, kolom pertama

COUNT	EQU R0			;Direktif untuk menyimpan nilai count pada R0
TEMP	EQU R1			;Direktif untuk menyimpan nilai suhu pada R1
DIGIT1	EQU R2			;Direktif untuk menyimpan nilai digit puluhan suhu dalam ASCII pada R2
DIGIT2	EQU R3			;Direktif untuk menyimpan nilai digit satuan suhu dalam ASCII pada R3

START:	MOV TMOD, #01H		;Mengubah mode timer 0 menjadi mode 1 (16-bit timer)

	MOV A, #LCDINIT		;Mengatur LCD untuk menggunakan 2 baris dan matriks 5x7
	ACALL CMD
	MOV A, #LCDON		;Menghidupkan LCD
	ACALL CMD
	MOV A, #LCDINC		;Mengatur cursor LCD ke mode increment
	ACALL CMD

	MOV A, #LCDCLR		;Mengosongkan LCD
	ACALL CMD
	MOV A, #LCD1ST		;Memindahkan cursor LCD ke baris pertama, kolom pertama
	ACALL CMD

	MOV DPTR, #TEKSAWAL	;Menyalin isi dari TEKSAWAL ke DPTR
	ACALL DISP

NEXT:	MOV A, #LCD2ND		;Memindahkan cursor LCD ke baris kedua, kolom pertama
	ACALL CMD

	MOV DPTR, #TEKSAWAL2	;Menyalin isi dari TEKSAWAL2 ke DPTR
	ACALL DISP

CHECK:	JNB IR, CHECK		;Melanjutkan program apabila sensor IR mendeteksi gerakan

	MOV A, #LCDCLR		;Mengosongkan LCD
	ACALL CMD
	MOV A, #LCD1ST		;Memindahkan cursor LCD ke baris pertama, kolom pertama
	ACALL CMD

	ACALL FETCH

	MOV DPTR, #TEKS		;Menyalin isi dari TEKS ke DPTR
	ACALL DISP

PRINT:	MOV A, DIGIT1		;Menampilkan digit puluhan dari suhu ke LCD
	ACALL SEND
	MOV A, DIGIT2		;Menampilkan digit satuan dari suhu ke LCD
	ACALL SEND

	MOV DPTR, #TEKS2	;Menyalin isi dari TEKS2 ke DPTR
	ACALL DISP

CMP:	MOV A, #LCD2ND		;Memindahkan cursor LCD ke baris kedua, kolom pertama
	ACALL CMD
	MOV A, TEMP
	SUBB A, #38D
	JNC ALERT		;Menampilkan pesan sesuai dengan nilai suhu yang didapatkan

	MOV DPTR, #TEKSAMAN	;Menyalin isi dari TEKSAMAN ke DPTR
	ACALL DISP
	SJMP DONE

ALERT:	MOV DPTR, #TEKSAWAS	;Menyalin isi dari TEKSAWAS ke DPTR
	ACALL DISP

DONE:	SJMP DONE

;-------------------------------------------------------------------------------

;Procedure untuk mengirimkan perintah tertentu ke LCD
CMD:	MOV LCD, A
	CLR RS
	SETB E
	CLR E
	ACALL DELAY
	RET

;Procedure untuk menampilkan data ke LCD
SEND:	MOV LCD, A
	SETB RS
	SETB E
	CLR E
	ACALL DELAY
	RET

;Procedure untuk menampilkan pesan ke LCD sesuai dengan isi dari DPTR
DISP:	CLR A
	MOVC A, @A+DPTR
	JZ CONT
	ACALL SEND
	INC DPTR
	SJMP DISP
CONT:	RET

;Procedure delay menggunakan timer dengan durasi 1,64 ms
DELAY:	MOV TH0, #0F9H
	MOV TL0, #98H
	SETB TR0
WAIT:	JNB TF0, WAIT
	CLR TR0
	CLR TF0
	RET

;Procedure untuk mengambil nilai suhu dari sensor suhu
FETCH:	SETB RD_
	CLR WR_
	SETB WR_
HOLD:	JB INTR_, HOLD
	CLR RD_
	ACALL DELAY
	MOV A, ADC
	ACALL CONV
	RET

;Procedure untuk merubah nilai suhu menjadi nilai per digit dan dalam ASCII agar dapat ditampilkan pada LCD
CONV:	MOV TEMP, A
	MOV B, #10D
	DIV AB
	ADD A, #30H
	MOV 2, A
	MOV A, B
	ADD A, #30H
	MOV 3, A
	RET

ORG 100H
;Berbagai teks yang digunakan untuk pesan pada LCD
TEKSAWAL:	DB '      Halo! Silahkan lewati mesin', 0
TEKSAWAL2:	DB ' untuk melakukan pengecekan suhu tubuh', 0
TEKS:		DB '               Suhu: ', 0
TEKS2:		DB 223, 'C', 0
TEKSAMAN:	DB '    Anda tidak sakit. Berbahagialah!', 0
TEKSAWAS:	DB 'Anda tidak sehat. Segera check-up ke RS.', 0
END
