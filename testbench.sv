module tb;
  i2c inf();
  i2c_mem DUT(.clk(inf.clk),.rst(inf.rst),.wr(inf.wr),.addr(inf.addr),.din(inf.din),.datard(inf.datard),.done(inf.done));
  
  initial
    begin
      inf.clk=0;
    end
  always
    #10 inf.clk=~inf.clk;
  
  initial
    begin
      uvm_config_db #(virtual i2c)::set(null,"*","inf",inf);
      run_test("test");
    end
endmodule
