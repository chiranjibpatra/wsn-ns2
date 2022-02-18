set initial 4294967295

# Decimal to hex using format
set inhex [format %x $initial]

# Hex to decimal using expr
set back_in_decimal [expr 0x$inhex]

# checking the results
puts "$initial ... $inhex ... $back_in_decimal"
