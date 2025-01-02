class wr_data extends uvm_sequence #(transaction);
  `uvm_object_utils(wr_data);
  transaction trans;
  function new(string path="seq");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize());
        trans.op=1;
        `uvm_info("WRITE",$sformatf("MODE:WRITE ADDR:%0d DATA:%0d",trans.addr,trans.din),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass
