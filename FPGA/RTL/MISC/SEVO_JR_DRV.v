// ‘û“ü‚è
// SERVO_JR_DRV.v
//      LED7SEG_DRV()
//

module SERVO_JR_DRV #(
      parameter C_FCK   =    48_000_000    //[Hz]
    , parameter C_TFRAME    =    20_000     //[us]
    , parameter C_TBOTTOM   =       500     //[us]
    , parameter C_TTOP      =     2_400     //[us]
)(
      input                 CK_i
    , input tri1            XARST_i
    , input tri0    [ 7 :0] DAT_i
    , output                SERVO_o
    , output                FRAME_o
) ;
    function time log2;             //time is reg unsigned [63:0]
        input time value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction
    localparam C_FCK_KHZ = C_FCK /1000 ;
    localparam C_FRAME = C_TFRAME *  C_FCK_KHZ /1000;
    localparam C_F_CTR_W = log2( C_FRAME -1) ;
    localparam C_BOTTOM = C_TBOTTOM * C_FCK_KHZ  /1000 ;
    localparam C_TOP = C_TTOP * C_FCK_KHZ /1000 ;
    localparam C_FRAME_PLS = C_TOP ;

    reg [C_F_CTR_W-1:0]     F_CTR   ;
    reg                     SERVO   ;
    reg                     FRAME   ;
    reg [C_F_CTR_W-1:0]    SERVO_D ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            F_CTR <= 'd0 ;
            FRAME <= 1'b1 ;
            SERVO <= 1'b1 ;
            SERVO_D <= C_TOP ;
        end else begin
            if (
                &(F_CTR | (~(C_FRAME-1)))
            ) begin
                F_CTR <= 'd0 ;
                FRAME <= 1'b1 ;
                SERVO <= 1'b1 ;
                SERVO_D <= DAT_i * (C_TOP-C_BOTTOM) / 256 + C_BOTTOM ;
            end else begin
                F_CTR <= F_CTR + 'd1 ;
                if (F_CTR == (SERVO_D-1))
                    SERVO <= 1'b0 ;
                if (&(F_CTR | (~(C_FRAME_PLS-1))) )
                    FRAME <= 1'b0 ;
            end
        end
    assign FRAME_o = FRAME ;
    assign SERVO_o = SERVO ;
endmodule //SERVO_JR_DRV
