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

\ wire [63:0] ins = {
\     sdram_ack,          // 63
\     sdram_data_r_en,    // 62
\     14'b0,
\     sdram_data_r,       // 47:32
\     32'b1
\ };
\ 
\ wire [63:0] outs;
\ assign sdram_req    = outs[63];
\ assign sdram_rh_wl  = outs[62];
\ assign led          = outs[55:48];
\ assign sdram_data_w = outs[47:32];
\ assign sdram_addr   = outs[23:0];

0 variable sd-w
0 variable sd-a

: sd-cycle ( data addr -- u )
  2over                >fpga> 2drop
  over 31 bit or over  >fpga> 2drop
                       >fpga> drop ;

: >sd ( data addr -- )  sd-cycle drop ;
: sd> ( addr -- data )  30 bit swap sd-cycle ;

$1234 $543210 >sd  $543210 sd> hex.
$0123 $054321 >sd  $054321 sd> hex.
