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
\ C3 = 1kΩ to A0, 1kΩ to A1, 1kΩ to A2, where: A0 = PWM, A1 = "0", A2 = "1"

: init-timer
  7200 PA0 +pwm  9000 PA0 pwm  \ set up timer 2 for 7200 Hz w/ 10% duty cycle
  OMODE-PP PA1 io-mode!  0 PA1 io!
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

: adc1-dma2 ( addr count pin rate -- )  \ continuous DMA-based conversion
  3 +timer        \ set the ADC trigger rate using timer 3
  +adc  adc drop  \ perform one conversion to set up the ADC
  2dup 0 fill     \ clear sampling buffer

    0 bit RCC-AHBENR bis!  \ DMA1EN clock enable
      2/ DMA1-CNDTR1 !     \ 2-byte entries
          DMA1-CMAR1 !     \ write to address passed as input
  ADC1-DR DMA1-CPAR1 !     \ read from ADC1

                0   \ register settings for CCR1 of DMA1:
  %01 10 lshift or  \ MSIZE = 16-bits
   %01 8 lshift or  \ PSIZE = 16 bits
          7 bit or  \ MINC
          5 bit or  \ CIRC
                    \ DIR = from peripheral to mem
          0 bit or  \ EN
      DMA1-CCR1 !

                 0   \ ADC1 triggers on timer 3 and feeds DMA1:
          23 bit or  \ TSVREFE
          20 bit or  \ EXTTRIG
  %100 17 lshift or  \ timer 3 TRGO event
           8 bit or  \ DMA
           0 bit or  \ ADON
        ADC1-CR2 ! ;

: test2
  init-timer
  fpga-init
  NAND 1024 PC3 2 adc1-dma
  key drop
  0 bit DMA1-CCR1 bic!
;
\ test2
