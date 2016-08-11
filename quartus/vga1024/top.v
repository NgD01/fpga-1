// Adapted from: www.TinyVGA.com

module top (
	input clk, // 50 MHz    
	output [2:0] red,    
	output [2:0] green,
	output [1:0] blue,
	output hsync, vsync     
);

reg [11:0] hcount;     // VGA horizontal counter
reg [10:0] vcount;     // VGA vertical counter
reg [7:0] data;		  // RGB data

wire hcount_ov, vcount_ov, video_active;

// VGA mode parameters
parameter
	hsync_end   = 12'd119,
   hdat_begin  = 12'd242,
   hdat_end    = 12'd1266,
   hpixel_end  = 12'd1345,
   vsync_end   = 11'd5,
   vdat_begin  = 11'd32,
   vdat_end    = 11'd632,
   vline_end   = 11'd665;

always @(posedge clk)
	if (hcount_ov)
		hcount <= 12'd0;
	else
		hcount <= hcount + 12'd1;
assign hcount_ov = hcount == hpixel_end;

always @(posedge clk)
	if (hcount_ov)
		if (vcount_ov)
			vcount <= 11'd0;
		else
			vcount <= vcount + 11'd1;
assign  vcount_ov = vcount == vline_end;

assign video_active = ((hcount >= hdat_begin) && (hcount < hdat_end))
                   && ((vcount >= vdat_begin) && (vcount < vdat_end));

assign hsync = hcount > hsync_end;
assign vsync = vcount > vsync_end;

assign red   = video_active ?  data[2:0] : 3'b0;      
assign green = video_active ?  data[5:3] : 3'b0;      
assign blue  = video_active ?  data[7:6] : 2'b0;      

// generate "image"
always @(posedge clk)
	data <= vcount[7:0] ^ hcount[7:0]; 

endmodule
