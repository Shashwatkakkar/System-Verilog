// Code your testbench here
// or browse Examples
class transaction;
  rand bit [2:0] a,b;
  bit [5:0] out;
  task display();
    $display("a = %0d, b = %0d, out  = %0d",a,b,out);
  endtask
  function transaction copy();
    copy = new();
    copy.a = a;
    copy.b = b;
    copy.out = out;
  endfunction
  constraint data {a!= 0; b!=0;}
endclass
class generator;
  transaction trans;
  mailbox #(transaction) mbx;
  function new(mailbox #(transaction) mbx);
  	this.mbx = mbx;
  endfunction
  task main();
    for(int i=0;i<3;i++) begin
      trans = new();
      trans.randomize();
      mbx.put(trans.copy());
      $display("[GEN] Data sent : a = %0d, b = %0d, time  = %0t",trans.a,trans.b,$time);
      #30;
  	end
  endtask
endclass
interface mul_if;
  logic [2:0] a,b;
  logic clk;
  logic [5:0] out;
endinterface
class driver;
  transaction trans;
  virtual mul_if mif;
  mailbox #(transaction) mbx;
  function new(mailbox #(transaction) mbx);
  	this.mbx = mbx;
  endfunction
  task main();
    forever begin
      mbx.get(trans);
      $display("[DRV] Data received : a = %0d, b = %0d, time = %0t",trans.a,trans.b,$time);
      @(posedge mif.clk)
      mif.a = trans.a;
      mif.b = trans.b;
      $display("[DRV] time = %0t",$time);
    end
  endtask
endclass
class monitor;
  transaction trans;
  mailbox #(transaction) mbx_o;
  virtual mul_if mif;
  function new(mailbox #(transaction) mbx_o);
    this.mbx_o = mbx_o;
  endfunction
  task main();
    forever begin
      trans = new();
      repeat(3) @(posedge mif.clk)
      //trans = new()
      trans.a = mif.a;
      trans.b = mif.b;
      trans.out = mif.out;
      $display("[MON] Data received a = %0d, b = %0d, out = %0d, time = %0t",trans.a,trans.b,trans.out,$time);
      mbx_o.put(trans.copy());
    end
  endtask  
endclass

class scoreboard;
  transaction trans;
  mailbox #(transaction) mbx_o;
  function new(mailbox #(transaction) mbx_o);
  	this.mbx_o = mbx_o;
  endfunction
  task compare(input transaction trans);
    if(trans.out == trans.a*trans.b)
      $display("[SCO] Test pass");
    else
      $display("[SCO] Test Fail");
  endtask
  task main();
    trans = new();
  	forever begin
      mbx_o.get(trans);
      $display("[SCO] Data received : a = %0d, b = %0d, out = %0d",trans.a,trans.b,trans.out);
      compare(trans);
    end
  endtask
endclass

module tb;
  mul_if mif();
  mul dut(.a(mif.a),.b(mif.b),.out(mif.out),.clk(mif.clk));
  generator g;
  driver drv;
  monitor mon;
  scoreboard sco;
  mailbox #(transaction) mbx_o;
  mailbox #(transaction) mbx;
  initial mif.clk = 0;
  always #5 mif.clk = ~mif.clk;
  initial begin
    mbx = new();
    mbx_o = new();
    g = new(mbx);
    drv = new(mbx);
    drv.mif = mif;
    mon = new(mbx_o);
    sco = new(mbx_o);
    mon.mif = mif;
  end
  initial begin
  	fork
      g.main();
      drv.main();
      mon.main();
      sco.main();
    join
  end
  initial begin
  	#300;
    $finish();
  end
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
  
endmodule