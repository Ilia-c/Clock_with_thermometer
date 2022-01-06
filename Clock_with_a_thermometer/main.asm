.CSEG			; Кодовый сегмент
;=================================================
;=		Последовательности для вывода чисел	     =
;=================================================

.equ				Num1 = 0b0000110
.equ				Num2 = 0b1011011
.equ				Num3 = 0b1001111
.equ				Num4 = 0b1100110
.equ				Num5 = 0b1101101
.equ				Num6 = 0b1111101
.equ				Num7 = 0b0000111
.equ				Num8 = 0b1111111
.equ				Num9 = 0b1101111
.equ				Num0 = 0b0111111
.equ				Minu_s = 0b1000000
.equ				Empty_s = 0b0000000

;=================================================
;=				Вектора прерываний		         =
;=================================================

reset:
   rjmp start
   reti					; Addr $01
   rjmp Button			; Addr $02
   reti					; Addr $03
   reti					; Addr $04
   reti					; Addr $05
   rjmp Time_current	; Addr $06        
   reti					; Addr $07        
   reti					; Addr $08
   reti					; Addr $09
   reti					; Addr $0A
   reti					; Addr $0B        
   reti					; Addr $0C        
   reti					; Addr $0D        
   reti					; Addr $0E
   reti					; Addr $0F
   reti					; Addr $10
         
;=================================================
;=					Прерывыния		             =
;=================================================

Time_current:					; прерывание по сравнению таймера

			subi	r21, -1
			cpi		r21, 187
			BRLO exit_Time_current 
			subi	r19, -1	
			ldi r21, 0
exit_Time_current:
				ldi		r16, 0x00					
				out		TCNT0, r16	
				reti	

			

Button:							; прерывание по нажатию кнопки
			ldi r26, 0
			ldi r16, 0

			ldi r22, 0
			ldi r23, 0
			ldi r16, 0	
			Rcall Delay_01s
			ldi r22, 0
			ldi r23, 0
			ldi r16, 0	
			
			sbis	PINB, 1
			rjmp    wait
			rjmp    Second

			WAIT:				;Цикл ожидания, пока нажата кнопка
				subi	r18, -1				
				Rcall   Time_correct		
				Rcall	Number_send	
				ldi r22, 0
				ldi r23, 0
				ldi r16, 0	
				Rcall Delay_01s	; подпрограмма ожидания
				ldi r22, 0
				ldi r23, 0
				ldi r16, 0		

				sbis PINB, 1	;Если РВ1=1 (кнопка SB1 ;отпущена), пропустить след. ;строку
				rjmp WAIT		;иначе перейти к началу цикла ожидания
				ldi r26, 0
				ldi r16, 0
				rcall Delay_01s
				ldi r22, 0
				ldi r23, 0
				ldi r16, 0	
				reti
			Second:
				subi	r19, -1		
				Rcall   Time_correct		
				Rcall	Number_send		
				ldi r26, 0
				ldi r16, 0
				rcall Delay_01s
				ldi r22, 0
				ldi r23, 0
				ldi r16, 0	
				reti


;=================================================
;=			Инициализация программы		         =
;=================================================

Start:	
				cli
				RAM_Flush:				;инициализация flash
						LDI	ZL,Low(SRAM_START)
						LDI	ZH,High(SRAM_START)
						CLR	R16	
				Flush:					
						ST 	Z+,R16
						CPI	ZH,High(RAMEND+1)
						BRNE	Flush
						CPI	ZL,Low(RAMEND+1)
						BRNE	Flush
						CLR	ZL
						CLR	ZH
				LDI	ZL, 30	
				CLR	ZH
				DEC	ZL
				ST	Z, ZH
				BRNE	PC-2

				
				LDI R16,Low(RAMEND) ; Инициализация стека
				OUT SPL,R16		
									; Установка режима прерываний таймера
				clr r16
				ldi r16, (1<<OCIE0A)+(1<<TOIE0)  ; прерывание по                                                                                                                                             ;                                                                                                  ;переполнению и по сравнению
				out TIMSK0, r16
									; Устьановка делителя счетчика на 1024 
				ldi		r16, 0x00
				ldi		r16, (1<<CS00)|(0<<CS01)|(1<<CS02)
				out		TCCR0B,  r16		
				ldi		r16, 0x00
				ldi r16, 188		; значение прерывания таймером по сравнению
				out OCR0A, r16
				ldi r16, 0x00
				out TCNT0, r16 

				sbi     DDRB, PB0		; порт PB1 на передачу
				sbi     DDRB, PB2		; порт PB2 на передачу
			    sbi		DDRB, PB3		; порт PB3 на передачу

				ldi		r24, 0x40		; Регистр хранящий маску

				ldi		r18, 00			;	Регистр часов
				ldi		r19, 00			;	Регистр минут

				ldi		r21, 0			;	Регистр подсчета таймера
										; Регистр для отправки числа (Сюда; пишется,         то, что необходимо ;вывести 1/0)

				ldi		r22, 0	
				ldi		r23, 0			; Регистр подсчета операций
										; настройка прерываний по кнопке
				ldi r16, 2
				out PORTB, r16
				out PCMSK, r16
				ldi r16, (1<<PCIE)
				out GIMSK, r16

				ldi r27, 0
				rjmp Time_output
;=================================================
;=			    Основной цикл			         =
;=================================================

loop:
										; ожидание 15 секунд
				SEI
				ldi r28, 3
				wait_1:
					cycle_w0:
						subi r28, 1
						ldi r29, 10
						cpi r28, 2
						BRSH cycle_w1
						rjmp exsit_wait
					cycle_w1:
						subi r29, 1
						cpi r29, 2
						BRSH cycle_w2
						rjmp cycle_w0
					cycle_w2:
						ldi r22, 0
						ldi r23, 0
						ldi r16, 0
						Rcall Delay_01s
						ldi r22, 0
						ldi r23, 0
						ldi r16, 0	
						rjmp cycle_w1
exsit_wait:							; Выбор того, что выводить
				cpi r27, 1
				BREQ Temp_output		
				rjmp Time_output

				; Вывод времени
Time_output:
				ldi		r23, 0		
				Rcall   Time_correct
				Rcall	Number_send	
				ldi r23, 0
				ldi r26, 0

				ldi r27, 1
				rjmp loop
				; Считывание температуры и ее вывод
Temp_output:
				CLI

				mov r5, r18
				mov r6, r19

				ldi r16, 0x00 
				ldi r16,(1<<ADLAR)|(1<<MUX1)|(0<<MUX0)|(1<<REFS0)	;АЦП на 2й выход ацп
				out ADMUX,r16
				ldi r16,(1<<ADEN)|(1<<ADSC)|(0<<ADATE)|(0<<ADIE) ;АЦП на 2й выход ацп включение 1 преобр.
				out ADCSRA,r16 
				; Задержка для АЦП

				ldi r22, 0
				ldi r23, 0
				ldi r16, 0	
				Rcall Delay_01s
				ldi r22, 0
				ldi r23, 0
				ldi r16, 0	

				ldi r18, 99
				ldi r19, 99	
				Rcall	ADC_complete ; Преобразование полученных значений в температуру
				Rcall	Number_send	; Вывод температуры
				ldi r23, 0
				ldi r26, 0

				mov r18, r5
				mov r19, r6

				ldi r27, 0
				rjmp loop


;=================================================
;=			  Дополнительные подпрограмммы	     =
;=================================================		

Number_send:						; вывод чисел и символов в регистрах r18, r19
				cpi		r18, 255
				ldi		r16, 11
				breq	raz_1	
				
				ldi		r26, 0				
				mov		r16, r18			
				ldi		r17, 0	
						
repeat_1:
				cpi		r16, 10			; Сравнить регистры r16 и 10
				BRCS	raz_1			; Если R16 >= 10 перехода не будет
				subi	r16, 10			; вычесть из r16 10
				subi	r17, -1				
				rjmp	repeat_1				
raz_1:										
				mov		r11, r16							
				mov		r16, r19				
				ldi		r25, 0x00				
repeat_2:									
				cpi		r16, 10			; Сравнить регистры r19 и 10
				BRCS	raz_2			; Если R19 >= 10 перехода не будет
				subi	r16, 10			; вычесть из r18 10
				subi	r25, -1				
				rjmp	repeat_2			
raz_2:										
				mov		r13, r16										

						
Time_send_start:							
				cpi		r26, 0			; Сравнить регистры r26 и 0
				BREQ	T0				; Если r26 == 0, то переход

				cpi		r26, 1			; Сравнить регистры r26 и 1
				BREQ	T1	

				cpi		r26, 2			; Сравнить регистры r26 и 2
				BREQ	T2

				cpi		r26, 3			; Сравнить регистры r26 и 3
				BREQ	T3	

				ldi     r16, 4			;	защелка 1
				out		PORTB,r16				
				ldi     r16, 0			;	защелка 0
				out		PORTB,r16	
				Ret
T0:
				subi	r26, -1
				mov		r16, r13		; буфер для цифр
				rjmp	Select_num
T1:	
				RCALL	Miss

				subi	r26, -1
				mov		r16, r25		; буфер для цифр
				rjmp	Select_num
T2:
				RCALL	Miss
				subi	r26, -1
				mov		r16, r11		; буфер для цифр
				cpi		r18, 255
				breq	rav_1
				rjmp c_1
rav_1:
				ldi r17, 11
				mov r11, r17
				ldi r17, 12
c_1:
				rjmp	Select_num
T3:
				RCALL	Miss

				subi	r26, -1
				mov		r16, r17		; буфер для цифр
				cpi		r18, 255
				breq	rav_2
				rjmp c_2
rav_2:
				ldi r17, 11
				mov r11, r17
				ldi r17, 12
c_2:
				rjmp	Select_num


Load_current:
				mov		r9, r22
Continue:			
				mov		r22, r9				
				cpi		r23, 7		; Сравнить регистры r23 и 7
				BRCS	Next		; Если R23 >= 7 перехода не будет
				rjmp	Exit					
Next:											
				subi	R23, -1 										
				and		r22, r24					
				cp		r22, r24			; Сравнить r22 с r24
				breq	r22_r24				; Перейти если r22 == r24
				ldi		r22, 0					
				lsr		r24						
				rcall    Send
		
				rjmp	Continue								
r22_r24:										
				ldi		r22, 1					
				lsr		r24						
				;rjmp    Send
				rcall Send
				rjmp	Continue										

Exit:			
				ldi     r23, 0		
				ldi     r24, 0x40	
				ldi     r22, 0				
				rjmp    Time_send_start		

				; выбор символа или числа
Select_num:
				cpi		r16, 1	; Сравнить регистры r16 и 1
				breq	Number_1; Перейти если содержимое регистров совпадает

				cpi		r16, 2	; Сравнить регистры r16 и 2
				breq	Number_2; Перейти если содержимое регистров совпадает

				cpi		r16, 3	; Сравнить регистры r16 и 3
				breq	Number_3; Перейти если содержимое регистров совпадает

				cpi		r16, 4	; Сравнить регистры r16 и 4 
				breq	Number_4; Перейти если содержимое регистров совпадает

				cpi		r16, 5	; Сравнить регистры r16 и 5 
				breq	Number_5; Перейти если содержимое регистров совпадает

				cpi		r16, 6	; Сравнить регистры r16 и 6 
				breq	Number_6; Перейти если содержимое регистров совпадает

				cpi		r16, 7	; Сравнить регистры r16 и 7 
				breq	Number_7; Перейти если содержимое регистров совпадает

				cpi		r16, 8	; Сравнить регистры r16 и 8 
				breq	Number_8; Перейти если содержимое регистров совпадает

				cpi		r16, 9	; Сравнить регистры r16 и 9 
				breq	Number_9; Перейти если содержимое регистров совпадает
				
				cpi		r16, 11	; Сравнить регистры r16 и 9 
				breq	Minus   ; Перейти если содержимое регистров совпадает

				cpi		r16, 12	; Сравнить регистры r16 и 9 
				breq	Empty	; Перейти если содержимое регистров совпадает

				rjmp	Number_0

Number_1:
				ldi		r22, Num1
				rjmp	Load_current
Number_2:
				ldi		r22, Num2
				rjmp	Load_current
Number_3:
				ldi		r22, Num3
				rjmp	Load_current	
Number_4:
				ldi		r22, Num4
				rjmp	Load_current
Number_5:
				ldi		r22, Num5
				rjmp	Load_current	
Number_6:
				ldi		r22, Num6
				rjmp	Load_current
Number_7:
				ldi		r22, Num7
				rjmp	Load_current	
Number_8:
				ldi		r22, Num8
				rjmp	Load_current
Number_9:	
				ldi		r22, Num9	
				rjmp	Load_current
Number_0:
				ldi		r22, Num0	
				rjmp	Load_current
Minus:
				ldi		r22, Minu_s	
				rjmp	Load_current
Empty:
				ldi		r22, Empty_s	
				rjmp	Load_current


Miss: ; 2 такта на регистры (внешние)
				ldi     r16, 8 
				out		PORTB,r16
				ldi     r16, 0		
				out		PORTB,r16 
				ldi     r16, 8 
				out		PORTB,r16
				ldi     r16, 0		
				out		PORTB,r16 	
				Ret



Time_correct:
				cpi		r19, 60		; Сравнить регистры r19 и 60
				BRCS	After_set_minute	; Если R19 >= 60 перехода не будет
				ldi		r19, 0		; Если R19 >= 60 сброс счетчика минут
				subi	r18, -1				
After_set_minute:							
				cpi		r18, 24		; Сравнить регистры r18 и 24
				BRSH	reset_hour		; Если R18 >= 24 переход
				RJMP	After_set_hour		
reset_hour:									
				ldi		r18, 0		; Если R18 >= 24 сброс счетчика минут
After_set_hour:								
				Ret


				; Температура
ADC_complete:
				in r18, ADCH; Копирование в регистр r18 результата преобразования
				cpi r18, 21
				BRSH No_zero
				ldi r18, 255
				ldi r19, 99
				ret
No_zero:

				mov r16, r18
				ldi r23, 0
Dividing:
				cpi		r18, 10		; Сравнить регистры r18 и 10
				BRLO	Next_1			; Перейти если меньше 
				SUBI	r18, 10				
				SUBI	r23, -1					
				rjmp	Dividing				
Next_1:
				mov r1, r18						
				mov r22, r18			; остаток x/10
							
				add r18, r22					
				add r18, r22					
				add r18, r22

				mov r22, r23			; x/10

				ldi r23, 0
Dividing_2:
				cpi		r18, 10		; Сравнить регистры r18 и 10
				BRLO	Next_2			; Перейти если меньше 
				SUBI	r18, 10					
				SUBI	r23, -1				
				rjmp	Dividing_2			
Next_2:

				cpi		r18, 5	
				BRSH	Big						; >=
				rjmp	continue_after_big
Big:
				SUBI	r23, -1	
continue_after_big:
				
				mov r18, r23					; x/10


				add r18, r22
				add r18, r22
				add r18, r22
				add r18, r22					; x/10*5

				ldi r23, 0
				mov r23, r22

				add r22, r23
				add r22, r23


				mov r23, r1
				add r1, r23
				add r1, r23

				ldi r23, 0
				mov r16, r1


Dividing_3:
				cpi		r16, 10			; Сравнить регистры r16 и 10
				BRLO	Next_3				; Перейти если меньше 
				SUBI	r16, 10				
				SUBI	r23, -1				
				rjmp	Dividing_3			
Next_3:


				add r22, r23				
				ldi r23, 0					
				mov r16, r22				
Dividing_4:									
				cpi		r16, 10			; Сравнить регистры r16 и 10
				BRLO	Next_4				; Перейти если меньше 
				SUBI	r16, 10				
				SUBI	r23, -1				
				rjmp	Dividing_4			
Next_4:

				
				add	r18, r23

				cpi r18, 50
				BRSH plus
				ldi	r19, 50
				SUB r19, r18
				ldi r18, 255
				ldi r23, 0
				rjmp ADC_complete_exit

plus:
				subi r18, 50
				mov r19, r18
				ldi r18, 0
				ldi r23, 0
				rjmp ADC_complete_exit

ADC_complete_exit:
				ret

Delay_01s:
cicle_0:
				subi	r22, 1
				mov		r16, r23
				cpi		r22, 1
				BRSH	cicle_1
				rjmp exit_delay
cicle_1:
				subi	r16, 1
				cpi		r16, 1
				BRSH	cicle_2
				rjmp cicle_0
cicle_2:
				nop
				nop
				nop
				nop
				nop
				nop
				nop
				nop
				nop
				nop
				rjmp cicle_1
exit_delay:		
				ret







Send:
				CPI		r22, 1		; Сравниваем два значения
				BRCS	action_b		; когда r22>=r20 флага С не будет
								; Перехода не произойдет
action_a:							; r22 == 1
				ldi     r16, 1 ;1 0x10	
				out		PORTB,r16			
				ldi     r16, 9 ;9				
				out		PORTB,r16			
				RJMP	next_action			

action_b:							; r22 != 1
				ldi     r16, 0				
				out		PORTB,r16			
				ldi     r16, 8 ;8				
				out		PORTB,r16			
next_action: 	
				ret
		.ESEG			; Сегмент EEPROM



