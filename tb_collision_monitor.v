`timescale 1ns/1ps

module tb_collision_monitor;

  parameter N = 8;
  parameter SELW = $clog2(N);

  reg  [N*SELW-1:0] select;
  reg  [N-1:0] output_enable;
  wire collision_error;


  // DUT
  collision_monitor #(.N(N)) dut (
    .select(select),
    .output_enable(output_enable),
    .collision_error(collision_error)
  );

  // auxiliares p/ montar o barramento (sel0 é o LSB do select)
  reg [SELW-1:0] s0, s1, s2, s3, s4, s5, s6, s7;
  // auxiliar para output enable
  reg e0, e1, e2, e3, e4, e5, e6, e7;

  task pack_select;
    begin
      select = {s7,s6,s5,s4,s3,s2,s1,s0};
    end
  endtask

  task enable_select;
    begin
      output_enable = {e7,e6,e5,e4,e3,e2,e1,e0};
    end
  endtask

  initial begin
    $display("=== TB collision_monitor (N=8) ===");

    // output_enable ativado em todos
    e0=1; e1=1; e2=1; e3=1; e4=1; e5=1; e6=1; e7=1;
    enable_select();
    // Caso 1: sem colisão (0,1,2,3,4,5,6,7)
    s0=0; s1=1; s2=2; s3=3; s4=4; s5=5; s6=6; s7=7;
    pack_select();
    #1;
    $display("Caso 1 collision_error=%b (esperado 0)", collision_error);

    // output_enable ativado em todos
    e0=1; e1=1; e2=1; e3=1; e4=1; e5=1; e6=1; e7=1;
    enable_select();
    // Caso 2: colisão simples (s2 = s5 = 3)
    s0=0; s1=1; s2=3; s3=2; s4=4; s5=3; s6=6; s7=7;
    pack_select();
    #1;
    $display("Caso 2 collision_error=%b (esperado 1)", collision_error);

    // output_enable mascarando a colisao, s2 -> 0 e s5 acessa 3
    e0=1; e1=1; e2=0; e3=1; e4=1; e5=1; e6=1; e7=1;
    enable_select();
    // Caso 3:
    s0=0; s1=1; s2=3; s3=2; s4=4; s5=3; s6=6; s7=7;
    pack_select();
    #1;
    $display("Caso 3 collision_error=%b (esperado 0)", collision_error);

    e0=1; e1=0; e2=1; e3=1; e4=1; e5=1; e6=1; e7=1;
    enable_select();
    // Caso 4: volta COLISÃO em s3, s4 (7,5,5,3,3,2,1,0)
    s0=7; s1=5; s2=5; s3=3; s4=3; s5=2; s6=1; s7=0;
    pack_select();
    #1;
    $display("Caso 4 collision_error=%b (esperado 1)", collision_error);

    $display("Fim do teste.");
    $finish;
  end

endmodule