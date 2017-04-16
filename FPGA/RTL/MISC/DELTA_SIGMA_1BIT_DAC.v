// $Id: $
// 
//      DELTA_SIGMA_1BIT_DAC.v
//
//
//170323r       :add TB
//151220su      :add XQQ :output reverse QQ
//151219sa      :mod matching for modern coding rule
//               mv write format on parameter
//130223W5      :rename from dalta_sigma_1dac.v
//2009-08-08W6  :label change
//2009-07-25W6  :repair for QuartusII v9.0
//                must decriear input port reg 

module DELTA_SIGMA_1BIT_DAC #(
        parameter C_DAT_W = 10
)(
          CK
        , XARST_i
        , DAT_i
        , QQ_o
        , XQQ_o
) ;
        // architecture Behavioral of delta_sigma_1dac is
        localparam C_0=64'd0 ;
        input                   CK      ;
        input                   XARST_i     ;
        input   [C_DAT_W-1 :0]  DAT_i   ;
        output                  QQ_o    ;
        output                  XQQ_o   ;

        wire    [C_DAT_W+1 :0] delta ;
        reg     [C_DAT_W+1 :0] SIGMA ;

        assign  delta = {{2 { SIGMA[C_DAT_W + 1] }} , DAT_i[C_DAT_W-1 :0]} ;
        always @ (posedge CK or negedge XARST_i) 
                if ( ~ XARST_i)
                        SIGMA <= C_0[0 +: C_DAT_W+2] ;
                else
                        SIGMA <= delta + SIGMA ;

        reg             QQ ;
        reg             XQQ ;
        always @ (posedge CK or negedge XARST_i)
                if ( ~ XARST_i ) begin
                        QQ <=   C_0[0] ;
                        QQ <= ~ C_0[0] ;
                end else begin
                        QQ  <= ~ SIGMA[ C_DAT_W ] ;
                        XQQ <=   SIGMA[ C_DAT_W] ;
                end
        assign QQ_o = QQ ;
        assign XQQ_o = XQQ ;
endmodule // DELTA_SIGMA_1BIT_DAC()


`timescale 1ns/1ns
module tbDELTA_SIGMA_1BIT_DAC #(
    parameter C_C = 10
)(
) ;
    reg     CK  ;
    initial begin
        CK <= 1'b1 ;
        forever begin
            #( C_C /2) ;
            CK <= ~ CK ;
        end
    end
    reg XARST   ;
    initial begin
        XARST <= 1'b1 ;
        #( 0.1 * C_C) ;
            XARST <= 1'b0 ;
        #( 2.1 * C_C) ;
            XARST <= 1'b1 ;
    end
    wire    [ 7: 0] data    ;
    wire            QQ      ;
    DELTA_SIGMA_1BIT_DAC  #(
        .C_DAT_W( 8 )
    ) DELTA_SIGMA_1BIT_DAC (
          .CK       ( CK    )
        , .XARST_i  ( XARST )
        , .DAT_i    ( data   )
        , .QQ_o     ( QQ    )
        , .XQQ_o    ()
    ) ;
    reg [ 8 :0] DAT    ;
    initial begin
        DAT <= 'd0 ;
        repeat ( 600 ) begin
            repeat ( 500 )
                @(posedge CK) ;
            DAT <= DAT + 1 ;
        end
        $stop ;
    end
    assign data = DAT[8] ? ~ DAT[7:0] : DAT[7:0] ;


    reg     [15 :0] IIR_CORE    ;
    wire    [ 7 :0] IIR         ;
    always @(posedge CK or negedge XARST)
        if ( ~ XARST) 
                IIR_CORE <= 16'h8000 ;
        else 
            IIR_CORE <= 
                IIR_CORE 
                + (QQ ? 9'h100 : 9'h000) 
                - (IIR_CORE[15:8] + IIR_CORE[7]) 
            ;
    assign IIR = IIR_CORE[15 : 8] + IIR_CORE[7] ;

endmodule
