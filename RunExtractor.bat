
REM Set Perl Exec Path
path = "C:\Perl\bin\"

REM Change to MedPCExtractor dir
chdir "C:\Program Files\MedPCDataExtractor\src\"

REM Call Perl Script
perl parser.pl

REM exit | pause (debug)
pause
