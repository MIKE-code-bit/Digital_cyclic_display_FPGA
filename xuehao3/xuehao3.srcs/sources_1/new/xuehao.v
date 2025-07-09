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

    reg [3:0] id_bcd_1[7:0]; // 学号1
    reg [3:0] id_bcd_2[7:0]; // 学号2
    initial begin
        id_bcd_1[0] = 4'd0;
        id_bcd_1[1] = 4'd2;
        id_bcd_1[2] = 4'd3;
        id_bcd_1[3] = 4'd4;
        id_bcd_1[4] = 4'd1;
        id_bcd_1[5] = 4'd9;
        id_bcd_1[6] = 4'd2;
        id_bcd_1[7] = 4'd5;

        id_bcd_2[0] = 4'd0;
        id_bcd_2[1] = 4'd2;
        id_bcd_2[2] = 4'd3;
        id_bcd_2[3] = 4'd4;
        id_bcd_2[4] = 4'd1;
        id_bcd_2[5] = 4'd9;
        id_bcd_2[6] = 4'd2;
        id_bcd_2[7] = 4'd9;
    end

    reg current_id; // 0：显示第一个学号，1：显示第二个
    reg [3:0] show_step;
    reg [1:0] delay_cnt;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            show_step <= 0;
            delay_cnt <= 0;
            current_id <= 0;
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
                    current_id <= ~current_id; // 切换学号
                end
            end
        end
    end

    reg [15:0] ax, bx;
    reg [3:0] display[7:0];
    integer i;
    always @(*) begin
        for(i = 0; i < 8; i = i + 1)
            display[i] = 4'd15;

        if(current_id == 0) begin
            if(dir == 1'b0) begin
                for(i = 0; i < show_step; i = i + 1)
                    display[7 - i] = id_bcd_1[7 - i];
            end else begin
                for(i = 0; i < show_step; i = i + 1)
                    display[i] = id_bcd_1[i];
            end
        end else begin
            if(dir == 1'b0) begin
                for(i = 0; i < show_step; i = i + 1)
                    display[7 - i] = id_bcd_2[7 - i];
            end else begin
                for(i = 0; i < show_step; i = i + 1)
                    display[i] = id_bcd_2[i];
            end
        end

        bx = {display[4], display[5], display[6], display[7]};
        ax = {display[0], display[1], display[2], display[3]};
    end

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

    always @(*) begin
        a_to_g = {aa_to_g, ba_to_g};
        an = {aan, ban};
    end
endmodule