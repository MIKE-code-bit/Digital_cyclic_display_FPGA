module x7_4bit(
input clk,
input rst_n,
input [15:0] x,      //�ȴ���ʾ��BCD��
output reg [6:0] a_to_g, //���ź�
output reg [3:0] an  //λѡ�ź�
);
//8611 3819/ 1000_0110_0001_0001// 0011_1000_0001_1001
//wire [15:0]x=16'b0011_1000_0001_1001;
//x={H,L};
//ʱ�ӷ�Ƶ ������
reg [20:0] clkdiv;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		clkdiv<=21'd0;
	else
		clkdiv<=clkdiv+1;
end
/*���ü������Զ����ʱ�䣬������clkdiv��0~11111111111111111111ѭ��������
��clk[20:19]����00~11֮����5.24msΪʱ�����仯  2^19=524288
������19λȫ0��ȫ1�ļ���ʱ�䣩
*/

//bitcnt: λɨ���ź� 0~1ѭ���仯 ɨ������ 5.24ms    ������ɨ��ʱ�䲻����10ms�������������ʾʱ��ԼΪ5ms
wire  [1:0]bitcnt;
assign bitcnt=clkdiv[20:19];

//an:λѡ�źŲ���������Ч
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


//digit ��ǰ����ʾ������
 
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

//a_to_g: �����źţ�����������ܣ��������Ч�� 7�������
always @(posedge clk or negedge rst_n)
begin
if(!rst_n)
	a_to_g=7'b1111111;
else
	case(digit)
	0:a_to_g=7'b1111110;//����λ���ɸߵ���Ϊa-g
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
//input [31:0] x,      //�ȴ���ʾ��BCD��
output reg [13:0] a_to_g, //���ź�
output reg [7:0]  an  //λѡ�ź�
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
.x(ax),      //�ȴ���ʾ��BCD��
.a_to_g(aa_to_g), //���ź�
.an(aan)  //λѡ�ź�
);
x7_4bit zhuozhuo2(
.clk(clk),
.rst_n(rst_n),
.x(bx),      //�ȴ���ʾ��BCD��
.a_to_g(ba_to_g), //���ź�
.an(ban)  //λѡ�ź�
);
always @*
    begin
        a_to_g={aa_to_g,ba_to_g};
        an={aan,ban};
    end
endmodule

