\ test code for BRAM/SRAM via the SPI peek device

reset
spi-init

\ %0000000001001100 SPI1-CR1 !  \ clk/4, i.e. 18 MHz, master (max supported)

: >fpga> ( u -- u )  \ exchange 32 bits with attached FPGA
  +spi
  dup 24 rshift >spi> 24 lshift swap
  dup 16 rshift >spi> 16 lshift swap
  dup  8 rshift >spi>  8 lshift swap
                >spi> or or or
  -spi ;

\ verify that data comes back when loopback is set
depth . $01234567 >fpga> hex. depth .
depth . $12345678 >fpga> hex. depth .

31 bit constant SR.REQ
 8 bit constant SR.WRn  \ will be lshifted 22 more

: sr-cycle ( data addr -- u )
  swap  22 lshift or
  dup SR.REQ or  >fpga> drop
                 >fpga> ;

: >sr ( data addr -- )  sr-cycle drop ;
: sr> ( addr -- data )  SR.WRn swap sr-cycle 22 rshift $FF and ;

$12 $43210 >sr  $43210 sr> h.2
$34 $54321 >sr  $54321 sr> h.2
        100 ms  $43210 sr> h.2
        100 ms  $54321 sr> h.2
: sr-timer micros $43210 sr> drop micros swap - . ;  \ about 19 µs @ 9 MHz
sr-timer
