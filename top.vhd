library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        clk    : in  std_logic;  -- 100 MHz z Basys 3
        btnC   : in  std_logic;  -- reset

        ble_rx : in  std_logic;  -- z TXD modułu PmodBLE do FPGA
        ble_tx : out std_logic;  -- z FPGA do RXD modułu PmodBLE

        led    : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of top is

    signal rx_data  : std_logic_vector(7 downto 0);
    signal rx_valid : std_logic;

    signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_start : std_logic := '0';
    signal tx_busy  : std_logic;

    signal led_reg : std_logic_vector(7 downto 0) := (others => '0');

begin

    led <= led_reg;

    uart_receiver : entity work.uart_rx
        generic map (
            CLK_FREQ  => 100_000_000,
            BAUD_RATE => 115_200
        )
        port map (
            clk        => clk,
            rst        => btnC,
            rx         => ble_rx,
            data_out   => rx_data,
            data_valid => rx_valid
        );

    uart_transmitter : entity work.uart_tx
        generic map (
            CLK_FREQ  => 100_000_000,
            BAUD_RATE => 115_200
        )
        port map (
            clk      => clk,
            rst      => btnC,
            data_in  => tx_data,
            tx_start => tx_start,
            tx       => ble_tx,
            tx_busy  => tx_busy
        );

    process(clk)
    begin
        if rising_edge(clk) then

            if btnC = '1' then
                led_reg  <= (others => '0');
                tx_data  <= (others => '0');
                tx_start <= '0';

            else
                tx_start <= '0';

                if rx_valid = '1' then
                    -- pokaż odebrany bajt na LED-ach
                    led_reg <= rx_data;

                    -- odeślij ten sam bajt jako echo
                    if tx_busy = '0' then
                        tx_data  <= rx_data;
                        tx_start <= '1';
                    end if;
                end if;

            end if;
        end if;
    end process;

end architecture;
