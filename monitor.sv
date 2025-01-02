class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  transaction trans;
  virtual i2c inf;
  uvm_analysis_port #(transaction)send;
  function new(string path="mon",uvm_component parent=null);
    super.new(path,parent);
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    send=new("send",this);
    if(!uvm_config_db #(virtual i2c)::get(this,"","inf",inf))
      `uvm_info("MON","ERROR IN CONFIG DB OF MON",UVM_NONE);
  endfunction        
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        @(posedge inf.clk);
        if(inf.rst)
          begin
            trans.op=2;
            `uvm_info("MON","RESET DETECTED",UVM_NONE);
            send.write(trans);
          end
        else
          begin
            if(inf.wr)
              begin
                trans.op=1;
                trans.addr=inf.addr;
                trans.din=inf.din;
                trans.wr=1;
                @(posedge inf.done);
                `uvm_info("MON",$sformatf("DATA WRITE addr:%d data:%d",trans.addr,trans.din),UVM_NONE);
                send.write(trans);
              end
            else if(!inf.wr)
              begin
                trans.op=0;
                trans.addr=inf.addr;
                trans.din=inf.din;
                trans.wr=0;
                @(posedge inf.done);
                trans.datard=inf.datard;
                `uvm_info("MON",$sformatf("DATA READ addr:%d data:%d",trans.addr,trans.din),UVM_NONE);
                send.write(trans);
              end
          end
      end
  endtask
endclass
