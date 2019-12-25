module revolve (
    input clk,
    input rst_n
);


reg [31:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        counter <= 32'b0;
    end else if (clk) begin
        counter <= counter + 32'b1;
    end
end


endmodule

