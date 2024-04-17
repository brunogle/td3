target remote localhost:2159
set $pc=0x70010000
set $sp=0x70020000

break end
cont
x /10wd &data_origen
x /10wd &data_destino