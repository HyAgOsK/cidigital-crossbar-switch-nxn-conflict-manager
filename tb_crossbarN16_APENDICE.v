//@Hyago
`timescale 1ns/1ns

module tb_Crossbar_Switch;

  localparam N   = 16;
  localparam W8  = 8;
  localparam W16 = 16;
  localparam W10 = 10;

  localparam SELW = $clog2(N);

  reg  [N*SELW-1:0] select;
  reg  [N-1:0]      output_enable;

  // W=8
  reg  [N*W8-1:0]   data_in8;
  wire [N*W8-1:0]   data_out8;
  wire              collision_error8;

  crossbar_switch #(N, W8) dut8 (
    .data_in(data_in8),
    .select(select),
    .output_enable(output_enable),
    .data_out(data_out8),
    .collision_error(collision_error8)
  );

  // W=16
  reg  [N*W16-1:0]  data_in16;
  wire [N*W16-1:0]  data_out16;
  wire              collision_error16;

  crossbar_switch #(N, W16) dut16 (
    .data_in(data_in16),
    .select(select),
    .output_enable(output_enable),
    .data_out(data_out16),
    .collision_error(collision_error16)
  );

  // W=10
  reg  [N*W10-1:0]  data_in10;
  wire [N*W10-1:0]  data_out10;
  wire              collision_error10;

  crossbar_switch #(N, W10) dut10 (
    .data_in(data_in10),
    .select(select),
    .output_enable(output_enable),
    .data_out(data_out10),
    .collision_error(collision_error10)
  );

  integer i;

  // ----------------------------------------------------------
  // TASKS AUXILIARES
  // ----------------------------------------------------------
  task set_identity_routes;
    integer k;
    begin
      select = {N*SELW{1'b0}};
      for (k = 0; k < N; k = k + 1)
        select[k*SELW +: SELW] = k;
    end
  endtask

  task set_reverse_routes;
    integer k;
    begin
      select = {N*SELW{1'b0}};
      for (k = 0; k < N; k = k + 1)
        select[k*SELW +: SELW] = (N-1-k);
    end
  endtask

  task print_state;
    integer k;
    begin
      $display(" ");
      $display("Tempo: %0t ns", $time);

      $write("Rotas         : {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%0d", select[k*SELW +: SELW]);
        if (k > 0) $write(".");
      end
      $write("}\n");

      $write("Output Enable : {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%b", output_enable[k]);
        if (k > 0) $write(".");
      end
      $write("}\n");

      $write(">> (W=8)  Data In : {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%02h", data_in8[k*W8 +: W8]);
        if (k > 0) $write(".");
      end
      $write("}\n");

      $write(">> (W=8)  Data Out: {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%02h", data_out8[k*W8 +: W8]);
        if (k > 0) $write(".");
      end
      $write("} | Collision Error: %b\n", collision_error8);

      $write(">> (W=16) Data In : {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%04h", data_in16[k*W16 +: W16]);
        if (k > 0) $write(".");
      end
      $write("}\n");

      $write(">> (W=16) Data Out: {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%04h", data_out16[k*W16 +: W16]);
        if (k > 0) $write(".");
      end
      $write("} | Collision Error: %b\n", collision_error16);

      $write(">> (W=10) Data In : {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%03h", data_in10[k*W10 +: W10]);
        if (k > 0) $write(".");
      end
      $write("}\n");

      $write(">> (W=10) Data Out: {");
      for (k = N-1; k >= 0; k = k - 1) begin
        $write("%03h", data_out10[k*W10 +: W10]);
        if (k > 0) $write(".");
      end
      $write("} | Collision Error: %b\n", collision_error10);
    end
  endtask

  // ----------------------------------------------------------
  // "MONITOR" via evento
  // ----------------------------------------------------------
  initial begin
    forever begin
      @(select or output_enable or data_in8 or data_out8 or collision_error8
        or data_in16 or data_out16 or collision_error16
        or data_in10 or data_out10 or collision_error10);
      #0;
      print_state;
    end
  end

  // ----------------------------------------------------------
  // ESTÍMULOS
  // ----------------------------------------------------------
  initial begin
    $display("\n=== TB CROSSBAR COMPLETO (N=16 | W=8,16,10) ===\n");

    // Inicialização
    data_in8       = 0;
    data_in16      = 0;
    data_in10      = 0;
    select         = 0;
    output_enable  = 0;

    for (i = 0; i < N; i = i + 1) begin
      data_in8 [i*W8  +: W8 ] = 8'h10   + i;   // 10 .. 1F
      data_in16[i*W16 +: W16] = 16'h1000 + i;  // 1000 .. 100F
      data_in10[i*W10 +: W10] = 10'h100 + i;   // 100 .. 10F
    end

    output_enable = {N{1'b1}};
    set_identity_routes();

    #5;

    // =========================================================
    // CASO 1 - Roteamento paralelo completo (16 rotas sem colisão)
    // =========================================================
    $display("\n[CASO 1] Roteamento paralelo completo (sem colisao)");
    output_enable = {N{1'b1}};
    set_reverse_routes();

    #1;
    $display("  >> collision_error8  (esperado 0): %b", collision_error8);
    $display("  >> collision_error16 (esperado 0): %b", collision_error16);
    $display("  >> collision_error10 (esperado 0): %b", collision_error10);

    #20;

    // =========================================================
    // CASO 2 - Conflito real
    // saídas 0,1,2 acessam a mesma entrada 3
    // =========================================================
    $display("\n[CASO 2] Conflito real (out0,out1,out2 -> in3)");
    output_enable = {N{1'b1}};
    set_identity_routes();

    select[0*SELW +: SELW] = 3;
    select[1*SELW +: SELW] = 3;
    select[2*SELW +: SELW] = 3;

    #1;
    $display("  >> collision_error8  (esperado 1): %b", collision_error8);
    $display("  >> collision_error16 (esperado 1): %b", collision_error16);
    $display("  >> collision_error10 (esperado 1): %b", collision_error10);

    #20;

    // =========================================================
    // CASO 3 - Enable em tempo real
    // desabilita saída 4
    // =========================================================
    $display("\n[CASO 3] Enable em tempo real (desabilita out4)");
    output_enable = {N{1'b1}};
    set_identity_routes();

    #1;
    $display("  >> out4 W8  antes disable : %02h", data_out8 [4*W8  +: W8 ]);
    $display("  >> out4 W16 antes disable : %04h", data_out16[4*W16 +: W16]);
    $display("  >> out4 W10 antes disable : %03h", data_out10[4*W10 +: W10]);

    output_enable[4] = 1'b0;

    #1;
    $display("  >> out4 W8  apos disable  : %02h (esperado 00)",   data_out8 [4*W8  +: W8 ]);
    $display("  >> out4 W16 apos disable  : %04h (esperado 0000)", data_out16[4*W16 +: W16]);
    $display("  >> out4 W10 apos disable  : %03h (esperado 000)",  data_out10[4*W10 +: W10]);

    output_enable[4] = 1'b1;

    #1;
    $display("  >> out4 W8  reenable      : %02h", data_out8 [4*W8  +: W8 ]);
    $display("  >> out4 W16 reenable      : %04h", data_out16[4*W16 +: W16]);
    $display("  >> out4 W10 reenable      : %03h", data_out10[4*W10 +: W10]);

    #20;

    // =========================================================
    // CASO 4 - Mudança dinâmica de dados + rota
    // =========================================================
    $display("\n[CASO 4] Mudanca dinamica (dados + rota)");
    output_enable = {N{1'b1}};
    set_identity_routes();

    #1;
    $display("  >> out0 W8  (sel=0)  antes: %02h", data_out8 [0*W8  +: W8 ]);
    $display("  >> out0 W16 (sel=0)  antes: %04h", data_out16[0*W16 +: W16]);
    $display("  >> out0 W10 (sel=0)  antes: %03h", data_out10[0*W10 +: W10]);

    for (i = 0; i < N; i = i + 1) begin
      data_in8 [i*W8  +: W8 ] = data_in8 [i*W8  +: W8 ] + 8'h20;
      data_in16[i*W16 +: W16] = data_in16[i*W16 +: W16] + 16'h0020;
      data_in10[i*W10 +: W10] = data_in10[i*W10 +: W10] + 10'h020;
    end

    set_reverse_routes();

    #1;
    $display("  >> out0 W8  (sel=15) apos : %02h", data_out8 [0*W8  +: W8 ]);
    $display("  >> out0 W16 (sel=15) apos : %04h", data_out16[0*W16 +: W16]);
    $display("  >> out0 W10 (sel=15) apos : %03h", data_out10[0*W10 +: W10]);

    #20;

    // =========================================================
    // CASO 5 - Máscara de colisão via output_enable
    // out0 e out2 -> in7, mas out2 é desabilitada depois e também out7
    // =========================================================
    $display("\n[CASO 5] output_enable mascarando colisao");
    output_enable = {N{1'b1}};
    set_identity_routes();

    select[0*SELW +: SELW] = 7;
    select[2*SELW +: SELW] = 7;
    select[7*SELW +: SELW] = 8;

    #1;
    $display("  >> collision_error8  com ambos ativos (esperado 1): %b", collision_error8);
    $display("  >> collision_error16 com ambos ativos (esperado 1): %b", collision_error16);
    $display("  >> collision_error10 com ambos ativos (esperado 1): %b", collision_error10);

    output_enable[2] = 1'b0;
    output_enable[7] = 1'b0;

    #1;
    $display("  >> collision_error8  com out2 e out7 desabilitada (esperado 0): %b", collision_error8);
    $display("  >> collision_error16 com out2 e out7 desabilitada (esperado 0): %b", collision_error16);
    $display("  >> collision_error10 com out2 e out7 desabilitada (esperado 0): %b", collision_error10);

    #20;

    $display("\nFim do teste.\n");
    $finish;
  end

endmodule
