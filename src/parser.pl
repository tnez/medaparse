#!/usr/local/bin/perl
use strict;
use POSIX qw(floor);

# Parser for Med PC Datafile
# Author: Travis Nesland
# Date: February 2009
#
# written for Nicole to extract data from datafiles into a format
# that resembles database records . . . this should make it easier
# to deal with the data in excel / access, enabling operations
# like filtering and aggregate functions to extract metadata.
#
# Preconditions:
# - a valid input file (MedPC Datafile) is passed to the program
# - input file exists in this or sufficiently similar format:
# ------------------------------------------------------------------------------
# File: C:\MED-PC IV\Data\!2009-01-31_11h23m.Subject E1_
#
#
# BOX:  1 SUBJECT:      E1_ EXPERIMENT: COCESC_RUNA GROUP:        2 MSN:    1102L
# START: 01/31/09  11:23:37  END: 01/31/09  17:25:18
# A:37.00000
# B:39.00000
# C:30.00000
# D:
#      0: 536.3000 771.1000 1049.400 2435.700 2435.900
#      5: 2486.300 3050.700 3052.800 4378.400 4396.000
#     10: 4692.400 5588.500 5613.800 5618.700 5621.400
#     15: 6085.800 6733.700 6783.600 7464.800 8024.000
#     20: 8290.600 9245.900 9246.400 9757.900 12364.60
#     25: 13490.10 14969.60 15484.00 15915.60 16808.40
#     30: 17240.40 18108.80 19131.20 19143.30 19143.50
#     35: 19145.30 20951.60
# E:
#      0: 567.9000 1448.200 4363.300 4798.600 4798.600
#      5: 5489.400 5504.400 5522.700 5537.800 5627.700
#     10: 5999.500 6748.800 7618.200 7618.400 8843.000
#     15: 8854.200 8881.400 9034.200 9047.900 9238.700
#     20: 9262.300 9270.900 9462.400 10467.40 13324.80
#     25: 13534.70 13709.70 14847.90 14857.20 15432.90
#     30: 15597.70 16166.60 16166.60 18093.70 18951.80
#     35: 19149.30 19151.90 19181.80 20892.80
# F:
#      0: 536.3000 771.1000 1049.400 2435.700 2486.300
#      5: 3050.700 4378.400 4396.000 4692.400 5588.500
#     10: 5613.800 6085.800 6733.700 6783.600 7464.800
#     15: 8024.000 8290.600 9245.900 9757.900 12364.60
#     20: 13490.10 14969.60 15484.00 15915.60 16808.40
#     25: 17240.40 18108.80 19131.20 19143.30 20951.60
# ------------------------------------------------------------------------------

# POSTCONDITIONS:
# - Output file exists <filename>.csv in comma delimited format where all data
#   exists as database records ( redundancy exists, but each record contains
#   all nessasary data to be evaluated independantly of all other data )
# - User is notified of success or failure


# DO NOT EDIT BELOW THIS LINE
# ##############################################################################

# define variables
our @files = ();                # holds collective list of input files
our $in_data;                   # holds name of current read file
our $out_file;                  # holds name of current write file
our $log = "../out/filelog.log"; # logfile where records prev input
our $raw;                        # holds raw read data
our $block;                      # holds temp chunks
our @variables = ();             # array to hold variables
our $v = 0;                      # ctr used with var array
our @context = ();               # array to hold data that will be rep
our $c = 0;                      # ctr used with context array
our $meta_data;                  # string to hold repeated meta data
our $data_roll;                  # string holds rolls of data for
                                 # further processing

# SUB ROUTINES
# ======================



# MAIN PROCEDURE
# ==============
find_files() or die $!;         # returns each file in "in" directory
                                # and sends it on to the parsing
                                # routine

parse_datafiles();              # parse all of the datafiles who's
                                # filenames have been put into the
                                # file array


# SUB PROCEDURE:find_files
# in : "in" directory exists in the Parser Project Folder
# out: each file in the "in" dir is checked for previous processing
#      and if has not been processed, is sent to the parse_datafile
#      subroutine
sub find_files () {
  print "\n";                       # cleans up term screen a little
  opendir(DIR, "../in/") or die $!; # open "in" directory
  # add each file name into the array
  my $i = 0;                   # local counter to increment file array
  # while there are files to be read...
  while (my $file = readdir(DIR)) {
    # skip if file begins with "."
    next if $file =~ m/^\./;
    # made it past skip... so file
    # does not start with "." and
    # I can add the filename to
    # the files array
    $files[$i++] = $file;
  }
  closedir(DIR);                # close "in" directory
}


# SUB PROCEDURE:parse_datafile
# in : filename of a valid MedPC datafile and applicable user
#      edits to the user editable variables (bin related)
# out: input file is parsed into csv record format, adding
#      bins when applicable
sub parse_datafiles {
  # for each of the files in the files array
  # start the parsing process
  foreach $in_data (@files) {
    # reset variables for begin loop
    initialize_vars();
    # Open (in)datafile
    open IN_FILE, "../in/$in_data" or die $!;
    # extract variables
    # using regex
    while (<IN_FILE>) {
      # reads file line by line
      # into read data
      # for each pattern that matches
      # pattern for variable labels...
      $raw .= $_;
      foreach my $match ($_ =~ m/(^|\s+)(\D+?):[^\\]/g) {
        # check that this is not whitespace
        if ($match =~ m/[^\s]/) {
          # ...store in variable array
          $variables[$v++] = $match;
        }
      }
    }

    # Close (in)datafile
    close IN_FILE;

    # for each of the variables
    # grab the data between start
    # and end
    # start=tag end=tag+1
    our $t = -1;                # starts at -1 because while
    # increments first run
    while ($variables[++$t]!~   # while haven't met match condition
           m/\b[a-zA-Z]\b/) {   # match 1 char variables
      # setup start and end locators
      my $start = $variables[$t];
      my $end = $variables[$t+1];
      # extract the data with regex
      $raw =~ m/$start:\s*(.*?)\s*$end:/m; # match between s/e ignore spaces
        # put the match into the context array...
        # this is special case meta data that will
        # be repeated again and again in records
        $context[$c++] = $1;
    }


    # turn context array data into a single string
    # so as to avoid extra loop in the write process
    foreach my $tmp (@context) {
      # for each of these . . . append to a meta data string
      $meta_data .= "\"$tmp\",";
    }


    # loop through the remaining variables in
    # the variable array and write records
    # to the correct table files for each
    # of the remaining variables
    for ($t;$t<$v;$t++) {
      # setup start and end locators
      my $start = $variables[$t];
      my $end = $variables[$t+1];
      # manipulate
      # if this is the last variable in the
      # variable array process until eof
      if ($t==$v-1) {
        $raw =~ m/\b$start:\s*([^\\].*?)\s*$/s; # match from start to <eof>
          $data_roll = $1;      # roll data for next step
      }
      # ...else this is not the last variable,
      # so we can get between start and end tags
      else {
        # extract the data with regex
        $raw =~ m/\b$start:\s*([^\\].*?)\s*$end:/s; # match between s/e ignore spaces
          $data_roll = $1;      # roll data for next step
      }
      # open out file for writing
      open OUT_FILE, ">>../out/$variables[$t].csv" or die $!;

      # start matching individual records
      # in the data roll

      # if data roll contains no spaces
      # it is a single datum point and needs
      # no special for loop for processing
      if ($data_roll!~m/\s/) {
        # output data
        print OUT_FILE "\n$meta_data\"$data_roll\"";
      }
      # else, multiple data points exist for this
      # variable, so we need a foreach loop to process
      else {
          # initialize a bin counter to include bin number in record
          my $bCount=0;
          foreach my $datum
            (split(" ",$data_roll)) { # match all things followed by space that
                                      # don't end in ":"
                # 
                # increment bin counter and print record if $datum
                # does not contain ":" or " "
                if ($datum !~ m/[:]/) {
                    $bCount++;
                    print OUT_FILE "\n$meta_data\"$bCount\",\"$datum\"";
                }
          }
        }
      # close the current write file
      # for which we have completed writing
      close OUT_FILE;
    }
    $raw = "";
    # write the filename that we have just parsed in the filelog.log
    # TODO: this parse routine needs error checks and needs to send
    # appropriate error messages to the log file when the (in)file was
    # not parsed successfully :END
    my $MedPC_filename = get_filename(); # get filename according to MedPC
    write_to_log($MedPC_filename);       # write to logfile
    print "finished $MedPC_filename...\n"; # update user on term screen
  }
}

# SUB PROCEDURE:initialize_vars
# in : n/a
# out: nesc global variables are reset and can be safely used
sub initialize_vars {
  $raw = "";
  $block = "";
  @variables = ();
  $v = 0;
  @context = ();
  $c = 0;
  $meta_data = "";
  $data_roll = "";
}


# SUB PROCEDURE:get_filename
# in : 1) datafile has already been parsed, populating the variables array
#      2) filename is the first variable found in the datafile
# out: filename as reported in MedPC datafile is returned
sub get_filename {
  $meta_data =~ m/^"(.*?)"/s; # extract filename from meta data string
    return $1;                # return the filename match
}


# SUB PROCEDURE:write_to_log
# in : string to be put in log (written filename or error desc)
# out: filename or error msg written to logfile "filelog.log"
#      in the "src" directory
sub write_to_log {
  my $input = @_[0];                 # store arg in input
  open OUT_FILE, ">>$log" or die $!; # open logfile for write
  print OUT_FILE "$input\n"; # and put value into our filename logfile
  close OUT_FILE;            # close logfile
}

