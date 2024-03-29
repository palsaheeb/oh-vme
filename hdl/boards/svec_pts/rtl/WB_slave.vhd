---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for Wishbone Slave port
---------------------------------------------------------------------------------------
-- File           : WB_slave.vhd
-- Author         : auto-generated by wbgen2 from WB_slave.wb
-- Created        : Thu Aug 30 15:04:36 2012
-- Revisioned by  : Davide Pedretti
-- Revision date  : 30/10/2012

---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE WB_slave.wb
-- and it was hand-edit since the original file was not working fine.
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

entity wishbone_port_slave is
generic(g_width      : integer := 32;
	     g_addr_width : integer := 9;
		  g_WB_memory_size : integer := 256;
		  g_num_irq    : integer := 2
	 );
  port (
    rst_n_i                                  : in     std_logic;
    clk_sys_i                                : in     std_logic;
    wb_adr_i                                 : in     std_logic_vector(g_addr_width - 1 downto 0);
    wb_dat_i                                 : in     std_logic_vector(g_width - 1 downto 0);
    wb_dat_o                                 : out    std_logic_vector(g_width - 1 downto 0);
    wb_cyc_i                                 : in     std_logic;
    wb_sel_i                                 : in     std_logic_vector(f_div8(g_width) - 1 downto 0);
    wb_stb_i                                 : in     std_logic;
    wb_we_i                                  : in     std_logic;
    wb_ack_o                                 : out    std_logic;
    wb_stall_o                               : out    std_logic;
    wb_int_o                                 : out    std_logic;
-- Ports for RAM: Memory
    wbslave_ram_addr_i                       : in     std_logic_vector(g_addr_width - 2 downto 0);
-- Read data output
    wbslave_ram_data_o                       : out    std_logic_vector(g_width - 1 downto 0);
-- Read strobe input (active high)
    wbslave_ram_rd_i                         : in     std_logic;
-- Write data input
    wbslave_ram_data_i                       : in     std_logic_vector(g_width - 1 downto 0);
-- Write strobe (active high)
    wbslave_ram_wr_i                         : in     std_logic;
-- Port for std_logic_vector field: 'INT_COUNT' in reg: 'INT_COUNT'
    wbslave_reg_int_count_i                  : in     std_logic_vector(g_width - 1 downto 0);
-- Port for std_logic_vector field: 'INT_RATE' in reg: 'INT_RATE'
    wbslave_reg_int_rate_o                   : out    std_logic_vector(g_width - 1 downto 0);
    irq_irq0_i                               : in     std_logic;
    irq_irq1_i                               : in     std_logic
  );
end wishbone_port_slave;

architecture rtl of wishbone_port_slave is

signal wbslave_ram_rddata_int                   : std_logic_vector(g_width - 1 downto 0);
signal wbslave_ram_rd_int                       : std_logic;
signal wbslave_ram_wr_int                       : std_logic;
signal wbslave_reg_int_rate_int                 : std_logic_vector(g_width - 1 downto 0);
signal wbslave_reg_int_count_int                : std_logic_vector(g_width - 1 downto 0);
signal eic_idr_int                              : std_logic_vector(g_num_irq - 1 downto 0);
signal eic_idr_write_int                        : std_logic;
signal eic_ier_int                              : std_logic_vector(g_num_irq - 1 downto 0);
signal eic_ier_write_int                        : std_logic;
signal eic_imr_int                              : std_logic_vector(g_num_irq - 1 downto 0);
signal eic_imr_reg_int                          : std_logic_vector(g_num_irq - 1 downto 0);
signal eic_isr_status_reg_int                   : std_logic_vector(g_num_irq - 1 downto 0);
signal eic_isr_clear_int                        : std_logic;
signal eic_isr_status_int                       : std_logic_vector(g_num_irq - 1 downto 0);
signal eic_isr_write_int                        : std_logic;
signal irq_inputs_vector_int                    : std_logic_vector(g_num_irq - 1 downto 0);
signal ack_sreg                                 : std_logic_vector(9 downto 0);
signal rddata_reg                               : std_logic_vector(g_width - 1 downto 0);
signal wrdata_reg                               : std_logic_vector(g_width - 1 downto 0);
signal bwsel_reg                                : std_logic_vector(f_div8(g_width) - 1 downto 0);
signal rwaddr_reg                               : std_logic_vector(g_addr_width - 1 downto 0);
signal ack_in_progress                          : std_logic;
signal wr_int                                   : std_logic;
signal rd_int                                   : std_logic;
signal allones                                  : std_logic_vector(g_width - 1 downto 0);
--signal allzeros                                 : std_logic_vector(31 downto 0);

begin
-- Some internal signals assignments. For (foreseen) compatibility with other bus standards.
  wrdata_reg <= wb_dat_i;
  bwsel_reg <= wb_sel_i;
  rd_int <= wb_cyc_i and (wb_stb_i and (not wb_we_i));
  wr_int <= wb_cyc_i and (wb_stb_i and wb_we_i);
  allones <= (others => '1');
--  allzeros <= (others => '0');
-- 
-- Main register bank access process.

process (clk_sys_i)
begin
  if rising_edge(clk_sys_i) then
     ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
     ack_sreg(9) <= '0'; 
    if (rst_n_i = '0') then 
	       ack_sreg <= "0000000000";
          ack_in_progress <= '0';
	 elsif(ack_in_progress = '1') then
	       ack_in_progress <= not ack_sreg(0);
	 else
	       ack_in_progress <= wb_cyc_i and wb_stb_i;
	       ack_sreg(0) <= wb_cyc_i and wb_stb_i;
	 end if;		
  end if;
end process;
-- access bus = read only
-- access dev = write only
-- prefix = int_count
-- size = 32/64
  process (clk_sys_i)
  begin
  if rising_edge(clk_sys_i) then
     if (rst_n_i = '0') then
	     wbslave_reg_int_count_int <= (others => '0');
	   else
		  wbslave_reg_int_count_int <= wbslave_reg_int_count_i;
		end if;
	end if;
	end process;
-- access bus = read/write
-- access dev = read only
-- prefix = int_rate
-- size = 32/64
  process (clk_sys_i)
  begin
  if rising_edge(clk_sys_i) then
     if (rst_n_i = '0') then
	     wbslave_reg_int_rate_int <= (others => '0');
	   elsif rwaddr_reg = "000000101" and wb_we_i = '1' and 
		      (wb_cyc_i = '1') and (wb_stb_i = '1')  then
		  wbslave_reg_int_rate_int <= wrdata_reg;
		end if;
	end if;
	end process;
-- ier register
process (clk_sys_i)
  begin
  if rising_edge(clk_sys_i) then
     if (rst_n_i = '0') then
	      eic_ier_write_int <= '0';
		   eic_ier_int <= (others => '0');
	   elsif rwaddr_reg = "000000001" and wb_we_i = '1' and 
		      (wb_cyc_i = '1') and (wb_stb_i = '1')  then
		   eic_ier_write_int <= '1';
		   eic_ier_int <= wrdata_reg(g_num_irq - 1 downto 0);
		 else
		   eic_ier_write_int <= '0';
		   eic_ier_int <= (others => '0');
		end if;
	end if;
	end process;
-- idr register
process (clk_sys_i)
  begin
  if rising_edge(clk_sys_i) then
     if (rst_n_i = '0') then
	     eic_idr_write_int <= '1';
		  eic_idr_int <= (others => '1');
	   elsif rwaddr_reg = "000000000" and wb_we_i = '1' and 
		      (wb_cyc_i = '1') and (wb_stb_i = '1')  then
		  eic_idr_write_int <= '1';
		  eic_idr_int <= wrdata_reg(g_num_irq - 1 downto 0); 
		else 
		  eic_idr_write_int <= '0';
		  eic_idr_int <= (others => '0');
		end if;
	end if;
	end process;
--interrupt source register
process (clk_sys_i)
  begin
  if rising_edge(clk_sys_i) then
      if (rst_n_i = '0') then
		  eic_isr_write_int <= '0';
	   elsif rwaddr_reg = "000000010" and wb_we_i = '0' and
		      (wb_cyc_i = '1') and (wb_stb_i = '1')  then
			eic_isr_write_int <= '1';
		else
			eic_isr_write_int <= '0';
		end if;
			
  end if;
end process;

  process (rwaddr_reg, wbslave_reg_int_count_int, wbslave_reg_int_rate_int, eic_idr_int, 
           eic_ier_int, eic_imr_reg_int, eic_isr_status_reg_int, wbslave_ram_rddata_int)
  begin
          case rwaddr_reg(g_addr_width - 1) is
			 when '0' => 
			   case rwaddr_reg(3 downto 0) is
               when "0100" => 
				     rddata_reg <= wbslave_reg_int_count_int;
             
               when "0101" => 
                 rddata_reg <= wbslave_reg_int_rate_int;
				  
               when "0000" => 
                 rddata_reg <= std_logic_vector(resize(unsigned(eic_idr_int),rddata_reg'length));
				  
               when "0001" => 
                 rddata_reg <= std_logic_vector(resize(unsigned(eic_ier_int),rddata_reg'length));
				  
               when "0011" => 
                 rddata_reg <= std_logic_vector(resize(unsigned(eic_imr_int),rddata_reg'length));
				  
               when "0010" =>   -- irq status
                 rddata_reg <= std_logic_vector(resize(unsigned(eic_isr_status_int),rddata_reg'length));
				  
               when others => null;
				  
             end case;
			when '1' =>
			    rddata_reg <= wbslave_ram_rddata_int;
         when others =>  null;         
         end case;
  end process;
  
  wb_dat_o <= rddata_reg;
  
-- Read & write lines decoder for RAMs
  process (wb_adr_i, rd_int, wr_int)
  begin
    if (wb_adr_i(g_addr_width - 1) = '1') then
      wbslave_ram_rd_int <= rd_int;
      wbslave_ram_wr_int <= wr_int;
    else
      wbslave_ram_wr_int <= '0';
      wbslave_ram_rd_int <= '0';
    end if;
  end process;
  
  
-- extra code for reg/fifo/mem: Memory
-- RAM block instantiation for memory: Memory
  wbslave_ram_raminst : wbgen2_dpssram
    generic map (
      g_data_width         => g_width,
      g_size               => g_WB_memory_size,
      g_addr_width         => g_addr_width - 1,
      g_dual_clock         => false,
      g_use_bwsel          => true
    )
    port map (
      clk_a_i              => clk_sys_i,
      clk_b_i              => clk_sys_i,
      addr_b_i             => wbslave_ram_addr_i,
      addr_a_i             => rwaddr_reg(g_addr_width - 2 downto 0),
      data_b_o             => wbslave_ram_data_o,
      rd_b_i               => wbslave_ram_rd_i,
      data_b_i             => wbslave_ram_data_i,
      wr_b_i               => wbslave_ram_wr_i,
      bwsel_b_i            => bwsel_reg,-- allones(f_div8(g_width) - 1 downto 0), 
      data_a_o             => wbslave_ram_rddata_int,
      rd_a_i               => wbslave_ram_rd_int,
      data_a_i             => wrdata_reg,
      wr_a_i               => wbslave_ram_wr_int,
      bwsel_a_i            => wb_sel_i
    );
  
-- INT_COUNT
-- INT_RATE
  wbslave_reg_int_rate_o <= wbslave_reg_int_rate_int;

  eic_irq_controller_inst : wbgen2_eic
    generic map (
      g_num_interrupts     => g_num_irq,
      g_irq00_mode         => 0,
      g_irq01_mode         => 1,
      g_irq02_mode         => 0,
      g_irq03_mode         => 0,
      g_irq04_mode         => 0,
      g_irq05_mode         => 0,
      g_irq06_mode         => 0,
      g_irq07_mode         => 0,
      g_irq08_mode         => 0,
      g_irq09_mode         => 0,
      g_irq0a_mode         => 0,
      g_irq0b_mode         => 0,
      g_irq0c_mode         => 0,
      g_irq0d_mode         => 0,
      g_irq0e_mode         => 0,
      g_irq0f_mode         => 0,
      g_irq10_mode         => 0,
      g_irq11_mode         => 0,
      g_irq12_mode         => 0,
      g_irq13_mode         => 0,
      g_irq14_mode         => 0,
      g_irq15_mode         => 0,
      g_irq16_mode         => 0,
      g_irq17_mode         => 0,
      g_irq18_mode         => 0,
      g_irq19_mode         => 0,
      g_irq1a_mode         => 0,
      g_irq1b_mode         => 0,
      g_irq1c_mode         => 0,
      g_irq1d_mode         => 0,
      g_irq1e_mode         => 0,
      g_irq1f_mode         => 0
    )
    port map (
      clk_i                => clk_sys_i,
      rst_n_i              => rst_n_i,
      irq_i                => irq_inputs_vector_int,
--      irq_ack_o            => eic_irq_ack_int,
      reg_imr_o            => eic_imr_int,
      reg_ier_i            => eic_ier_int,
      reg_ier_wr_stb_i     => eic_ier_write_int,
      reg_idr_i            => eic_idr_int,
      reg_idr_wr_stb_i     => eic_idr_write_int,
      reg_isr_o            => eic_isr_status_int,
      --reg_isr_i            => eic_isr_clear_int,
      reg_isr_wr_stb_i     => eic_isr_clear_int,
      wb_irq_o             => wb_int_o
    );
  
  irq_inputs_vector_int(0) <= irq_irq0_i;
  irq_inputs_vector_int(1) <= irq_irq1_i;
  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
-- ACK signal generation. Just pass the LSB of ACK counter.
  eic_isr_clear_int <= ack_sreg(0) and eic_isr_write_int;
  wb_ack_o <= ack_sreg(0);
end rtl;
