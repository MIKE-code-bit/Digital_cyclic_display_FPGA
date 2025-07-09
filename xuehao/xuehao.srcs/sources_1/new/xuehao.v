module x7_4bit(
input clk,
input rst_n,
input [15:0] x,      //等待显示的BCD码
output reg [6:0] a_to_g, //段信号
output reg [3:0] an  //位选信号
);
//8611 3819/ 1000_0110_0001_0001// 0011_1000_0001_1001
//wire [15:0]x=16'b0011_1000_0001_1001;
//x={H,L};
//时钟分频 计数器
reg [20:0] clkdiv;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		clkdiv<=21'd0;
	else
		clkdiv<=clkdiv+1;
end
/*利用计数器自动溢出时间，即就是clkdiv从0~11111111111111111111循环计数，
则clk[20:19]会在00~11之间以5.24ms为时间间隔变化  2^19=524288
（即后19位全0到全1的计数时间）
*/

//bitcnt: 位扫描信号 0~1循环变化 扫描周期 5.24ms    控制总扫描时间不超过10ms，单个数码管显示时间约为5ms
wire  [1:0]bitcnt;
assign bitcnt=clkdiv[20:19];

//an:位选信号产生，高有效
always @(posedge clk or negedge rst_n)
begin 
if(!rst_n)
	an=4'd0;
else
	case(bitcnt)
	2'd0:an=4'b0001;
	2'd1:an=4'b0010;
	2'd2:an=4'b0100;
	2'd3:an=4'b1000;
    endcase
end


//digit 当前带显示的数字
 
 reg [3:0]digit;
always @(posedge clk or negedge rst_n)
begin
if (!rst_n)
	digit=4'd0;
else
	case(bitcnt)
	2'd0:digit=x[3:0];
	2'd1:digit=x[7:4];
	2'd2:digit=x[11:8];
	2'd3:digit=x[15:12];
	default:digit=4'd0;
	endcase
end

//a_to_g: 段码信号，共阴极数码管，段码高有效。 7段译码表
always @(posedge clk or negedge rst_n)
begin
if(!rst_n)
	a_to_g=7'b1111111;
else
	case(digit)
	0:a_to_g=7'b1111110;//段码位序由高到低为a-g
	1:a_to_g=7'b0110000;
	2:a_to_g=7'b1101101;
	3:a_to_g=7'b1111001;
	4:a_to_g=7'b0110011;
	5:a_to_g=7'b1011011;
	6:a_to_g=7'b1011111;
	7:a_to_g=7'b1110000;
	8:a_to_g=7'b1111111;
	9:a_to_g=7'b1111011;
	default:a_to_g=7'b1111110;
	endcase
end
endmodule

module xuehao(
input clk,
input rst_n,
//input [31:0] x,      //等待显示的BCD码
output reg [13:0] a_to_g, //段信号
output reg [7:0]  an  //位选信号
);
wire [15:0]ax=16'b0001_1001_0010_0101;
wire [15:0]bx=16'b0000_0010_0011_0100;
wire [6:0]aa_to_g;//=a_to_g[6:0];
wire [6:0]ba_to_g;//=a_to_g[13:7];
wire [3:0]aan;//=an[3:0];
wire [3:0]ban;//=an[7:4];
x7_4bit zhuozhuo1(
.clk(clk),
.rst_n(rst_n),
.x(ax),      //等待显示的BCD码
.a_to_g(aa_to_g), //段信号
.an(aan)  //位选信号
);
x7_4bit zhuozhuo2(
.clk(clk),
.rst_n(rst_n),
.x(bx),      //等待显示的BCD码
.a_to_g(ba_to_g), //段信号
.an(ban)  //位选信号
);
always @*
    begin
        a_to_g={aa_to_g,ba_to_g};
        an={aan,ban};
    end
endmodule

