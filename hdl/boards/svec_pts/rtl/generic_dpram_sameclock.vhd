-------------------------------------------------------------------------------
-- Title      : Parametrizable dual-port synchronous RAM (Xilinx version)
-- Project    : Generics RAMs and FIFOs collection
-------------------------------------------------------------------------------
-- File       : generic_dpram_sameclock.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2011-01-25
-- Last update: 2012-03-28
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: True dual-port synchronous RAM for Xilinx FPGAs with:
-- - configurable address and data bus width
-- - byte-addressing mode (data bus width restricted to multiple of 8 bits)
-- Todo:
-- - loading initial contents from file
-- - add support for read-first/write-first address conflict resulution (only
--   supported by Xilinx in VHDL templates)
-------------------------------------------------------------------------------
-- Copyright (c) 2011 CERN
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2011-01-25  1.0      twlostow        Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

entity generic_dpram_sameclock is

  generic (
    g_data_width : natural;
    g_size       : natural;

    g_with_byte_enable         : boolean;
    g_addr_conflict_resolution : string  := "read_first";
    g_init_file                : string  := "";
    g_init_value               : t_generic_ram_init := c_generic_ram_nothing;
    g_fail_if_file_not_found   : boolean
    );

  port (
    rst_n_i : in std_logic := '1';      -- synchronous reset, active LO

    -- Port A
    clk_i : in std_logic;

    bwea_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    wea_i  : in  std_logic;
    aa_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    da_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qa_o   : out std_logic_vector(g_data_width-1 downto 0);

    -- Port B
    bweb_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    web_i  : in  std_logic;
    ab_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    db_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qb_o   : out std_logic_vector(g_data_width-1 downto 0)
    );

end generic_dpram_sameclock;



architecture syn of generic_dpram_sameclock is

  constant c_num_bytes : integer := (g_data_width+7)/8;


  type t_ram_type is array(0 to g_size-1) of std_logic_vector(g_data_width-1 downto 0);

  function f_memarray_to_ramtype(arr : t_meminit_array) return t_ram_type is
    variable tmp    : t_ram_type;
    variable n, pos : integer;
  begin
    pos := 0;
    while(pos < g_size)loop
      n := 0;
      -- avoid ISE loop iteration limit
      while (pos < g_size and n < 4096) loop
        for i in 0 to g_data_width-1 loop
          tmp(pos)(i) := arr(pos, i);
        end loop;  -- i
        n   := n+1;
        pos := pos + 1;
      end loop;
    end loop;
    return tmp;
  end f_memarray_to_ramtype;

  function f_file_contents return t_meminit_array is
  begin
    if g_init_value'length > 0 then
      return g_init_value;
    else
      return f_load_mem_from_file(g_init_file, g_size, g_data_width, g_fail_if_file_not_found);
    end if;
  end f_file_contents;
  
  shared variable ram : t_ram_type := f_memarray_to_ramtype(f_file_contents);

  signal s_we_a     : std_logic_vector(c_num_bytes-1 downto 0);
  signal s_ram_in_a : std_logic_vector(g_data_width-1 downto 0);
  signal s_we_b     : std_logic_vector(c_num_bytes-1 downto 0);
  signal s_ram_in_b : std_logic_vector(g_data_width-1 downto 0);


  signal wea_rep, web_rep : std_logic_vector(c_num_bytes-1 downto 0);

begin

  wea_rep <= (others => wea_i);
  web_rep <= (others => web_i);

  s_we_a <= bwea_i and wea_rep;
  s_we_b <= bweb_i and web_rep;

  gen_with_byte_enable_readfirst : if(g_with_byte_enable = true and g_addr_conflict_resolution = "read_first") generate

    process (clk_i)
    begin
      if rising_edge(clk_i) then
        qa_o <= ram(to_integer(unsigned(aa_i)));
        qb_o <= ram(to_integer(unsigned(ab_i)));
        for i in 0 to c_num_bytes-1 loop
          if s_we_a(i) = '1' then
            ram(to_integer(unsigned(aa_i)))((i+1)*8-1 downto i*8) := da_i((i+1)*8-1 downto i*8);
          end if;
          if(s_we_b(i) = '1') then
            ram(to_integer(unsigned(ab_i)))((i+1)*8-1 downto i*8) := db_i((i+1)*8-1 downto i*8);
          end if;
        end loop;
      end if;
    end process;

  end generate gen_with_byte_enable_readfirst;



  gen_without_byte_enable_readfirst : if(g_with_byte_enable = false and g_addr_conflict_resolution = "read_first") generate

    process(clk_i)
    begin
      if rising_edge(clk_i) then
        qa_o <= ram(to_integer(unsigned(aa_i)));
        qb_o <= ram(to_integer(unsigned(ab_i)));
        if(wea_i = '1') then
          ram(to_integer(unsigned(aa_i))) := da_i;
        end if;
        if(web_i = '1') then
          ram(to_integer(unsigned(ab_i))) := db_i;
        end if;
      end if;
    end process;
  end generate gen_without_byte_enable_readfirst;

  gen_without_byte_enable_writefirst : if(g_with_byte_enable = false and g_addr_conflict_resolution = "write_first") generate

    process(clk_i)
    begin
      if rising_edge(clk_i) then
        if(wea_i = '1') then
          ram(to_integer(unsigned(aa_i))) := da_i;
          qa_o                            <= da_i;
        else
          qa_o <= ram(to_integer(unsigned(aa_i)));
        end if;
        if(web_i = '1') then
          ram(to_integer(unsigned(ab_i))) := db_i;
          qb_o                            <= db_i;
        else
          qb_o <= ram(to_integer(unsigned(ab_i)));
        end if;
      end if;

    end process;
  end generate gen_without_byte_enable_writefirst;


  gen_without_byte_enable_nochange : if(g_with_byte_enable = false and g_addr_conflict_resolution = "no_change") generate

    process(clk_i)
    begin
      if rising_edge(clk_i) then
        if(wea_i = '1') then
          ram(to_integer(unsigned(aa_i))) := da_i;
        else
          qa_o <= ram(to_integer(unsigned(aa_i)));
        end if;
        if(web_i = '1') then
          ram(to_integer(unsigned(ab_i))) := db_i;
        else
          qb_o <= ram(to_integer(unsigned(ab_i)));
        end if;
      end if;
    end process;


    
  end generate gen_without_byte_enable_nochange;
  

end syn;
