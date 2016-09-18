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

   2048 constant BUF-SIZE
BUF-SIZE buffer: rdata

: fpga-init ( -- )  \ init NAND flash access
  nand-pins fpga-fsmc  $00 NAND-CMD c! ;

: fpga-write ( page addr -- )  \ write 2048 bytes to flash
  swap NAND-ADR h!
  BUF-SIZE 4 / 0 do  dup i cells + @  NAND !  loop  drop ;

: fpga-read ( page addr -- )  \ read 2048 bytes from flash
  swap NAND-ADR h!
  BUF-SIZE 4 / 0 do  NAND @  over i cells + !  loop  drop ;

: show
  cr  8  0 do  rdata i 2* + space h@ h.4  loop
  cr 17  8 do  rdata i 2* + space h@ h.4  loop ;

: adc-to-fpga ( -- )  \ transfer 1024 values from ADC to FPGA
  $00 NAND-ADR h!  1024 0 do  PC3 adc NAND h!  loop ;

\ pins used:
\   C2 A0 A2 A4 A6
\   C1 C3 A1 A3 A5
\
\ C3 = 1kΩ to A0, 1kΩ to A1, 1kΩ to A2, where: A0 = "0", A1 = PWM, A2 = "1"

: init-timer
  7200 PA1 +pwm  9000 PA1 pwm  \ set up timer 2 for 7200 Hz w/ 10% duty cycle
  OMODE-PP PA0 io-mode!  0 PA0 io!
  OMODE-PP PA2 io-mode!  1 PA2 io!
;

: test1
  init-timer
  fpga-init
  +adc
  begin
\   micros
    adc-to-fpga
    $00 rdata fpga-read  \ show
\   micros swap - . cr
    1000 ms
  key? until
;
\ test1

: test2
  init-timer
  fpga-init
  NAND 1024 PC2 2 adc1-dma
  5000 PA1 pwm  \ 50% PWM
  key drop
  0 bit DMA1-CCR1 bic!
;
\ test2
