\ test code for FSMC bus interface to FPGA

: fpga-fsmc ( -- )
              0
   1 4 lshift or  \ PWID = 16 bit
        3 bit or  \ PTYP = NAND
    FSMC-PCR2 !
                 0
\    0 24 lshift or  \ MEMHIZ = 2
     1 16 lshift or  \ MEMHOLD = 3
      2 8 lshift or  \ MEMWAIT = 4
\     0 0 lshift or  \ MEMSET = 2
  dup FSMC-PMEM2 !
      FSMC-PATT2 !

  2 bit FSMC-PCR2 bis!  \ PBKEN = enabled
;

: fpga-init ( -- )  \ init NAND flash access
  nand-pins fpga-fsmc  $00 NAND-CMD c!  $00 NAND-ADR c!  NAND h@ drop ;

: fpga-write ( page addr -- )  \ write one 512-byte flash page
  swap NAND-ADR h!
  16 0 do  dup i 2* + h@  NAND h!  loop  drop ;

: fpga-read ( page addr -- )  \ read one 512-byte flash page
  swap NAND-ADR h!  NAND h@ drop
  16 0 do  NAND h@  over i 2* + h!  loop  drop ;

fpga-init

512 buffer: rdata

: show
  cr  8  0 do  rdata i 2* + space h@ h.4  loop
  cr 17  8 do  rdata i 2* + space h@ h.4  loop ;

create wdata
hex
  1234 h, 4321 h, 5678 h, 8765 h, 2345 h, 5432 h, 6789 h, 9876 h,
  8080 h, 4040 h, 2020 h, 1010 h, 0808 h, 0404 h, 0202 h, 0101 h,
  1111 h, 2222 h, 3333 h, 4444 h, 5555 h, 6666 h, 7777 h, 8888 h,
decimal

$00 wdata      fpga-write  $00 rdata fpga-read  show
$40 wdata 16 + fpga-write  $40 rdata fpga-read  show
                           $00 rdata fpga-read  show
                           $40 rdata fpga-read  show
                           $80 rdata fpga-read  show

: timing ( n -- )  \ perform a timing test, reading 1000 words via the FSMC
  micros swap 0 do NAND h@ drop loop micros swap - . ;
\ currently returns 279 ns, of which 85 ns are loop overhead, i.e. ≈ 5 Mw/s
1000 timing
