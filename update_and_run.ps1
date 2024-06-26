$filename = $args[0]
if($args[0] -eq $null) {
    Write-host "Please specify a filename"
} else {
    $circ_pattern = 'INSTR_FILE = ".+?";'
    $replace_circ = "INSTR_FILE = `"$($filename)`";"
    $circ_content = Get-Content "Wrapper.v"
    $circ_content | ForEach-Object {$_ -replace $circ_pattern, $replace_circ} | Set-Content "Wrapper.v"

    $tb_pattern = 'parameter FILE = ".+?"'
    $replace_tb = "parameter FILE = `"$($filename)`""
    $tb_content = Get-Content "Wrapper_tb.v"
    $tb_content | ForEach-Object {$_ -replace $tb_pattern, $replace_tb} | Set-Content "Wrapper_tb.v"

    & '.\Test Files\asm.exe' -i ".\Test Files\custom_insn.csv" ".\Test Files\Assembly Files\$($filename).s"
    mv -Force ".\Test Files\Assembly Files\$($filename).mem" '.\Test Files\Memory Files\' 
    iverilog -c filelist.txt -o proc.vvp -Wimplicit -s Wrapper_tb
    vvp proc.vvp
}