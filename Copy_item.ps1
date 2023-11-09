$computerList = Get-Content "C:\list.txt"
foreach ($computer in $computerList) { 
    Copy-Item -Path "C:\script.txt" -Destination "\\$computer\c$" -Recurse
}