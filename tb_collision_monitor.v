`timescale 1ns/1ps

module tb_collision_monitor;

  parameter N = 8;
  parameter SELW = $clog2(N);

  reg  [N*SELW-1:0] select;
  wire collision_error;

  // DUT
  collision_monitor #(.N(N)) dut (
    .select(select),
    .collision_error(collision_error)
  );

  // auxiliares p/ montar o barramento (sel0 é o LSB do select)
  reg [SELW-1:0] s0, s1, s2, s3, s4, s5, s6, s7;

  task pack_select;
    begin
      select = {s7,s6,s5,s4,s3,s2,s1,s0};
    end
  endtask

  initial begin
    $display("=== TB collision_monitor (N=8) ===");

    // Caso 1: sem colisão (0,1,2,3,4,5,6,7)
    s0=0; s1=1; s2=2; s3=3; s4=4; s5=5; s6=6; s7=7;
    pack_select();
    #1;
    $display("Caso 1 (sem colisao): collision_error=%b (esperado 0)", collision_error);

    // Caso 2: colisão simples (s2 = s5 = 3)
    s0=0; s1=1; s2=3; s3=2; s4=4; s5=3; s6=6; s7=7;
    pack_select();
    #1;
    $display("Caso 2 (colisao s2=s5): collision_error=%b (esperado 1)", collision_error);

    // Caso 3: todos iguais (colisao)
    s0=4; s1=4; s2=4; s3=4; s4=4; s5=4; s6=4; s7=4;
    pack_select();
    #1;
    $display("Caso 3 (todos iguais): collision_error=%b (esperado 1)", collision_error);

    // Caso 4: volta para sem colisão (7,6,5,4,3,2,1,0)
    s0=7; s1=6; s2=5; s3=4; s4=3; s5=2; s6=1; s7=0;
    pack_select();
    #1;
    $display("Caso 4 (sem colisao): collision_error=%b (esperado 0)", collision_error);

    $display("Fim do teste.");
    $finish;
  end

endmodule