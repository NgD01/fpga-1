\ test code for SDRAM via SPI peek, this runs full cycles over all addresses

spi-init

  %0000000001011100 SPI1-CR1 !  \ clk/16, i.e. 4.5 MHz, master
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
depth . $00FF0000 $12345678 >fpga> swap hex. hex. depth .

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

: sd-timer micros $543210 sd> drop micros swap - . ;  \ should take about 46 µs
sd-timer

24 bit constant TEST-SIZE  \ 22 = 4Mx16 (64 Mbit), 24 = 16Mx16 (256 Mbit)

: test-range ( leds -- hi lo )  24 lshift  dup TEST-SIZE or  swap ;

: zero-ram ( leds -- )
  test-range do
    0 i >sd
  loop ;

: fill-ram ( leds -- )
  test-range do
    i 1+ $FFFF and  i >sd
  loop ;

: zero-check ( leds -- )
  test-range do
    i sd>  $FFFF and  if cr i hex. i sd> hex. ." ?" then
  loop ;

: fill-check ( leds -- )
  test-range do
    i sd>  i 1+ - $FFFF and  if cr i hex. i sd> hex. ." ?" then
  loop ;

: test
  0  begin
    dup zero-ram    1+
    100 ms
    dup zero-check  1+
    dup fill-ram    1+
    1000 ms
    dup fill-check  1+
  key? until  drop ;

\ now launch tests manually - if everything is ok, the LEDs will show a counter
\ this is very slow: for 4M, each step takes about 3 min, 12 min per full cycle
\ the test is successful if the LEDs count is 4 or more with no serial messages
