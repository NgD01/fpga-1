\ test code for FSMC bus interface to FPGA

: fpga-fsmc ( -- )
              0
        3 bit or  \ PTYP = NAND
    FSMC-PCR2 !
                 0
     1 24 lshift or  \ MEMHIZ = 2
     2 16 lshift or  \ MEMHOLD = 3
      3 8 lshift or  \ MEMWAIT = 4
      1 0 lshift or  \ MEMSET = 2
  dup FSMC-PMEM2 !
      FSMC-PATT2 !

  2 bit FSMC-PCR2 bis!  \ PBKEN = enabled
;

: fpga-init ( -- )  \ init NAND flash access
  nand-pins fpga-fsmc  $00 NAND-CMD c!  $00 NAND-ADR c!  NAND c@ drop ;

: fpga-write ( page addr -- )  \ write one 512-byte flash page
  swap NAND-ADR h!  512 0 do  dup i + c@  NAND c!  loop  drop ;

: fpga-read ( page addr -- )  \ read one 512-byte flash page
  swap NAND-ADR h!  512 0 do  NAND c@  over i + c!  loop  drop ;

fpga-init

512 buffer: rdata

: show  12 0 do  rdata i 2* + h@ h.4 space  loop ;

create wdata
hex
  1234 h, 4321 h, 5678 h, 8765 h, 1111 h, 2222 h, 3333 h, 4444 h,
decimal

7 wdata fpga-write
7 rdata fpga-read

show
