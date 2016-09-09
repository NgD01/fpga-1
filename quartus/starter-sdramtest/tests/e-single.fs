\ test code for SDRAM via the SPI peek device

spi-init

\ %0000000001001100 SPI1-CR1 !  \ clk/4, i.e. 18 MHz, master (max supported)

: >f32> ( u -- u )
  dup 24 rshift >spi> 24 lshift swap
  dup 16 rshift >spi> 16 lshift swap
  dup  8 rshift >spi>  8 lshift swap
                >spi> or or or ;

: >fpga> ( u2 -- u2 )  \ exchange 64 bits with attached FPGA
  swap +spi >f32> swap >f32> -spi ;

\ verify that data comes back when loopback is set
depth . $01234567 $89ABCDEF >fpga> swap hex. hex. depth .
depth . $12345678 $FF000000 >fpga> swap hex. hex. depth .

31 bit constant SD.REQ
30 bit constant SD.WRn

: sd-cycle ( data addr -- u )
\ 2over                >fpga> 2drop
  over SD.REQ or over  >fpga> 2drop
                       >fpga> drop ;

: >sd ( data addr -- )  sd-cycle drop ;
: sd> ( addr -- data )  SD.WRn swap sd-cycle ;

$1234 $543210 >sd  $543210 sd> hex.
$0123 $054321 >sd  $054321 sd> hex.
           100 ms  $543210 sd> hex.
           100 ms  $054321 sd> hex.

: sd-timer micros $543210 sd> drop micros swap - . ;  \ about 34 µs @ 9 MHz
sd-timer
