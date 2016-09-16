\ send rapdily-captured-and-scaled ADC data to the FPGA

reset

: fpga-fsmc ( -- )
              0
   1 4 lshift or  \ PWID = 16 bit
        3 bit or  \ PTYP = NAND
    FSMC-PCR2 !
                 0
\    0 24 lshift or  \ MEMHIZ
     3 16 lshift or  \ MEMHOLD
      3 8 lshift or  \ MEMWAIT
\     0 0 lshift or  \ MEMSET
  dup FSMC-PMEM2 !
      FSMC-PATT2 !

  2 bit FSMC-PCR2 bis!  \ PBKEN = enabled
;

: fpga-init ( -- )  \ init NAND flash access
  nand-pins fpga-fsmc  $00 NAND-CMD c! ;

: fpga-write ( page addr -- )  \ write one 1024-byte flash page
  swap NAND-ADR h!
  256 0 do  dup i cells + @  NAND !  loop  drop ;

: fpga-read ( page addr -- )  \ read one 1024-byte flash page
  swap NAND-ADR h!
  256 0 do  NAND @  over i cells + !  loop  drop ;

1024 buffer: rdata

: show
  cr  8  0 do  rdata i 2* + space h@ h.4  loop
  cr 17  8 do  rdata i 2* + space h@ h.4  loop ;

: adc-to-fpga ( -- )  \ transfer 512 values from ADC to FPGA
  $00 NAND-ADR h!  512 0 do  PC3 adc NAND h!  loop ;

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

: test
  init-timer
  fpga-init
  +adc
  begin
    adc-to-fpga
    $00 rdata fpga-read  show
    1000 ms
  key? until
;
\ test
