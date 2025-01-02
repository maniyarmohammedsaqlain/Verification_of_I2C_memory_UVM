class reset_dut extends uvm_sequence #(transaction);
  `uvm_object_utils(reset_dut);
  
  transaction trans;
  
  function new(string path="rst");
    super.new(path);
  endfunction
  
  
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize());
        trans.op=2;
        `uvm_info("RST",$sformatf("MODE:RST"),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass
