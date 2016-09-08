\ test code for SDRAM via the SPI peek device

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
