`timescale 1ns/1ps

module tb_barrel_shifter;

  parameter N   = 8;
  parameter W8  = 8;
  parameter W16 = 16;
  parameter W10 = 10;

  // Para N=8 => shift tem 3 bits
  reg [$clog2(N)-1:0] shift;

  // ========== DUT W=8 ==========
  reg  [N*W8-1:0]  in8;
  wire [N*W8-1:0]  out8;

  barrel_shifter #(.N(N), .W(W8)) dut_w8 (
    .in(in8),
    .shift(shift),
    .out(out8)
  );

  // ========== DUT W=16 ==========
  reg  [N*W16-1:0] in16;
  wire [N*W16-1:0] out16;

  barrel_shifter #(.N(N), .W(W16)) dut_w16 (
    .in(in16),
    .shift(shift),  
    .out(out16)
  );

  // ========== DUT W=10 ==========
  reg  [N*W10-1:0] in10;
  wire [N*W10-1:0] out10;

  barrel_shifter #(.N(N), .W(W10)) dut_w10 (
    .in(in10),
    .shift(shift),
    .out(out10)
  );

  integer s, k;

  initial begin
    // Padrões em hexadecimal para facilitar leitura (palavra 0 é a mais à direita)
    // (palavra 0 fica no LSB: [W-1:0])
    in8  = {8'h07, 8'h06, 8'h05, 8'h04, 8'h03, 8'h02, 8'h01, 8'h00};
    in16 = {16'h1007, 16'h1006, 16'h1005, 16'h1004, 16'h1003, 16'h1002, 16'h1001, 16'h1000};
    in10 = {10'h107, 10'h106, 10'h105, 10'h104, 10'h103, 10'h102, 10'h101, 10'h100};

    $display("\n==================== TB BARREL_SHIFTER ====================");

    // ------------------- W=8 -------------------
    $display("\n--- Caso 1: N=8, W=8 ---");
    $write("in  : ");
    // Imprime cada palavra de W bits em hexadecimal
    for (k = 0; k < N; k = k + 1) begin
      $write("%02h ", in8[k*W8 +: W8]);
    end
    $write("\n");

    // Varia shift de 0 a N-1 e imprime saída
    for (s = 0; s < N; s = s + 1) begin
      // s = 0,1,2,...,7 -> shift = 0,1,2,...,7
      // [2:0] para garantir que shift seja sempre 3 bits (0 a 7)
      shift = s[2:0];
      #1;
      $write("sh=%0d | out : ", s);
      for (k = 0; k < N; k = k + 1) begin
        $write("%02h ", out8[k*W8 +: W8]);
      end
      $write("\n");
    end

    // ------------------- W=16 -------------------
    $display("\n--- Caso 2: N=8, W=16 ---");
    $write("in  : ");
    for (k = 0; k < N; k = k + 1) begin
      $write("%04h ", in16[k*W16 +: W16]);
    end
    $write("\n");

    for (s = 0; s < N; s = s + 1) begin
      shift = s[2:0];
      #1;
      $write("sh=%0d | out : ", s);
      for (k = 0; k < N; k = k + 1) begin
        $write("%04h ", out16[k*W16 +: W16]);
      end
      $write("\n");
    end

    // ------------------- W=10 -------------------
    $display("\n--- Caso 3: N=8, W=10 ---");
    $write("in  : ");
    for (k = 0; k < N; k = k + 1) begin
      $write("%03h ", in10[k*W10 +: W10]);
    end
    $write("\n");

    for (s = 0; s < N; s = s + 1) begin
      shift = s[2:0];
      #1;
      $write("sh=%0d | out : ", s);
      for (k = 0; k < N; k = k + 1) begin
        $write("%03h ", out10[k*W10 +: W10]);
      end
      $write("\n");
    end

    $display("\nFim do teste.");
    $finish;
  end

endmodule