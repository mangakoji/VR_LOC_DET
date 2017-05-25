//VR_LOC_DET.v
//  VR_LOC_DET 
//  volume(Variable Register) location ditector
//170525th  003 :support multi potention memter , ch_n split.
//170407f   002 :P-N combinearign center but...
//170326u   001 :new for VR_LOC_DET
//

module VR_LOC_DET #(
    parameter C_CH_N = 1
)(
      input                     CK_i
    , input                     XARST_i
    , input  tri1               EN_CK_i
    , output                    TPAT_P_o
    , output                    TPAT_N_o
    , input  [C_CH_N-1 :0]      DAT_i
    , output [C_CH_N*8-1 :0]    LOC_o
    , output [C_CH_N-1 :0]      CMP_P_o
    , output [C_CH_N-1 :0]      CMP_N_o

) ;
    function integer log2;
        input integer value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction
//    parameter C_FCK = 48_000_000 ;
    
    // output test pattern
    wire    MSEQ_P  ;
    wire    MSEQ_N  ;
    GALOIS_LFSR #(
        //           (32,22,2,1)
        //                2109_8765_4321_0987_6543_2109_8765_4321
          .C_GF_COF ( 32'b1000_1000_0010_0000_0000_0000_0000_0011)
    ) GALOIS_LFSR_POS(
          .CK_i     ( CK_i          )
        , .XARST_i  ( XARST_i       )
        , .CY_o     ( MSEQ_P      )
    ) ;
    GALOIS_LFSR #(
        //           (32,22,2,1)
        //                2109_8765_4321_0987_6543_2109_8765_4321
          .C_GF_COF ( 32'b1000_1000_0010_0000_0000_0000_0000_0011 )
        , .C_LDD    ( 32'h70_C0FFEE ) //to_coffee
    ) GALOIS_LFSR_NEG(
          .CK_i     ( CK_i          )
        , .XARST_i  ( XARST_i       )
        , .CY_o     ( MSEQ_N      )
    ) ;
    assign TPAT_P_o = MSEQ_P ;
    assign TPAT_N_o = MSEQ_N ;

    // test pattern feed 
    parameter C_P_DLY = 2 ;
    parameter C_N_DLY = 2 ;
    parameter C_DAT_DLY = 2 ;
    reg [C_P_DLY :0] MSEQ_P_D    ;
    reg [C_N_DLY :0] MSEQ_N_D    ;
    generate 
        if (C_P_DLY > 1)
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    MSEQ_P_D <= {C_P_DLY{1'b1}} ;
                else
                    MSEQ_P_D <= {MSEQ_P , MSEQ_P_D[C_P_DLY-1:1]} ;
        else
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    MSEQ_P_D[0] <= 1'b1 ;
                else
                    MSEQ_P_D[0] <= MSEQ_P ;
    endgenerate

    generate
        if (C_N_DLY > 1)
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    MSEQ_N_D <= {C_N_DLY{1'b1}} ;
                else
                    MSEQ_N_D <= {MSEQ_N , MSEQ_N_D[C_N_DLY-1:1]} ;
        else
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    MSEQ_N_D[0] <= 1'b1 ;
                else
                    MSEQ_N_D[0] <= MSEQ_N ;
    endgenerate

    reg [C_DAT_DLY-1:0] DAT_D [0 : C_CH_N-1];
    genvar g_ch ;
    generate
        for (g_ch=0 ; g_ch<C_CH_N ; g_ch=g_ch+1) begin:gen_DLY
            if (C_DAT_DLY > 1)
                always @(posedge CK_i or negedge XARST_i)
                    if ( ~ XARST_i)
                        DAT_D[g_ch] <= {C_DAT_DLY{1'b0}} ;
                    else
                        DAT_D[g_ch] <= {DAT_i[g_ch] , DAT_D[g_ch][C_DAT_DLY-1:1]} ;
            else
                always @(posedge CK_i or negedge XARST_i)
                    if ( ~ XARST_i)
                        DAT_D[g_ch][0] <= 1'b0 ;
                    else
                        DAT_D[g_ch][0] <= DAT_i[g_ch] ;
        end
    endgenerate


    wire    [C_CH_N-1:0]    CMP_P_a ;
    wire    [C_CH_N-1:0]    CMP_N_a ;
    reg     [C_CH_N-1:0]    CMP_P   ;
    reg     [C_CH_N-1:0]    CMP_N   ;
    generate
        for (g_ch=0 ; g_ch<C_CH_N ; g_ch=g_ch+1) begin:gen_CMP
            assign CMP_P_a[g_ch] = MSEQ_P_D[0] == DAT_D[g_ch][0] ;
            assign CMP_N_a[g_ch] = MSEQ_N_D[0] == DAT_D[g_ch][0] ;
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i ) begin
                    CMP_P[g_ch] <= 1'b0 ;
                    CMP_N[g_ch] <= 1'b0 ;
                end else begin
                    CMP_P[g_ch] <= CMP_P_a[g_ch] ;
                    CMP_N[g_ch] <= CMP_N_a[g_ch] ;
                end
            assign CMP_P_o[g_ch] = CMP_P[g_ch] ;
            assign CMP_N_o[g_ch] = CMP_N[g_ch] ;
        end
    endgenerate

    wire    [ 1 :0] LOC_PN  [0:C_CH_N-1];
    wire    [ 8 :0] LOC_AQ  [0:C_CH_N-1];
    reg     [ 7 :0] LOC     [0:C_CH_N-1];
    generate
        for (g_ch=0 ; g_ch<C_CH_N ; g_ch=g_ch+1) begin:gen_IIR_LOC
            assign LOC_PN[g_ch] = {CMP_P[g_ch] , ~ CMP_N[g_ch]} ;
            IIR_LPF #(
                  .C_DAT_W  ( 9    )
                , .C_SHIFT  ( 17    )   //=17 in CK_EN 48MHz 
                                        // ,tau ?=2.73ms,fc=58.3Hz
                                        // fc = fck/(2*pi*((2**C_SHIFT)))
                                        // (2**C_SHIFT) = fck/fc/2/pi
                                        // C_SHIFT = log((fck/fc/2/pi) , 2)
                ) u_IIR_LPF_PN (
                  .CK_i     ( CK_i          )
                , .XARST_i  ( XARST_i       )
                , .EN_CK_i  ( 1'b1          )
                , .DAT_i    ( 
                        (LOC_PN[g_ch] == 2'b11) ? 
                            9'h1FF
                        : (LOC_PN[g_ch] == 2'b00) ?
                            9'h001
                        :
                            9'h100
                )
                , .QQ_o     ( LOC_AQ[g_ch]  )
                , .SIGMA_o  ()
            ) ;
            always @ (posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i )
                LOC[g_ch] <= 8'h80 ;
            else
                if (LOC_AQ[g_ch][8:7] == 2'b11)
                    LOC[g_ch] <= 8'hFF ;
                else if (LOC_AQ[g_ch][8:7] == 2'b00)
                    LOC[g_ch] <= 8'h01 ;
                else
                    LOC[g_ch] <= {~LOC_AQ[g_ch][7] , LOC_AQ[g_ch][6:0]} ;
            assign LOC_o[g_ch*8 +: 8] = LOC[g_ch] ;
        end
    endgenerate


endmodule //VR_LOC_DET
