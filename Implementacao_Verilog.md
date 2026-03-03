# Implementação Verilog

---

## `barrel_shifter.v` V0 - Controle

O módulo barrel shifter, de toração circular po palavras, de largura W sobre um vetor que contem N entradas.

### O que este módulo faz:

- A entrada `in`  é vista como N portas, cada um com W bits;
- O sinal `shift` define quantas posições esses blocos vão ser rotacionados circularmente.
- A saída `out`  é o mesmo conjunto de blocos, porém rotacionado, conforme o valor de shift.

A técnica usada é **duplicar** o vetor (`in_double = {in, in}`) para permitir selecionar uma “janela” contínua de N blocos.

### Entradas

- `in [N*W-1:0]` Vetor com N blocos de W bits conectados.
- `shift [$clog2(N)-1:0]` quantidade de rotação (0 até N-1, posições), em unidades de bloco. de bits

### Saída

- `out [N*W-1:0]` Quantidade de rotação (0 até N-1 posições), N possiveis possições, de um bloco de bits.

### Lógica

o bloco `k` de `out` recebe o bloco `(k + shift)` de `in` (com retorno circular).

## Testbench `barrel_shifter.v`

Entrada dos dados com N=8, para W=8, W=16, W=10 (sem ser potência de 2)

```verilog
    in8  = {8'h07, 8'h06, 8'h05, 8'h04, 8'h03, 8'h02, 8'h01, 8'h00};
    in16 = {16'h1007, 16'h1006, 16'h1005, 16'h1004, 16'h1003, 16'h1002, 16'h1001, 16'h1000};
    in10 = {10'h107, 10'h106, 10'h105, 10'h104, 10'h103, 10'h102, 10'h101, 10'h100};
```

Waves

![image.png](./images/b0a505fd-652d-4475-a91d-466adcf29960.png)

![image.png](./images/d163bdf1-2293-4715-84df-b52d1c814897.png)

![image.png](./images/image.png)

Para W=10 usaremos a análise em binário

![image.png](./images/image%201.png)

![image.png](./images/image%202.png)

![image.png](./images/image%203.png)

Terminal:

    -- Caso 1: N=8, W=8 ---

    in : 00 01 02 03 04 05 06 07

    sh=0 | out : 00 01 02 03 04 05 06 07

    sh=1 | out : 01 02 03 04 05 06 07 00

    sh=2 | out : 02 03 04 05 06 07 00 01

    sh=3 | out : 03 04 05 06 07 00 01 02

    sh=4 | out : 04 05 06 07 00 01 02 03

    sh=5 | out : 05 06 07 00 01 02 03 04

    sh=6 | out : 06 07 00 01 02 03 04 05

    sh=7 | out : 07 00 01 02 03 04 05 06

    -- Caso 2: N=8, W=16 ---

    in : 1000 1001 1002 1003 1004 1005 1006 1007

    sh=0 | out : 1000 1001 1002 1003 1004 1005 1006 1007

    sh=1 | out : 1001 1002 1003 1004 1005 1006 1007 1000

    sh=2 | out : 1002 1003 1004 1005 1006 1007 1000 1001

    sh=3 | out : 1003 1004 1005 1006 1007 1000 1001 1002

    sh=4 | out : 1004 1005 1006 1007 1000 1001 1002 1003

    sh=5 | out : 1005 1006 1007 1000 1001 1002 1003 1004

    sh=6 | out : 1006 1007 1000 1001 1002 1003 1004 1005

    sh=7 | out : 1007 1000 1001 1002 1003 1004 1005 1006

    -- Caso 3: N=8, W=10 ---

    in : 100 101 102 103 104 105 106 107

    sh=0 | out : 100 101 102 103 104 105 106 107

    sh=1 | out : 101 102 103 104 105 106 107 100

    sh=2 | out : 102 103 104 105 106 107 100 101

    sh=3 | out : 103 104 105 106 107 100 101 102

    sh=4 | out : 104 105 106 107 100 101 102 103

    sh=5 | out : 105 106 107 100 101 102 103 104

    sh=6 | out : 106 107 100 101 102 103 104 105

    sh=7 | out : 107 100 101 102 103 104 105 106

## Modulo barrel_shifter

```verilog
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
```

---

## Análise da arquitetura de hardware

### Crossbar Switch NxN: Barrel Shifter Camada Única com Barramento de W Bits:

- Quantidade de mapeamentos cheios suportados: N (em contraste com N! de um CS Tradicional);
    - Deslocamento à esquerda (com N=4: {3, 2, 1, 0} -> {2, 1, 0, 3} -> {1, 0, 3, 2} -> {0, 3, 2, 1} ).
- Circuito 100% combinacional;
- Quantidade de camadas: 1 (Crossbar Switch Tradicional);
    - Quantidade de muxes na camada: $N$ muxes Nx1;
- Fios com potencial de interseção: $N²W-2 = O(N²W)$;
- Atraso de propagação: $O(1)$;
- Fan-out dos buffers de entrada: $N$;
- Conversor de código: 1 conversor empregado
    - Entrada: "shift";
    - Saídas: sinais que controlam os seletores dos muxes.

**Conclusão**: Baixo tempo de propagação, mas redução de possíveis mapeamentos e roteamento de barramentos complexo.

- Para crossbar switches, é uma abordagem sem benefícios: mais cara do que um crossbar switch tradicional para uma piora na capacidade de mapeamentos.

### Crossbar Switch NxN: N Barrel Shifters Camada Única (Permutativo), com Barramento de W Bits:

- Quantidade de mapeamentos cheios suportados: N! (todos os mapeamentos possíveis);
- Circuito 100% combinacional;
- Quantidade de camadas: 1 (N Crossbar Switches Tradicionais);
    - Quantidade de muxes na camada: $N^2$ muxes Nx1;
- Fios com potencial de interseção: $N^3W-2 = O(N^3W)$;
- Atraso de propagação: $O(1)$;
- Fan-out dos buffers de entrada: $N²$;
- Conversores de código: N conversores empregados
    - Entrada: "shift";
    - Saídas: sinais que controlam os seletores dos N muxes de seu respectivo Crossbar Switch Tradicional.

**Conclusão**: Baixo tempo de propagação e permite as N! combinações de mapeamentos, mas roteamento de barramentos de complexidade elevada e baixa eficiência no uso de recursos.

- Eficiência < 1/n na utilização de recursos em comparação com o uso de um único barrel shifter.

![Crossbar Switch N Barrel Shifters Camada Única Combinatorial EDITED.jpg](./images/Crossbar_Switch_N_Barrel_Shifters_Camada_nica_Combinatorial_EDITED.jpg)



---

## Testbench BarrelShifter

```verilog
//@Hyago
`timescale 1ns/1ps

module tb_barrel_shifter;

  parameter N   = 8;
  parameter W8  = 8;
  parameter W16 = 16;
  parameter W10 = 10;
  // Configurar N

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
```

---

## `collision_monitor.v`- Monitoramento

O módulo de colisão, monitora basicamente o nosso barramento select, que contém N selecções e levanta a flag `collision_error`  quando detecta colisão **(duas ou mais saídas escolheram a mesma entrada).**

Seu funcionamento se da por:

- O vetor `select` tem N campos, cada campo com largura log2(N) bits.
    - Para N=8, cada campo tem 3 bits, então select tem 8*3 = 24 bits.
- O módulo varre todas as combinações de pares (i, j) com j > i (sempre 1 a frente, para justamente ver)
    - extrai `sel_i`  do pedaço `select[i*log2(N) +: log2(N)]`
    - extrai `sel_j`  do pedaço `select[j*log2(N) +: log2(N)]`
    - Se `output_enable[i] == output_enable[j]` então, as saídas estão habilitadas, consequentemente, se:
        - Se `sel_i == sel_j` , as seleções para cada saída é igual, então existe colisão → `collision_error`  = 1.

## Testbench `collision_monitor.v`

Entrada feita por uma task que ira receber os valores auxiliares para montar o barramento

```verilog
  // auxiliares p/ montar o barramento (sel0 é o LSB do select)
  reg [SELW-1:0] s0, s1, s2, s3, s4, s5, s6, s7;

  task pack_select;
    begin
      select = {s7,s6,s5,s4,s3,s2,s1,s0};
    end
  endtask
  
  // auxiliar para output enable
  reg e0, e1, e2, e3, e4, e5, e6, e7;
  task enable_select;
    begin
      output_enable = {e7,e6,e5,e4,e3,e2,e1,e0};
    end
  endtask
```

![image.png](./images/image%204.png)

- **Caso 1 - Sem colisão**
    - `output_enable = 11111111` (todas as saídas habilitadas)
    - `select = [0,1,2,3,4,5,6,7]` (cada saída escolhe uma entrada diferente)
    - **Esperado:** `collision_error = 0`
- **Caso 2 - Colisão simples**
    - `output_enable = 11111111` (todas habilitadas)
    - `select` com repetição: `s2 = 3` e `s5 = 3` (duas saídas apontam para a mesma entrada)
    - **Esperado:** `collision_error = 1`
- **Caso 3 - Máscara (output_enable) mascarando colisão**
    - `output_enable` desabilita a saída 2: `e2 = 0` (as demais ficam 1)
    - `select` é igual ao Caso 2 (a repetição ainda existe em `s2` e `s5`)
    - **Ideia do teste:** como `s2` está desabilitado, a colisão **deveria ser ignorada** e sobrar só `s5=3` habilitado
    - **Esperado (se o monitor considera enable):** `collision_error = 0`
- **Caso 4 - Colisão com máscara parcial**
    - `output_enable` desabilita a saída 1: `e1 = 0` (as demais ficam 1)
    - `select = [7,5,5,3,3,2,1,0]` (há entradas repetidas: `5` e `3`)
        - colisão em `s1=s2=5` **mas `s1` está desabilitado** (pode “sumir”)
        - colisão em `s3=s4=3` **ambas habilitadas** (deve permanecer)
    - **Esperado:** `collision_error = 1`
    
    ---
    

```verilog
module collision_monitor #(
    parameter N = 8
)(
    input  wire [N*$clog2(N)-1:0] select,
    input wire [N-1:0] output_enable,
    output reg  collision_error
);

    integer i, j;

    reg [$clog2(N)-1:0] sel_i;
    reg [$clog2(N)-1:0] sel_j;

    always @(*) begin
        collision_error = 1'b0;
				
        for (i = 0; i < N; i = i + 1) begin
            sel_i = select[i*$clog2(N) +: $clog2(N)];
            for (j = i+1; j < N; j = j + 1) begin
                sel_j = select[j*$clog2(N) +: $clog2(N)];
                // verificando saidas habilitadas
                if(output_enable[i] && output_enable[j]) begin
                    // verificando se as saídas são as mesmas
                    if (sel_i == sel_j) begin
                        collision_error = 1'b1;
                    end
                end
            end
        end
    end

endmodule
```

---

### Detalhes sobre as caracterísicas do Collision Monitor

→ Complexidade: O(N^2)

→ Número de combinações: N(N-1)/2

```verilog
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
```

---

## `crossbar_nxn` - Dados

Este é o módulo top Level, de um Crossbar Switch NxN, que roteia N entradas de dados para N saídas, com os requisitos que foi solicitado no Tema deste Projeto:

- [x]  Seleção indendente por saída (cada saída escolhe qual entrada quer).
- [x]  enable individual, por saída (pode desligar uma saída para “mascarar colisão, ou ativar”.
- [x]  detecção global de colisão (se duas saídas ou mais escolherem a mesma entrada)

### Entradas

- `data_in [N*W-1:0]`  É o barramento de entrada que contém N palavras de W bits concatenados.
- `select [N*log2(N)-1:0]` Vetor com N seletores, um por saída (Barrel Shifter).
- `output_enable [N-1:0]` Enable individual por saída, caso no índice do vetor, esteja “1”, indica que esta ativo (roteia o dado selecionado) caso contrário “0”, saída forçada para zero.

### Saídas

- `data_out [N*W-1:0]` Barramento com N palavras de W bits cada, por saída.
- `collision_error` Flag global que indica erro, igual anteriormente, “1” se duas ou mais saídas escolherem a mesma entrada, e “0”, se as seleções forem únicas.

O módulo instancia inicialmente o `collision_monitor` e elecompara todos os seletores dentro de select, e levanta `collision_error` se houver repetição.

Basicamente 1 barrel shifter por saída (uma linha por saída usando barrel shifter. Para cada saída i, (loop generate):

→ Extraímos o seletor da saída com `sel`

→ Rodamos o barrel Shifter, do barramento inteiro (`data_in`) usando `sel`

Barrel Shifter rotaciona os N blocos de `data_in`  de forma circular. Com o comportamento esperado de um claássico Barrel Shifter.

Depois disso, pega a posição 0 do barramento rotacionado, que passa a ser exatamente a entrada selecionada, sendo `shifted_bus[0*W +: W].`  Caso o `output_enable` estiver ativo, caso contrário concatena com zero.

### Objetivo do testbench @Bruno

- [x]  Validar roteamento **independente por saída** (cada saída escolhe a entrada desejada).
- [x]  Validar `output_enable` **forçando saída para zero** quando desabilitado.
- [x]  Validar `collision_error` **quando duas ou mais saídas escolhem a mesma entrada**.
- [x]  Mostrar resultados de forma clara no console (`$display`) e na waveform.
- [x]  N ≥ 8 e W≥8 testar automaticamente, (instancie várias vezes o crossbar igual o barrel shifter que eu fiz que você consegue resolver isso) Altere RB para o nome igual ao que temos na instancia.

**Fase de Inicialização.**

**Wave e Transcript**

![image.png](./images/image%205.png)

![image.png](./images/image%206.png)

### **Teste 1 — Roteamento básico (Identidade, sem colisão)**

Configuração:

- `output_enable = 111...1` (todas as saídas ativas)
- `select[i] = i`

Esperado:

- `data_out[i] = data_in[i]`
- `collision_error = 0` (ninguém repetiu seleção)

**Teste  Wave e Transcript**

![image.png](image%207.png)

![image.png](image%208.png)

---

### **Teste 2 — Permutação (roteamento simultâneo e independente)**

Configuração:

- todas as saídas ativas
- cada saída escolhe uma entrada **diferente** (ex.: `out0→in5`, `out1→in3`, …)

Esperado:

- `data_out[i]` bate com a entrada escolhida
- `collision_error = 0` (sem repetição)

Esse teste prova que o crossbar faz múltiplas conexões ao mesmo tempo.

**Teste  Wave e Transcript**

![image.png](./images/image%209.png)

![image.png](./images/image%2010.png)

---

### **Teste 3 — Colisão**

Configuração:

- duas saídas escolhem a **mesma** entrada (ex.: `out0→in4` e `out2→in4`)
- saídas ativas

Esperado:

- `collision_error = 1`
- as duas saídas envolvidas recebem o **mesmo dado** (o dado da entrada selecionada)

Esse teste valida o monitoramento global de colisão.

**Teste  Wave e Transcript**

![image.png](./images/image%2011.png)

![image.png](./images/image%2012.png)

---

### **Teste 4 — `output_enable` (mascaramento por saída)**

Configuração:

- `select[i] = i` (identidade)
- algumas saídas desligadas (ex.: `output_enable[3]=0` e `output_enable[6]=0`)

Esperado:

- `data_out[3] = 0` e `data_out[6] = 0`
- as demais saídas continuam roteando normalmente

Esse teste prova o “desligamento” individual e o comportamento de saída forçada a zero.

**Teste  Wave e Transcript**

![image.png](./images/image%2013.png)

![image.png](./images/image%2014.png)

![image.png](./images/image%2015.png)

### **Teste 5 - Testando com variações de N≥8 e W≥8.**

- [ ]  Prioridade é N=8 (teste N>8) W≥8. ( apresentar waves e terminal)

```verilog
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
```

---

### Detalhes sobre a característica do Top Level Crossbar Switch NxN

→ …

---

- Código testbench @Bruno
    
    ```verilog
    @Bruno
    `timescale 1ns/1ps
    
    module tb_crossbar_switch;
    
      localparam N  = 8;
      localparam W  = 8;
      localparam RB = $clog2(N);
    
      reg  [N*W-1:0]  data_in;
      reg  [N*RB-1:0] select;
      reg  [N-1:0]    output_enable;
    
      wire [N*W-1:0]  data_out;
      wire            collision_error;
    
      crossbar_switch #(
        .N(N),
        .W(W)
      ) dut (
        .data_in        (data_in),
        .select         (select),
        .output_enable  (output_enable),
        .data_out       (data_out),
        .collision_error(collision_error)
      );
    
      
      // Funções auxiliares (Helpers)
     // Define que a saída out_idx vai selecionar a entrada in_idx.
      task set_sel;
        input integer out_idx;
        input integer in_idx;
        begin
          select[out_idx*RB +: RB] = in_idx[RB-1:0];
        end
      endtask
      
    // Extrai a palavra W-bit da entrada idx a partir do vetor data_in
      function [W-1:0] in_word;
        input integer idx;
        begin
          in_word = data_in[idx*W +: W];
        end
      endfunction
      
    // Extrai a palavra W-bit da saída idx a partir do vetor data_out
      function [W-1:0] out_word;
        input integer idx;
        begin
          out_word = data_out[idx*W +: W];
        end
      endfunction
    
      // Compara a saída idx com o valor esperado exp.
      // Se falhar, para simulação com $stop.
      task expect_out;
        input integer idx;
        input [W-1:0] exp;
        input [1023:0] label;
        begin
          if (out_word(idx) !== exp) begin
            $display("FAIL: %s | out%0d=0x%0h esperado=0x%0h", label, idx, out_word(idx), exp);
            $stop;
          end else begin
            $display("PASS: %s | out%0d=0x%0h", label, idx, out_word(idx));
          end
        end
      endtask
    
    // Valida collision_error.
      task expect_collision;
        input exp;
        input [1023:0] label;
        begin
          if (collision_error !== exp) begin
            $display("FAIL: %s | collision_error=%b esperado=%b", label, collision_error, exp);
            $stop;
          end else begin
            $display("PASS: %s | collision_error=%b", label, collision_error);
          end
        end
      endtask
      
    // Carrega valores conhecidos nas entradas
      task load_inputs;
        integer k;
        begin
          for (k = 0; k < N; k = k + 1) begin
            data_in[k*W +: W] = (8'hA0 + k[7:0]); // A0, A1, A2...
          end
        end
      endtask
    
      // Mostra um resumo do estado atual:
      // collision_error
    
      task print_summary;
        input [1023:0] title;
        integer k;
        begin
          $display("\n---- %s ----", title);
          $display("collision_error=%b", collision_error);
          for (k = 0; k < N; k = k + 1) begin
            $display("out%0d: enable=%0d sel=%0d -> 0x%0h",
                     k, output_enable[k], select[k*RB +: RB], out_word(k));
          end
        end
      endtask
    
      integer i;
    
      initial begin
        // evita X na wave para o integer i, colocando ele para iniciar em 0
        i = 0;
    
        $display("============================================================");
        $display("TB crossbar_switch | N=%0d W=%0d RB=%0d", N, W, RB);
        $display("============================================================");
    
        // Init sinais do DUT
        data_in = {N*W{1'b0}};
        select  = {N*RB{1'b0}};
        output_enable = {N{1'b0}};
    
        #5;
    
        load_inputs();
    
        $display("\nEntradas:");
        for (i = 0; i < N; i = i + 1)
          $display("in%0d = 0x%0h", i, in_word(i));
    
        // =========================================================
        // TESTE 1: Identidade cada saída seleciona a entrada de mesmo índice
        // =========================================================
        $display("\n[TESTE 1] Identidade (sem colisao): out[i]=in[i]");
        output_enable = {N{1'b1}};
        for (i = 0; i < N; i = i + 1)
          set_sel(i, i);
        #1;
    
        for (i = 0; i < N; i = i + 1)
        expect_out(i, in_word(i), "roteamento identidade");
        expect_collision(1'b0, "sem colisao (sel diferentes)");
        print_summary("RESUMO TESTE 1");
    
        // =========================================================
        // TESTE 2: Permutacao configura as saídas para pegarem entradas diferentes
        // =========================================================
        $display("\n[TESTE 2] Permutacao (sem colisao): roteamento independente");
        output_enable = {N{1'b1}};
        if (N == 8) begin
          set_sel(0, 5);
          set_sel(1, 3);
          set_sel(2, 7);
          set_sel(3, 0);
          set_sel(4, 2);
          set_sel(5, 6);
          set_sel(6, 1);
          set_sel(7, 4);
          #1;
    
          expect_out(0, in_word(5), "out0<-in5");
          expect_out(1, in_word(3), "out1<-in3");
          expect_out(2, in_word(7), "out2<-in7");
          expect_out(3, in_word(0), "out3<-in0");
          expect_out(4, in_word(2), "out4<-in2");
          expect_out(5, in_word(6), "out5<-in6");
          expect_out(6, in_word(1), "out6<-in1");
          expect_out(7, in_word(4), "out7<-in4");
          expect_collision(1'b0, "sem colisao (permuta sem repeticao)");
          print_summary("RESUMO TESTE 2");
        end else begin
          $display("INFO: TESTE 2 foi escrito para N=8. Pulando.");
        end
    
        // =========================================================
        // TESTE 3: Colisao da out0 e out4
        // =========================================================
        $display("\n[TESTE 3] Colisao: out0 e out2 escolhem a mesma entrada (in4)");
        output_enable = {N{1'b1}};
        for (i = 0; i < N; i = i + 1)
          set_sel(i, i);
        set_sel(0, 4);
        set_sel(2, 4);
        #1;
    
        expect_out(0, in_word(4), "out0<-in4 (colisao)");
        expect_out(2, in_word(4), "out2<-in4 (colisao)");
        expect_collision(1'b1, "colisao deve ser 1 quando sel iguais");
        print_summary("RESUMO TESTE 3");
    
        // =========================================================
        // TESTE 4: output_enable **mascaramento da out3 e out6**
        // =========================================================
        $display("\n[TESTE 4] output_enable: saida desabilitada deve ser 0");
        for (i = 0; i < N; i = i + 1)
          set_sel(i, i);
        output_enable = {N{1'b1}};
        output_enable[3] = 1'b0;
        output_enable[6] = 1'b0;
        #1;
    
        expect_out(3, {W{1'b0}}, "out3 desabilitada -> 0");
        expect_out(6, {W{1'b0}}, "out6 desabilitada -> 0");
        expect_out(0, in_word(0), "out0 continua normal");
        expect_out(7, in_word(7), "out7 continua normal");
        print_summary("RESUMO TESTE 4");
    
        $display("\nFINAL: Todos os testes passaram.");
        $finish;
      end
    
    endmodule
    ```
    

---

## Testbench `tb_crossbar_nxn.v` @Hyago Vieira

- [x]  Testbench de Validação:
    - [x]  A simulação deve ser realizada configurando o módulo para uma instância de, no mínimo, N=8 (8 entradas e 8 saídas) e largura de dado W >= 8 bits. O grupo deve demonstrar:
        - [x]  Roteamento Paralelo de Alta Densidade:
            - [x]  Demonstração de pelo menos 4 rotas distintas e simultâneas (ex: Entrada 0 -> Saída 7, Entrada 1 -> Saída 6, etc.),
            - [x]  provando que não há interferência entre os barramentos de dados.
        - [x]  Validação de Conflito (Corner Case):
            - [x]  Forçar uma condição onde múltiplas saídas (ex: Saídas 0, 1 e 2) tentem acessar simultaneamente a mesma entrada.
            - [x]  O grupo deve validar a ativação imediata do sinal collision_error.
        - [x]  Controle de Habilitação:
            - [x]  Demonstração do sinal **enable** atuando em tempo real, garantindo que a saída seja zerada instantaneamente quando desabilitada, independentemente do dado na entrada.
        - [x]  Mudança Dinâmica:
            - [x]  Alterar a configuração de rota durante a transmissão de dados e observar a comutação correta no diagrama de tempos.

- Caso 1 - As saídas todas escolhem a entrada 0 (colisão)

![image.png](./images/image%2016.png)

- Caso 2 - Saídas escolhem as entradas dinamicamente aleatória (sem colisão). Entrada 0 → saída 7, Entrada 1 → saída 6… (não há interferência no barramento)

![image.png](./images/image%2017.png)

- Caso 3 - Saídas 0, 1, 2 escolhem entrada 3 (colisão)

![image.png](./images/image%2018.png)

- Caso 4 - Mudança dinâmica de rota - primeiro ponto, identidade entrada → saída

![image.png](./images/image%2019.png)

- Caso 4.1 - Mudânça dinâmica de rota - desabilitando output_enable para ver saída zerada.

![image.png](./images/image%2020.png)

- Caso 4.2 -  Saída 0, 2 escolhem entrada 7, e o restante entrada 0 (Colisão)

![image.png](./images/image%2021.png)

- Caso 4.3 - Desabilitando output_enable, onde há colisões, e verificando a máscara

![image.png](./images/image%2022.png)

> Observação: Não estamos colocando N≥8. Apenas N=8, se for testar outro valor de N, é necessário que seja, expoente de 2.
> 

2^2 = 4

2^3 = 8

2^4 = 16…

> Caso N seja um número que não seja inteiro na equação que possui o shift dos dados com barrel shifter, log2(N) teremos um valor fracionado. E isto não foi algo definido no projeto.
> 


## Testbench Crossbar Switch top level
```verilog
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
```

---

## Casos de teste

- [x]  Caso A - 4 rotas simultâneas (sem colisão)
    
    Valida o roteamento paralelo com múltiplas saídas ativas e rotas distintas, comprovando ausência de interferência indevida entre barramentos.
    
- [x]  Caso B - Colisão forçada
    
    Força duas saídas habilitadas a selecionarem a mesma entrada e valida a ativação de `collision_error`.
    
- [x]  Caso C -Habilitação/zero + colisão mascarada

Valida:

- precedência da lógica de `output_enable` (saída desabilitada zerada),
- e cenário em que rotas repetidas não geram colisão quando uma das saídas está desabilitada.
- [x]  Caso D - Mudança dinâmica de rota
    
    Altera a rota de uma saída habilitada ao longo do tempo e observa a comutação correta no DUT.
    

### IDE, HDL e Simulador

- VScode
    - Integração rápida com GitHub
    - Contém extensões de renderização de Markdown
    - Integra CLI
- Verilog
    - IEEE 1364-2005 and 1364-1995 (Verilog)
    - Mentor ModelSim - Intel FPGA Starter Edition 2020.1 Rev. 2020.02 - feb, 28 2020

### Estrutura de repositório

- link: …

```verilog
CIDigital_Grupo_2_CrossBar_Switch_NxN/
├── .gitignore               # Arquivos de simulação ignorados
├── README.md                # Trabalho Orientado
├── Barrel_shifter.v         # módulo de barrel shifter
├── collision_monitor.v      # módulo de colisão          
├── Crossbar_switch.v        # módulo top level     
├── tb_Barrel_shifter.v      # teste unitário barrel shifter    
├── tb_colission_monitor.v   # teste unitário de colisão
└── tb_Crossbar_switch.v     # teste TOP LEVEL
```

# Referências bibliográficas

- **Tema 2 — Crossbar Switch NxN com Gerenciamento de Conflitos** (enunciado do projeto).
- **SD192 – Trabalho Orientado I** (orientações da disciplina / módulo).
- IEEE Std 1364 — Verilog Hardware Description Language.
- Documentação e código RTL desenvolvidos pelo grupo (módulos e testbench do projeto.