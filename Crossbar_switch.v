module crossbar_switch #(
    parameter N = 8,
    parameter W = 8
)(
    input  wire [N*W-1:0] data_in,              //Entrada dos dados
    input  wire [N*$clog2(N)-1:0] select,       // Cada saída escolhe qual entrada deseja
    input  wire [N-1:0] output_enable,          // Enable individual por saída
    output wire [N*W-1:0] data_out,             // Saídas roteadas
    output wire collision_error                 // Status global de erro
);


    collision_monitor #(N) monitor_inst (       // Instancia Monitor de Colisão
        .select(select),
        .output_enable(output_enable),
        .collision_error(collision_error)
    );

    genvar i;                                   // Matriz baseada em Barrel Shifters


    generate
        for (i = 0; i < N; i = i + 1) begin : OUTPUT_PORT

            wire [N*W-1:0] shifted_bus;
            wire [$clog2(N)-1:0] sel;

            // Extrai seletor da saída i
            assign sel = select[i*$clog2(N) +: $clog2(N)];

            // Cada saída tem seu próprio barrel shifter
            barrel_shifter #(N, W) bs_inst (
                .in(data_in),
                .shift(sel),
                .out(shifted_bus)
            );

            // Pega posição 0 após rotação
            assign data_out[i*W +: W] = (output_enable[i])
                                        ? shifted_bus[0*W +: W]
                                        : {W{1'b0}};

        end
    endgenerate

endmodule