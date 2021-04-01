awk -F"," '{sub(/00/,"",$7)}1' OFS=","
sub(/target regex/, "replace", $column number)
