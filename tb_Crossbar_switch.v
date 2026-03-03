//@Hyago
`timescale 1ns/1ps

module tb_Crossbar_Switch;

  parameter N   = 8;
  parameter W8  = 8;
  parameter W16 = 16;
  parameter W10 = 10;

  localparam SELW = $clog2(N);

  reg  [N*SELW-1:0] select;
  reg  [N-1:0]      output_enable;

  // W=8
  reg  [N*W8-1:0]  data_in8;
  wire [N*W8-1:0]  data_out8;
  wire             collision_error8;

  crossbar_switch #(N, W8) dut8 (
    .data_in(data_in8),
    .select(select),
    .output_enable(output_enable),
    .data_out(data_out8),
    .collision_error(collision_error8)
  );

  // W=16
  reg  [N*W16-1:0] data_in16;
  wire [N*W16-1:0] data_out16;
  wire             collision_error16;

  crossbar_switch #(N, W16) dut16 (
    .data_in(data_in16),
    .select(select),
    .output_enable(output_enable),
    .data_out(data_out16),
    .collision_error(collision_error16)
  );

  // W=10
  reg  [N*W10-1:0] data_in10;
  wire [N*W10-1:0] data_out10;
  wire             collision_error10;

  crossbar_switch #(N, W10) dut10 (
    .data_in(data_in10),
    .select(select),
    .output_enable(output_enable),
    .data_out(data_out10),
    .collision_error(collision_error10)
  );

  integer i;

  initial begin
    $display("\n=== TB CROSSBAR SIMPLES (N=8 | W=8,16,10) ===");

    // -----------------------------
    // Inicialização + dados conhecidos
    // -----------------------------
    data_in8  = 0;
    data_in16 = 0;
    data_in10 = 0;
    select    = 0;
    output_enable = 0;

    for (i = 0; i < N; i = i + 1) begin
      data_in8 [i*W8  +: W8 ] = i + 8'h10;        // 10..17
      data_in16[i*W16 +: W16] = 16'h1000 + i;     // 1000..1007
      data_in10[i*W10 +: W10] = 10'h100 + i;      // 100..107
    end

    output_enable = 8'b11111111;

    #5;

    // =========================================================
    // CASO 1 - Roteamento Paralelo de Alta Densidade (>=4 rotas)
    // Exemplo com 8 rotas simultâneas (sem repetição)
    // =========================================================
    $display("\n[CASO 1] Roteamento paralelo (sem colisao)");
    select = 0;
    select[0*SELW +: SELW] = 7;
    select[1*SELW +: SELW] = 6;
    select[2*SELW +: SELW] = 5;
    select[3*SELW +: SELW] = 4;
    select[4*SELW +: SELW] = 0;
    select[5*SELW +: SELW] = 2;
    select[6*SELW +: SELW] = 3;
    select[7*SELW +: SELW] = 1;

    #1;
    $display("collision_error (esperado 0): %b", collision_error8);

    #20;

    // =========================================================
    // CASO 2 - Validação de Conflito (Corner Case)
    // Saídas 0,1,2 acessam a mesma entrada 3
    // =========================================================
    $display("\n[CASO 2] Conflito (0,1,2 -> 3)");
    output_enable = 8'b11111111;
    select = 0;
    select[0*SELW +: SELW] = 3;
    select[1*SELW +: SELW] = 3;
    select[2*SELW +: SELW] = 3;

    #1;
    $display("collision_error (esperado 1): %b", collision_error8);

    #20;

    // =========================================================
    // CASO 3 - Controle de Habilitação (enable em tempo real)
    // Desabilita saída 4 => saída deve virar 0 imediatamente
    // =========================================================
    $display("\n[CASO 3] Enable em tempo real (desabilita out4)");
    output_enable = 8'b11111111;
    select = 0;
    // sel=i
    select[0*SELW +: SELW] = 0;
    select[1*SELW +: SELW] = 1;
    select[2*SELW +: SELW] = 2;
    select[3*SELW +: SELW] = 3;
    select[4*SELW +: SELW] = 4;
    select[5*SELW +: SELW] = 5;
    select[6*SELW +: SELW] = 6;
    select[7*SELW +: SELW] = 7;

    #1;
    $display("out4 W8 antes disable : %02h", data_out8[4*W8 +: W8]);

    output_enable[4] = 1'b0;
    #1;
    $display("out4 W8 apos  disable : %02h (esperado 00)", data_out8[4*W8 +: W8]);

    output_enable[4] = 1'b1;
    #1;
    $display("out4 W8 reenable      : %02h (volta ao valor)", data_out8[4*W8 +: W8]);

    #20;

    // =========================================================
    // CASO 4 - Mudança Dinâmica (troca de rota durante dados)
    // muda os dados e a rota e observa a comutação
    // =========================================================
    $display("\n[CASO 4] Mudança dinâmica (dados + rota)");
    output_enable = 8'b11111111;

    // rota inicial sel=i
    select = 0;
    select[0*SELW +: SELW] = 0;
    select[1*SELW +: SELW] = 1;
    select[2*SELW +: SELW] = 2;
    select[3*SELW +: SELW] = 3;
    select[4*SELW +: SELW] = 4;
    select[5*SELW +: SELW] = 5;
    select[6*SELW +: SELW] = 6;
    select[7*SELW +: SELW] = 7;

    #1;
    $display("out0 W8 (sel=0) antes: %02h", data_out8[0*W8 +: W8]);

    // muda dados "em transmissão"
    for (i = 0; i < N; i = i + 1) begin
      data_in8 [i*W8  +: W8 ] = data_in8 [i*W8  +: W8 ] + 8'h20;
      data_in16[i*W16 +: W16] = data_in16[i*W16 +: W16] + 16'h0020;
      data_in10[i*W10 +: W10] = data_in10[i*W10 +: W10] + 10'h020;
    end

    // troca rota para reverso
    select[0*SELW +: SELW] = 7;
    select[1*SELW +: SELW] = 6;
    select[2*SELW +: SELW] = 5;
    select[3*SELW +: SELW] = 4;
    select[4*SELW +: SELW] = 3;
    select[5*SELW +: SELW] = 2;
    select[6*SELW +: SELW] = 1;
    select[7*SELW +: SELW] = 0;

    #1;
    $display("out0 W8 (sel=7) apos : %02h (deve refletir nova rota+dado)", data_out8[0*W8 +: W8]);

    #20;

    // =========================================================
    // CASO EXTRA - Máscara de colisão via output_enable
    // Existe colisão em select (0 e 2 -> 7), mas 2 está desabilitado
    // => collision_error deve ser 0 (se monitor usa enable)
    // =========================================================
    $display("\n[CASO EXTRA] output_enable mascarando colisao");
    select = 0;
    output_enable = 8'b11111111;

    // colisão proposital: out0 e out2 escolhem 7
    select[0*SELW +: SELW] = 7;
    select[2*SELW +: SELW] = 7;

    #1;
    $display("collision_error com ambos ativos (esperado 1): %b", collision_error8);

    // mascara: desabilita saídas com colisão
    output_enable[2] = 1'b0;
    output_enable[3] = 1'b0;
    output_enable[4] = 1'b0;
    output_enable[5] = 1'b0;
    output_enable[6] = 1'b0;
    output_enable[7] = 1'b0;

    #1;
    $display("collision_error saídas colididas desativadas (esperado 0): %b", collision_error8);

    $display("\nFim do teste.");
    $finish;
  end

endmodule