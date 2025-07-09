module x7_4bit(
    input clk,
    input rst_n,
    input [15:0] x,          // 待显示的BCD码
    output reg [6:0] a_to_g, // 段信号
    output reg [3:0] an      // 位选信号
);
    reg [20:0] clkdiv;
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            clkdiv <= 21'd0;
        else
            clkdiv <= clkdiv + 1;
    end

    wire [1:0] bitcnt;
    assign bitcnt = clkdiv[20:19];

    always @(posedge clk or negedge rst_n)
    begin 
        if(!rst_n)
            an = 4'd0;
        else
            case(bitcnt)
                2'd0: an = 4'b0001;
                2'd1: an = 4'b0010;
                2'd2: an = 4'b0100;
                2'd3: an = 4'b1000;
            endcase
    end

    reg [3:0] digit;
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            digit = 4'd0;
        else
            case(bitcnt)
                2'd0: digit = x[3:0];
                2'd1: digit = x[7:4];
                2'd2: digit = x[11:8];
                2'd3: digit = x[15:12];
                default: digit = 4'd0;
            endcase
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            a_to_g = 7'b0000000;
        else
            case(digit)
                4'd0: a_to_g = 7'b1111110;
                4'd1: a_to_g = 7'b0110000;
                4'd2: a_to_g = 7'b1101101;
                4'd3: a_to_g = 7'b1111001;
                4'd4: a_to_g = 7'b0110011;
                4'd5: a_to_g = 7'b1011011;
                4'd6: a_to_g = 7'b1011111;
                4'd7: a_to_g = 7'b1110000;
                4'd8: a_to_g = 7'b1111111;
                4'd9: a_to_g = 7'b1111011;
                4'd15: a_to_g = 7'b0000000; // 空白
                default: a_to_g = 7'b0000000;
            endcase
    end
endmodule

module xuehao(
    input clk,
    input rst_n,
    input dir,
    output reg [13:0] a_to_g, // 段信号
    output reg [7:0] an       // 位选信号
);
    // 秒时钟（1Hz）
    reg [26:0] sec_cnt;
    reg sec_tick;
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sec_cnt <= 0;
            sec_tick <= 0;
        end
        else if(sec_cnt >= 100_000_000 - 1)
        begin
            sec_cnt <= 0;
            sec_tick <= 1;
        end
        else
        begin
            sec_cnt <= sec_cnt + 1;
            sec_tick <= 0;
        end
    end

    // 学号数据：0 2 3 4 1 9 2 5
    reg [3:0] id_bcd[7:0];
    initial begin
        id_bcd[0] = 4'd0;
        id_bcd[1] = 4'd2;
        id_bcd[2] = 4'd3;
        id_bcd[3] = 4'd4;
        id_bcd[4] = 4'd1;
        id_bcd[5] = 4'd9;
        id_bcd[6] = 4'd2;
        id_bcd[7] = 4'd5;
    end

    // 当前显示步数
    reg [3:0] show_step;
    reg [1:0] delay_cnt;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            show_step <= 0;
            delay_cnt <= 0;
        end
        else if(sec_tick)
        begin
            if(show_step < 8)
                show_step <= show_step + 1;
            else
            begin
                if(delay_cnt < 1)
                    delay_cnt <= delay_cnt + 1;
                else
                begin
                    delay_cnt <= 0;
                    show_step <= 0;
                end
            end
        end
    end

    // 构造待显示的16位 BCD 数据
    reg [15:0] ax, bx;
    reg [3:0] display[7:0];
    integer i;
    always @(*) begin
    // 初始化为全空白
    for(i = 0; i < 8; i = i + 1)
        display[i] = 4'd15;

    if(dir == 1'b0) begin
        // 方向=0，右向左滚入
        for(i = 0; i < show_step; i = i + 1)
            display[7 - i] = id_bcd[7 - i];
    end else begin
        // 方向=1，左向右滚入
        for(i = 0; i < show_step; i = i + 1)
            display[i] = id_bcd[i];
    end

    // 映射到段控制
    bx = {display[4], display[5], display[6], display[7]}; // D3~D0
    ax = {display[0], display[1], display[2], display[3]}; // D7~D4
    end

    // 两个 4 位数码管驱动模块
    wire [6:0] aa_to_g, ba_to_g;
    wire [3:0] aan, ban;
    x7_4bit u1 (
        .clk(clk),
        .rst_n(rst_n),
        .x(ax),
        .a_to_g(aa_to_g),
        .an(aan)
    );
    x7_4bit u2 (
        .clk(clk),
        .rst_n(rst_n),
        .x(bx),
        .a_to_g(ba_to_g),
        .an(ban)
    );

    // 合并输出
    always @(*) begin
        a_to_g = {aa_to_g, ba_to_g};
        an = {aan, ban};
    end

endmodule
