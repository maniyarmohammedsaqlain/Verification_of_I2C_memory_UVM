class sco extends uvm_scoreboard;
  `uvm_component_utils(sco);
  transaction trans;
  uvm_analysis_imp #(transaction,sco)recv;
  bit [7:0] mem[128] = '{default:0};
  bit [7:0] data_rd = 0;
  function new(string path="sco",uvm_component parent=null);
    super.new(path,parent);
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv=new("recv",this);
    trans=transaction::type_id::create("trans",this);
  endfunction
  
  virtual function void write(transaction tr);
    trans=tr;
    if(trans.op==2)
      begin
        `uvm_info("SCO","RESET DETECTED",UVM_NONE);
      end
    else if(trans.op==1)
      begin
        mem[trans.addr]=trans.din;
        `uvm_info("SCO",$sformatf("DATA WRITE OP DATA:%0d ADDR:%0d",trans.din,trans.addr),UVM_NONE);
      end
    else if(trans.op==0)
      begin
        data_rd=mem[trans.addr];
        if(data_rd==trans.datard)
          begin
            `uvm_info("SCO",$sformatf("DATA MATCHED ADDR:%0d RDATA:%0d",trans.addr,trans.datard),UVM_NONE);
          end
        else
          begin
            `uvm_info("SCO",$sformatf("DATA MISMATCHED ADDR:%0d RDATA:%0d ADATA:%0d",trans.addr,trans.datard,data_rd),UVM_NONE);
          end
      end
    $display("-------------------------------xxxxxxxxx------------------------------");
  endfunction
endclass
