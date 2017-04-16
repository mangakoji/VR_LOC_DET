// MSEQ.v
//  FIBONACCI_LFSR  ( ) : use old randome gate method
//  GALOIS_LFSR     ( ) : use ECC method
//
// Linear Feedback Shift Register(FLFSR)
//
// GF_COF from http://www.finetune.co.jp/~lyuka/technote/lfsr/lfsr.html
// write by:@manga_koji

//170326    001 :
//170227    001 :1st.


module FIBONACCI_LFSR  # (
//      parameter C_GF_COF    = 16'b1011_0100_0000_0000
      parameter C_GF_COF    = 17'b1_0110_1000_0000_0001
//    , parameter C_LDD       = 16'hACE1 
    , parameter C_LDD        = 'h0
)(
      input         CK_i
    , input tri1    XARST_i
    , input tri1    EN_CK_i
    , input tri0    LD_i
    , output        CY_o
) ;
    function time log2;             //time is reg unsigned [63:0]
        input time value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction
    localparam C_REGS_W    = log2(C_GF_COF) - 1 ;
    localparam C_LDD_local = (C_LDD==0) ? 
            {(C_REGS_W){1'b1}}
        :
            C_LDD[C_REGS_W-1:0]
    ;

    reg [C_REGS_W-1 :0] REGS    ;
    wire                cy      ;
    assign cy = ^ (REGS & C_GF_COF[C_REGS_W:1]) ;
    always @ (posedge CK_i or negedge XARST_i)
        if (~ XARST_i)
            REGS <= C_LDD_local ;
        else if ( EN_CK_i ) begin
            if ( LD_i )
                REGS <= C_LDD_local ;
            else 
                REGS <= {REGS[C_REGS_W-2 :0] , cy} ;
        end 
    assign CY_o = cy ;
endmodule


module GALOIS_LFSR # (
      parameter C_GF_COF    = 17'b1_0110_1000_0000_0001
//    , parameter C_LDD       = 17'h1_ACE1 
    , parameter C_LDD       = 'h0
//    , parameter C_LDD        = 17'h159C3 
)(
      input         CK_i
    , input tri1    XARST_i
    , input tri1    EN_CK_i
    , input tri0    LD_i
    , output        CY_o
) ;
    function time log2;                 //time is reg unsigned[63:0]
        input time value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction
    localparam C_REGS_W    = log2(C_GF_COF) - 1 ;
    localparam C_LDD_local = (C_LDD==0) ? 
            {(C_REGS_W){1'b1}}
        :
            C_LDD[C_REGS_W-1:0]
//            C_LDD[30:0]
    ;
    
    reg [C_REGS_W-1 :0] REGS    ;
    always @ (posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i)
            REGS <= C_LDD_local ;
        else if ( EN_CK_i ) begin
            if ( LD_i )
                REGS <= C_LDD_local ;
            else
                REGS <= 
                    {REGS[C_REGS_W-2:0] , 1'b0}
                    ^
                    ({C_REGS_W{CY_o}} & C_GF_COF[C_REGS_W-1:0])
                ;
        end
    assign CY_o = REGS[C_REGS_W-1] ; //MSB
endmodule


module tbMSEQ(
      input     CK_i
    , input     XARST_i
    , input     LD_i
    , output    FIBONACCI_o
    , output    GALOIS_o
    , output    CMP_o
) ;
    FIBONACCI_LFSR u_FIBONACCI_LFSR(
          .CK_i     ( CK_i          )
        , .XARST_i  ( XARST_i       )
        , .EN_CK_i  ( 1'b1          )
        , .LD_i     ( LD_i          )
        , .CY_o     ( FIBONACCI_o   )
    ) ;
    GALOIS_LFSR u_GALOIS_LFSR(
          .CK_i     ( CK_i          )
        , .XARST_i  ( XARST_i       )
        , .EN_CK_i  ( 1'b1          )
        , .LD_i     ( LD_i          )
        , .CY_o     ( GALOIS_o      )
    ) ;
    reg          CMP ;
    always @ (posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i )
            CMP <= 1'b0 ;
        else
            CMP <= (FIBONACCI_o == GALOIS_o) ;
    assign CMP_o = CMP ;
endmodule
