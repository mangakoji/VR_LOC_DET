// IIR_LPF.v
//
module IIR_LPF #(
          parameter C_DAT_W = 8
        , parameter C_SHIFT = 8  //=8 in CK_EN 50MHz ,tau ?=5.23us,fc=31.1kHz
                                 // fc = 1./(2*pi*((2**C_SHIFT)*fck))
)(
          CK_i
        , XARST_i
        , EN_CK_i
        , DAT_i
        , QQ_o
        , SIGMA_o
) ;
        localparam C_SIGMA_W = C_DAT_W + C_SHIFT ;
        input                           CK_i    ;
        input   tri1                    XARST_i ;
        input   tri1                    EN_CK_i ;
        input   tri0 [C_DAT_W-1 :0]     DAT_i   ;
        output       [C_DAT_W-1 :0]     QQ_o    ;
        output       [C_SIGMA_W-1 :0]   SIGMA_o ;


        wire    [C_DAT_W :0]    diff    ;//2's
        assign diff = DAT_i - SIGMA[C_SIGMA_W-1:C_SHIFT] ;
//        assign diff = {1'b0 , DAT_i} - {1'b0 ,  SIGMA[C_SIGMA_W-1:C_SHIFT]} ;

        wire    [C_SIGMA_W-1 :0] SIGMA_a ;
        assign SIGMA_a = SIGMA + $signed( diff ) ;
//        assign SIGMA_a = {1'b0 , SIGMA}  + {diff[C_DAT_W] , diff} ;


        reg     [C_SIGMA_W-1 :0] SIGMA ;
        always @ (posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    SIGMA <= 'd0 ;
                else if ( EN_CK_i )
                    SIGMA <= SIGMA_a  ;
        assign QQ_o = SIGMA[C_SIGMA_W-1:C_SHIFT] ;
        assign SIGMA_o = SIGMA ;
endmodule // IIR_LPF
