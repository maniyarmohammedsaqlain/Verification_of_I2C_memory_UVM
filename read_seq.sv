class rd_data extends uvm_sequence #(transaction);
  `uvm_object_utils(rd_data);
  transaction trans;
  function new(string path="rd");
    super.new(path);
  endfunction  
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize());
        trans.op=0;
        `uvm_info("READ",$sformatf("MODE:READ ADDR:%0d",trans.addr),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass
