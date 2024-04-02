// bitcontroller states
`define I2C_CMD_NOP   4'b0000
`define I2C_CMD_START 4'b0001
`define I2C_CMD_STOP  4'b0010
`define I2C_CMD_WRITE 4'b0100
`define I2C_CMD_READ  4'b1000

// Address of the I2C master Resgisters
`define I2C_PRER      3'h0   //WR
`define I2C_CTR       3'h1   //W
`define I2C_TXR       3'h2   //W
`define I2C_CR        3'h3   //WR
`define I2C_RXR       3'h4   //R
`define I2C_SR        3'h5   //R



