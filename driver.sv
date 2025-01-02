class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver);
  transaction trans;
  virtual i2c inf;
  function new(string path="drv",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    
    if(!uvm_config_db #(virtual i2c)::get(this,"","inf",inf))
      `uvm_info("DRV","ERROR IN CONFIG DB OF DRV",UVM_NONE);
  endfunction
  
  task reset_dut();
    begin
      `uvm_info("DRV","DUT RESET",UVM_NONE);
      inf.rst<=1;
      inf.addr<=0;
      inf.din<=0;
      inf.wr<=0;
      @(posedge inf.clk);
    end
  endtask
  
  task write();
    begin
      `uvm_info("DRV","WRITE OPERATION",UVM_NONE);
      inf.rst<=0;
      inf.addr<=trans.addr;
      inf.din<=trans.din;
      inf.wr<=1;
      @(posedge inf.done);
    end
  endtask  
  
  task read();
    begin
      `uvm_info("DRV","READ OPERATION",UVM_NONE);
      inf.rst<=0;
      inf.addr<=trans.addr;
      inf.wr<=0;
      inf.din<=0;
      @(posedge inf.done);
    end
  endtask  

  virtual task run_phase(uvm_phase phase);
    forever
      begin
        seq_item_port.get_next_item(trans);
        if(trans.op==2)
          begin
            reset_dut();
          end
        else if(trans.op==1)
          begin
            write();
          end
        else if(trans.op==0)
          begin
            read();
          end
        seq_item_port.item_done(trans);
      end
  endtask
endclass
