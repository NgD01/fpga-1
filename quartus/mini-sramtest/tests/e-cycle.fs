\ test BRAM/SRAM via SPI peek, this runs full cycles over all addresses

spi-init

  %0000000001001100 SPI1-CR1 !  \ clk/4, i.e. 18 MHz, master (max supported)

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
  dup            >fpga> drop
  dup SR.REQ or  >fpga> drop
                 >fpga> ;

: >sr ( data addr -- )  sr-cycle drop ;
: sr> ( addr -- data )  SR.WRn swap sr-cycle 22 rshift $FF and ;

$12 $43210 >sr  $43210 sr> h.2
$34 $54321 >sr  $54321 sr> h.2
        100 ms  $43210 sr> h.2
        100 ms  $54321 sr> h.2
: sr-timer micros $43210 sr> drop micros swap - . ;  \ about 22 µs @ 18 MHz
sr-timer

19 bit constant TEST-SIZE  \ 14 = 16 KB, 19 = 512 KB, 21 = 2048 KB

: test-range ( leds -- hi lo )  3 and 20 lshift  dup TEST-SIZE or  swap ;
: test-value ( n -- u )  211 * 8 rshift $FF and ;

: zero-ram ( leds -- )
  test-range do
    0 i >sr
  loop ;

: fill-ram ( leds -- )
  test-range do
    i test-value  i >sr
  loop ;

: zero-check ( leds -- )
  test-range do
    i sr>  $FFFF and  if cr i hex. i sr> hex. ." ?" then
  loop ;

: fill-check ( leds -- )
  test-range do
    i sr>  i test-value - $FFFF and  if cr i hex. i sr> hex. ." ?" then
  loop ;

: test
  0  begin
    dup fill-ram    1+
    dup fill-check  1+
    dup zero-ram    1+
    dup zero-check  1+
  key? until  drop ;

\ now launch tests manually - if everything is ok, the LEDs will show a counter
\ this can be slow: for 4M, each step takes about 2 min - 8 min per full cycle
\ the test is successful if the LED count is 4 or more, with no serial messages
