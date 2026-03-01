module collision_monitor #(
    parameter N = 8
)(
    input  wire [N*$clog2(N)-1:0] select,
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

                if (sel_i == sel_j)
                    collision_error = 1'b1;
            end
        end
    end

endmodule