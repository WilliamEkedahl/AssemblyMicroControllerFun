############################## DEFINITIONS #############################
        .equ    JTAG_DATA, 0x10001000   # Base address to the JTAG data register
        .equ    JTAG_CTRL, 0x10001004   # Base address to the JTAG control register

        .equ    LCD_INST, 0x10003050    # Base address to the LCD instruction register
        .equ    LCD_DATA, 0x10003051    # Base address to the LCD data register

        .equ    RS232_DATA, 0x10001010  # Base address to the RS-232 data register
        .equ    RS232_CTRL, 0x10001014  # Base address to the RS-232 control register

############################# CODE SEGMENT #############################

        .text
        .global _start

_start:
    # Turn off LCD cursor
    call    lcd_cursor_off

main_loop:
    # Check if JTAG data is available
    movia   r3, JTAG_CTRL
    ldbio   r2, 0(r3)
    andi    r2, r2, 0x01  # Mask to check RVALUE bit
    beq     r2, r0, check_rs232  # If not valid, check RS-232

    # JTAG data is available
    call    jtag_get
    mov     r4, r2        # Character read from JTAG
    call    jtag_put      # Echo character to terminal over JTAG
    call    rs232_put     # Send character over RS-232
    movi    r4, 0
    movi    r5, 0
    call    lcd_put       # Display character on LCD (upper left corner)

check_rs232:
    # Check if RS-232 data is available
    movia   r3, RS232_CTRL
    ldbio   r2, 0(r3)
    andi    r2, r2, 0x01  # Mask to check RVALUE bit
    beq     r2, r0, main_loop  # If not valid, loop again

    # RS-232 data is available
    call    rs232_get
    mov     r4, r2        # Character read from RS-232
    call    rs232_put     # Echo character to terminal over RS-232
    call    jtag_put      # Send character to JTAG
    movi    r4, 0
    movi    r5, 15
    call    lcd_put       # Display character on LCD (upper right corner)

    br      main_loop  # Repeat main loop

######################## JTAG FUNCTIONS ########################

################################################################
# jtag_get                                                     #
# Returns JTAG input.                                          #
# Arguments: none                                              #
# Returns:                                                     #
#   r2  The data in bit field [0,7] of the                     #
#       JTAG DATA register.                                    #
################################################################
jtag_get:
    movia   r3, JTAG_DATA
    ldbio   r2, 0(r3)     # Load data from JTAG_DATA register
    ret

################################################################
# jtag_put                                                     #
# Writes a character to the JTAG port if there is space        #
# available in the FIFO.                                       #
# Arguments:                                                   #
#   r4  The character to write                                 #
################################################################
jtag_put:
    movia   r3, JTAG_CTRL
check_jtag_space:
    ldbio   r2, 0(r3)
    andi    r2, r2, 0x02  # Mask to check for space in FIFO
    beq     r2, r0, check_jtag_space  # Wait if no space available

    movia   r3, JTAG_DATA
    stbio   r4, 0(r3)     # Store character in JTAG_DATA register
    ret

####################### RS-232 FUNCTIONS #######################

################################################################
# rs232_get                                                    #
# Returns RS-232 input.                                        #
# Arguments: none                                              #
# Returns:                                                     #
#   r2  The data in bit field [0,7] of the                     #
#       RS-232 DATA register.                                  #
################################################################
rs232_get:
    movia   r3, RS232_DATA
    ldbio   r2, 0(r3)     # Load data from RS-232 DATA register
    ret

################################################################
# rs232_put                                                    #
# Writes a character to the RS-232 port if there is space      #
# available in the FIFO.                                       #
# Arguments:                                                   #
#   r4  The character to write                                 #
################################################################
rs232_put:
    movia   r3, RS232_CTRL
check_rs232_space:
    ldbio   r2, 0(r3)
    andi    r2, r2, 0x02  # Mask to check for space in FIFO
    beq     r2, r0, check_rs232_space  # Wait if no space available

    movia   r3, RS232_DATA
    stbio   r4, 0(r3)     # Store character in RS-232 DATA register
    ret

######################## LCD FUNCTIONS #########################

################################################################
# lcd_cursor_off                                               #
# Turns off the LCD cursor.                                    #
# Arguments: none                                              #
################################################################
lcd_cursor_off:
    movia   r8, LCD_INST    # Turn off LCD cursor
    movui   r9, 0x000C
    stbio   r9, 0(r8)
    ret

################################################################
# lcd_put                                                      #
# Prints a character at a given position on the LCD.           #
# Arguments:                                                   #
#   r4  The line (0: line one, 1: line two)                    #
#   r5  The position on the line (0, 1, ... or 15)             #
#   r6  The character to print                                 #
################################################################
lcd_put:
    # Set cursor position
    slli    r8, r4, 7       # Shift line bit to position 6
    or      r8, r8, r5      # Concatenate line bit and positions bits
    ori     r8, r8, 0x80    # Set instruction bit
    movia   r9, LCD_INST
    stbio   r8, 0(r9)

    movia   r10, LCD_DATA    # Print character
    stbio   r6, 0(r10)
    ret

end:
    .end
