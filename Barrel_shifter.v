module barrel_shifter #(
    parameter N = 8,  // Número de portas
    parameter W = 8   // Largura de cada porta
)(
    input  wire [N*W-1:0] in,     // Entradas
    input  wire [$clog2(N)-1:0] shift, // Quantidade de rotação
    output wire [N*W-1:0] out     // Saídas rotacionadas
);


    // Duplica vetor para permitir rotação circular
    wire [2*N*W-1:0] in_double;

    assign in_double = {in, in};

    genvar k;
    generate
        for (k = 0; k < N; k = k + 1) begin : MUX
            assign out[k*W +: W] =
                   in_double[(k + shift)*W +: W];
        end
    endgenerate

endmodule