//VR_LOC_DET.v
//  VR_LOC_DET 
//  volume(Variable Register) location ditector
//
//170407f   002 :P-N combinearign center but...
//170326u   001 :new for VR_LOC_DET
//

module VR_LOC_DET(
      input     CK_i
    , input     XARST_i
    , input  tri1 EN_CK_i
    , output        TPAT_P_o
    , output        TPAT_N_o
    , input         DAT_i
    , output [ 7:0] LOC_o
    , output        CMP_P_o
    , output        CMP_N_o

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

    reg [C_DAT_DLY-1:0] DAT_D ;
    generate
        if (C_DAT_DLY > 1)
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    DAT_D <= {C_DAT_DLY{1'b0}} ;
                else
                    DAT_D <= {DAT_i , DAT_D[C_DAT_DLY-1:1]} ;
        else
            always @(posedge CK_i or negedge XARST_i)
                if ( ~ XARST_i)
                    DAT_D[0] <= 1'b0 ;
                else
                    DAT_D[0] <= DAT_i ;
    endgenerate


    wire    CMP_P_a ;
    assign CMP_P_a = MSEQ_P_D[0] == DAT_D[0] ;
    wire    CMP_N_a ;
    assign CMP_N_a = MSEQ_N_D[0] == DAT_D[0] ;
    reg     CMP_P   ;
    reg     CMP_N   ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i ) begin
            CMP_P <= 1'b0 ;
            CMP_N <= 1'b0 ;
        end else begin
            CMP_P <= CMP_P_a ;
            CMP_N <= CMP_N_a ;
        end
            
    assign CMP_P_o = CMP_P ;
    assign CMP_N_o = CMP_N ;


    wire    [ 1 :0] LOC_PN   ;
    assign LOC_PN = {CMP_P , ~ CMP_N} ;
    wire    [ 8 :0] LOC_AQ ;
    IIR_LPF #(
          .C_DAT_W  ( 9    )
        , .C_SHIFT  ( 17    )   //=17 in CK_EN 48MHz ,tau ?=2.73ms,fc=58.3Hz
                                // fc = fck/(2*pi*((2**C_SHIFT)))
                                // (2**C_SHIFT) = fck/fc/2/pi
                                // C_SHIFT = log((fck/fc/2/pi) , 2)
    ) u_IIR_LPF_PN (
          .CK_i     ( CK_i          )
        , .XARST_i  ( XARST_i       )
        , .EN_CK_i  ( 1'b1          )
        , .DAT_i    ( 
            (LOC_PN == 2'b11) ? 
                9'h1FF
            : (LOC_PN == 2'b00) ?
                9'h001
            :
                9'h100
        )
        , .QQ_o     ( LOC_AQ       )
        , .SIGMA_o  ()
    ) ;
    reg [ 7 :0] LOC ;
    always @ (posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i )
            LOC <= 8'h80 ;
        else
            if (LOC_AQ[8:7] == 2'b11)
                LOC <= 8'hFF ;
            else if (LOC_AQ[8:7] == 2'b00)
                LOC <= 8'h01 ;
            else
                LOC <= {~LOC_AQ[7] , LOC_AQ[6:0]} ;

    assign LOC_o = LOC ;


endmodule //VR_LOC_DET
