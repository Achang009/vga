library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port ( 
        i_clk_50M : in  STD_LOGIC;                      -- 系統時鐘輸入
        i_rst     : in  STD_LOGIC;                      -- 非同步重置輸入 (高電位觸發)
        o_hsync   : out STD_LOGIC;                      -- 水平同步訊號
        o_vsync   : out STD_LOGIC;                      -- 垂直同步訊號
        o_red     : out STD_LOGIC_VECTOR (3 downto 0);  -- 紅色訊號
        o_green   : out STD_LOGIC_VECTOR (3 downto 0);  -- 綠色訊號
        o_blue    : out STD_LOGIC_VECTOR (3 downto 0)   -- 藍色訊號
    );
end vga_controller;

architecture Behavioral of vga_controller is
    -- 內部訊號宣告 (僅保留計數器與除頻器)
    signal clk_25M  : std_logic := '0';
    signal h_cnt    : integer range 0 to 799 := 0;
    signal v_cnt    : integer range 0 to 524 := 0;
begin

    -- [除頻器] 只負責控制 clk_25M
    process(i_clk_50M, i_rst)
    begin
        if i_rst = '1' then
            clk_25M <= '0';
        elsif rising_edge(i_clk_50M) then
            clk_25M <= not clk_25M;
        end if;
    end process;

    -- [水平計數器] 只負責控制 h_cnt
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            h_cnt <= 0;
        elsif rising_edge(clk_25M) then
            if h_cnt = 799 then
                h_cnt <= 0;
            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;

    -- [垂直計數器] 只負責控制 v_cnt
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            v_cnt <= 0;
        elsif rising_edge(clk_25M) then
            if h_cnt = 799 then
                if v_cnt = 524 then
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- [水平同步訊號] 轉換為循序邏輯，只負責控制 o_hsync
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            o_hsync <= '1';  -- 同步訊號預設為高電位
        elsif rising_edge(clk_25M) then
            if (h_cnt >= 656 and h_cnt < 752) then
                o_hsync <= '0';
            else
                o_hsync <= '1';
            end if;
        end if;
    end process;

    -- [垂直同步訊號] 轉換為循序邏輯，只負責控制 o_vsync
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            o_vsync <= '1';  -- 同步訊號預設為高電位
        elsif rising_edge(clk_25M) then
            if (v_cnt >= 490 and v_cnt < 492) then
                o_vsync <= '0';
            else
                o_vsync <= '1';
            end if;
        end if;
    end process;

    -- [畫面繪製 - 紅色通道] 轉換為循序邏輯，只負責控制 o_red
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            o_red <= "0000";
        elsif rising_edge(clk_25M) then
            -- 先判斷是否在 640x480 的可視區域內
            if (h_cnt < 640 and v_cnt < 480) then
                -- 繪製左上角 200x200 的紅色區塊
                if (h_cnt < 200 and v_cnt < 200) then
                    o_red <= "1111"; 
                else
                    o_red <= "0000";
                end if;
            else
                o_red <= "0000"; -- 離開可視區強制歸零
            end if;
        end if;
    end process;

    -- [畫面繪製 - 綠色通道] 轉換為循序邏輯，只負責控制 o_green
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            o_green <= "0000";
        elsif rising_edge(clk_25M) then
            -- 範例未使用綠色
            o_green <= "0000";
        end if;
    end process;

    -- [畫面繪製 - 藍色通道] 轉換為循序邏輯，只負責控制 o_blue
    process(clk_25M, i_rst)
    begin
        if i_rst = '1' then
            o_blue <= "0000";
        elsif rising_edge(clk_25M) then
            if (h_cnt < 640 and v_cnt < 480) then
                -- 除了紅區塊外，其餘背景塗藍
                if (h_cnt < 200 and v_cnt < 200) then
                    o_blue <= "0000";
                else
                    o_blue <= "1111";
                end if;
            else
                o_blue <= "0000"; -- 離開可視區強制歸零
            end if;
        end if;
    end process;

end Behavioral;