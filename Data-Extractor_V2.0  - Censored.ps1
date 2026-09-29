# Getting only ErrorText data from .b2s files 

# Defining Variables 
$Scan_Path = "path_censored"
$Output_File = "path_censored\Total-Diagnostic-Errors.csv"
$Filtered_Diagnostic_Text = @() # Collecting all EC lines with Diagnostic label

# Setting Up output CSV File Table
"Diagnostic,EC(hex),Error-Text" | Out-File $Output_File

# Fetching ErrorText Data, adding the filename to the start of each line
Get-ChildItem -Path $Scan_Path | ForEach-Object {  
    $file_name = $_.BaseName
    $insideErrorText = $false   

    Get-Content $_.FullName | ForEach-Object { 
        $line = $_
        $line_with_name = "$file_name,$line" # Adding the filename (Diagnostic) to the start of each line, separated with a comma 
       
        
        if ($insideErrorText -and $line -match "};") { # Detect end of block errortexte block 
            $insideErrorText = $false
        }
        if ($insideErrorText -eq $true) { # Collect lines inside block
            $Filtered_Diagnostic_Text += $line_with_name # Adding current object (line) into $Filtered_Diagnostic_Text 
        }
        if ($line -match "errortexte[ -~][0-9][ -~][ -~][ -~]") { # Detecting start of errortexte block 
            $insideErrorText = $true 
           
        }       
    }
}

$Filtered_Diagnostic_Text = $Filtered_Diagnostic_Text | Where-Object { $_ -notmatch 'ORT|ORTTEXT|Diagnostic_Code|Failure_Class' } # Removing all { "ORT", "ORTTEXT", "Diagnostic_Code", "Failure_Class" } lines 


# Extracting columns one, two and three from the array 
$Filtered_Columns = $Filtered_Diagnostic_Text | ForEach-Object {
    $cols = ($_ -split ",") | ForEach-Object { $_.Trim() -replace '^"|"$','' } # Removing "" at the start and end of the line 
    "$($cols[0]),$($cols[1]),$($cols[2])" # Taking the first three elements from $cols, and joining them to the same line, seperated with commas 
}

$Filtered_Columns = $Filtered_Columns | ForEach-Object {
    $_ -replace '[^\p{L}\p{N}, ]', '' # Removing all symbols expect commas 
}

$Filtered_Columns | Out-File $Output_File -Append


