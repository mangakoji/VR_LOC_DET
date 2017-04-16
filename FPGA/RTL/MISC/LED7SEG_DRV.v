// ‘û“ü‚è
// LED7SEG_DRV.v
//      LED7SEG_DRV()
//

module LED7SEG_DRV #(
      parameter C_FCK   = 48_000_000
    , parameter C_FBLINK = 1_0000
)(
      input                 CK_i
    , input tri1            XARST_i
    , input tri0    [15 :0] DAT_i
    , input tri1            LATCH_i
    , input tri0            BUS_SUP0
    , output        [ 3 :0] ACT_DIGIT_o     // act H out
    , output        [ 6 :0] SEG7_o          // segment out ,act H
) ;
    function time log2;             //time is reg unsigned [63:0]
        input time value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction
    localparam C_DIV = C_FCK / C_FBLINK ;
    localparam C_DIV_CTR_W = log2( C_DIV -1) ;

    reg [C_DIV_CTR_W-1:0]   DIV_CTR     ;
    reg                     EN_BLINK    ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            DIV_CTR <= C_DIV - 1'b1 ;
            EN_BLINK <= 1'b0 ;
        end else begin
            if (
                &(DIV_CTR | (~(C_DIV-1)))
            ) begin
                DIV_CTR <= 'd0 ;
                EN_BLINK <= 1'b1 ;
            end else begin
                DIV_CTR <= DIV_CTR + 'd1 ;
                EN_BLINK <= 1'b0 ;
            end
        end

    reg [15:0]  DAT_D   ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i)
            DAT_D <= 'd0 ;
        else if ( LATCH_i)
            DAT_D <= DAT_i ;

    // digit select
    reg [3 :0] ACT_DIGIT    ;
    reg         EN_BLINK_D      ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            ACT_DIGIT   <= 'h8 ;
            EN_BLINK_D <= 1'b0 ;
        end else begin
            EN_BLINK_D <= EN_BLINK ;
            if ( EN_BLINK )
                ACT_DIGIT <= 
                    (~|ACT_DIGIT) ? 
                        'h8
                    : 
                        {ACT_DIGIT[0] , ACT_DIGIT[3:1] } 
                ;
        end
    reg [ 3 :0] OCTET_SELED ;
    reg [ 3 :0] ACT_DIGIT_D ;
    reg         EN_BLINK_DD ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            OCTET_SELED <= 4'b0 ;
            EN_BLINK_DD <= 1'b0 ;
            ACT_DIGIT_D <= 'd0 ;
        end else begin
            EN_BLINK_DD <= EN_BLINK_D ;
            ACT_DIGIT_D <= ACT_DIGIT ;
            if (EN_BLINK_D )
                OCTET_SELED <= 
                      (ACT_DIGIT[3]) ? DAT_D[15:12]
                    : (ACT_DIGIT[2]) ? DAT_D[11: 8]
                    : (ACT_DIGIT[1]) ? DAT_D[ 7: 4]
                    : (ACT_DIGIT[0]) ? DAT_D[ 3: 0]
                    : 4'b0 
                ;
        end

    // decoder for  LED7-segment
    //   a 
   // f     b
   //    g
   // e     c
   //    d
    function [6:0] f_seg_dec ;
        input [3:0] octet;
    begin
        case( octet )
                              //  gfedcba
            4'h0 : f_seg_dec = 7'b0111111 ; //0
            4'h1 : f_seg_dec = 7'b0000110 ; //1
            4'h2 : f_seg_dec = 7'b1011011 ; //2
            4'h3 : f_seg_dec = 7'b1001111 ; //3
            4'h4 : f_seg_dec = 7'b1100110 ; //4
            4'h5 : f_seg_dec = 7'b1101101 ; //5
            4'h6 : f_seg_dec = 7'b1111101 ; //6
            4'h7 : f_seg_dec = 7'b0100111 ; //7
            4'h8 : f_seg_dec = 7'b1111111 ; //8
            4'h9 : f_seg_dec = 7'b1101111 ; //9
            4'hA : f_seg_dec = 7'b1110111 ; //a
            4'hB : f_seg_dec = 7'b1111100 ; //b
            4'hC : f_seg_dec = 7'b0111001 ; //c
            4'hD : f_seg_dec = 7'b1011110 ; //d
            4'hE : f_seg_dec = 7'b1111001 ; //e
            4'hF : f_seg_dec = 7'b1110001 ; //f
            default : f_seg_dec = 7'b1000000 ; //-
        endcase
    end endfunction


    reg [ 6 :0] SEG7        ;
    reg [ 3 :0] ACT_DIGIT_DD   ;
    wire        SUP_a ;
    assign SUP_a = 
        (BUS_SUP0) &
        (
            (ACT_DIGIT_D[3]) ?
                (OCTET_SELED == 4'h0 )
            :
                (SUP & (OCTET_SELED == 4'h0))
        )
    ;
    reg         SUP ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin 
            ACT_DIGIT_DD   <= 'd1 ;
            SEG7            <= 7'd0 ;
        end else begin
            if (EN_BLINK_DD) begin
                ACT_DIGIT_DD <= ACT_DIGIT_D ;
                SUP <= SUP_a ;
                SEG7 <= {7{~SUP_a}} & f_seg_dec( OCTET_SELED ) ;
            end
        end
    assign ACT_DIGIT_o = ACT_DIGIT_DD   ;
    assign SEG7_o     = SEG7           ;
    
endmodule //LED7SEG_DRV
