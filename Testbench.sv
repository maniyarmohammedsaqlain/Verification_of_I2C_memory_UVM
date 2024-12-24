`include "uvm_macros.svh";
import uvm_pkg::*;
class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  randc logic [6:0]addr;
  rand logic [7:0]din;
  logic wr;
  logic [7:0]datard;
  logic done;
  logic [1:0]op;
  
  constraint addr_c{addr<=10;}
  
  function new(string path="trans");
    super.new(path);
  endfunction
endclass

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

class agent extends uvm_agent;
  `uvm_component_utils(agent);
  driver drv;
  monitor mon;
  uvm_sequencer #(transaction)seqr;
  transaction trans;
  function new(string path="a",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans",this);
    mon=monitor::type_id::create("mon",this);
    drv=driver::type_id::create("drv",this);
    seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  agent a;
  sco sc;
  
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a=agent::type_id::create("a",this);
    sc=sco::type_id::create("sc",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(sc.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  wr_data wrd;
  rd_data rdd;
  reset_dut rdut;
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e=env::type_id::create("e",this);
    wrd=wr_data::type_id::create("wrd",this);
    rdd=rd_data::type_id::create("rdd",this);
    rdut=reset_dut::type_id::create("rdut",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rdut.start(e.a.seqr);
    wrd.start(e.a.seqr);
    rdd.start(e.a.seqr);
    phase.drop_objection(this);
  endtask
endclass

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
