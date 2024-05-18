/********1*********2*********3*********4*********5*********6*********7*********8
* File : bme280_defines.vh
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/02/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* BME280 sensor regs and operation codes
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2022
*
*********1*********2*********3*********4*********5*********6*********7*********/
`define BME_WRITE     1'b0
`define BME_READ      1'b1
`define BME_CAL00     8'b1000_1000
`define BME_CAL26     8'b1110_0001
`define BME_DIGT1     8'b1000_1000
`define BME_DIGT2     8'b1000_1010
`define BME_DIGT3     8'b1000_1100
`define BME_DIGP1     8'b1000_1110
`define BME_DIGP2     8'b1001_0000
`define BME_DIGP3     8'b1001_0010
`define BME_DIGP4     8'b1001_0100
`define BME_DIGP5     8'b1001_0110
`define BME_DIGP6     8'b1001_1000
`define BME_DIGP7     8'b1001_1010
`define BME_DIGP8     8'b1001_1100
`define BME_DIGP9     8'b1001_1110
`define BME_DIGH1     8'b1010_0001
`define BME_DIGH2     8'b1110_0001
`define BME_DIGH3     8'b1110_0011
`define BME_DIGH4     8'b1110_0100
`define BME_DIGH5     8'b1110_0101
`define BME_DIGH6     8'b1110_0111
`define BME_ID        8'b1101_0000
`define BME_RESET     8'b1110_0000
`define BME_CTRL_HUM  8'b1111_0010
`define BME_STATUS    8'b1111_0011
`define BME_CTRL_MEAS 8'b1111_0100
`define BME_CONFIG    8'b1111_0101
`define BME_PRESS_MSB 8'b1111_0111
`define BME_PRESS_LSB 8'b1111_1000
`define BME_PRESS_XSB 8'b1111_1001
`define BME_TEMP_MSB  8'b1111_1010
`define BME_TEMP_LSB  8'b1111_1011
`define BME_TEMP_XSB  8'b1111_1100
`define BME_HUM_MSB   8'b1111_1101
`define BME_HUM_LSB   8'b1111_1110
