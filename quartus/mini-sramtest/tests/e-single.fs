\ test code for BRAM/SRAM via the SPI peek device

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

31 bit constant SD.REQ
 8 bit constant SD.WRn  \ will be lshifted 22 more

: sd-cycle ( data addr -- u )
  swap  22 lshift or
  dup SD.REQ or  >fpga> drop
                 >fpga> ;

: >sd ( data addr -- )  sd-cycle drop ;
: sd> ( addr -- data )  SD.WRn swap sd-cycle 22 rshift $FF and ;

$12 $43210 >sd  $43210 sd> h.2
$34 $54321 >sd  $54321 sd> h.2
        100 ms  $43210 sd> h.2
        100 ms  $54321 sd> h.2
: sd-timer micros $43210 sd> drop micros swap - . ;  \ about 19 µs @ 9 MHz
sd-timer
