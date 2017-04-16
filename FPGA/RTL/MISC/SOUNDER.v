// ‘û“ü‚è
// SOUNDER.v
//      LED7SEG_DRV()
//

module SOUNDER #(
      parameter C_FCK   =    48_000_000    //[Hz]
)(
      input                 CK_i
    , input tri1            XARST_i
    , input tri0    [ 7 :0] KEY_i
    , output                SOUND_o
    , output                XSOUND_o
    , output        [ 15:0] SOUND_CTR_o
) ;
    function time log2;             //time is reg unsigned [63:0]
        input time value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction

    reg [ 7 :0] PRESCALE_CTR    ;
    reg         EN_CK           ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            PRESCALE_CTR <= 'd0 ;
            EN_CK <= 1'b0 ;
        end else begin
            EN_CK <= (& PRESCALE_CTR) ;
            PRESCALE_CTR <= PRESCALE_CTR + 1 ;
        end


    
    reg [15 :0] SOUND_CTR ;
    reg [ 8 :0] SOUND_DIV   ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            SOUND_CTR <= 16'd0 ;
            SOUND_DIV <= 9'd85 ;
        end else if ( EN_CK ) begin
            SOUND_DIV <= 9'd85 +{1'b0 ,  KEY_i} ;
            SOUND_CTR <= SOUND_CTR + SOUND_DIV ;
        end
    assign SOUND_CTR_o = SOUND_CTR ;
    reg     SOUND   ;
    reg     XSOUND  ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) begin
            SOUND  <= 1'b0 ;
            XSOUND <= 1'b0 ;
        end else begin
            if (KEY_i > 8'h01) begin
                SOUND  <= SOUND_CTR[15] ;
                XSOUND <= ~ SOUND_CTR[15]  ;
            end
        end
    assign SOUND_o  = SOUND ;
    assign XSOUND_o = XSOUND ;

endmodule //SOUNDER
