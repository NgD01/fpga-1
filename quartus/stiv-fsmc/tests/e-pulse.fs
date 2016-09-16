\ generate a square wave of adjustable frequency

reset

\ pins used:
\   C2 A0 A2 A4 A6
\   C1 C3 A1 A3 A5
\
\ C3 = 1kΩ to A0, 1kΩ to A1, 1kΩ to A2, where: A0 = PWM, A1 = "0", A2 = "1"

: init-timer
  7200 PA0 +pwm  9000 PA0 pwm  \ set up timer 2 for 7200 Hz w/ 10% duty cycle
  OMODE-PP PA1 io-mode!  0 PA1 io!
  OMODE-PP PA2 io-mode!  1 PA2 io!
;

init-timer
