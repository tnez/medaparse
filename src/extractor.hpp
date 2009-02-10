/*
 * Program: Med PC Data Extractor
 *
 * Author: Travis Nesland
 * Date: 2009.02.10
 *
 * This program was written to extract data from MedPC datafiles of a particular format.
 * For this to work, the data file must be formatted as:
 * 
 * -----------------------------------------------------
 * File: C:\MED-PC IV\Data\!2009-01-31_11h23m.Subject E1_
 * 
 * 
 * BOX:  1 SUBJECT:      E1_ EXPERIMENT: COCESC_RUNA GROUP:        2 MSN:    1102L
 * START: 01/31/09 11:23:37 END: 01/31/09 17:25:18
 * A:37.00000
 * B:39.00000
 * C:30.00000
 * D:
 *    0: 536.3000 771.1000 1049.400 2435.700 2435.900
 *    5: 2486.300 3050.700 3052.800 4378.400 4396.000
 *   10: 4692.400 5588.500 5613.800 5618.700 5621.400
 *   15: 6085.800 6733.700 6783.600 7464.800 8024.000
 *   20: 8290.600 9245.900 9246.400 9757.900 12364.60
 *   25: 13490.10 14969.60 15484.00 15915.60 16808.40
 *   30: 17240.40 18108.80 19131.20 19143.30 19143.50
 *   35: 19145.30 20951.60
 * E:
 *    0: 567.9000 1448.200 4363.300 4798.600 4798.600
 *    5: 5489.400 5504.400 5522.700 5537.800 5627.700
 *   10: 5999.500 6748.800 7618.200 7618.400 8843.000
 *   15: 8854.200 8881.400 9034.200 9047.900 9238.700
 *   20: 9262.300 9270.900 9462.400 10467.40 13324.80
 *   25: 13534.70 13709.70 14847.90 14857.20 15432.90
 *   30: 15597.70 16166.60 16166.60 18093.70 18951.80
 *   35: 19149.30 19151.90 19181.80 20892.80
 * F:
 *    0: 536.3000 771.1000 1049.400 2435.700 2486.300
 *    5: 3050.700 4378.400 4396.000 4692.400 5588.500
 *   10: 5613.800 6085.800 6733.700 6783.600 7464.800
 *   15: 8024.000 8290.600 9245.900 9757.900 12364.60
 *   20: 13490.10 14969.60 15484.00 15915.60 16808.40
 *   25: 17240.40 18108.80 19131.20 19143.30 20951.60
 * -----------------------------------------------------
 */

#include <regex>
#include <fstream>
#include <iostream>

class MedPCDataParser {
private:
  std::ifstream * datafile;
  std::ofstream * writefile;
  char * box;
  char * subject;
  char * experiment;
  char * group;
  char * msn;
  char * start;
  char * end;
  char * variable;
  int bin;
  char * timestamp;
public:
  // this constructor will handle opening the medpc data file
  // as well as the write file and ready them for read / write
  MedPCDataParser(const char * ,  // full path of input data file
                  const char * ,  // full path to output file
                  bool append     // mode: write = 0 | append = 1
                  );
  // Destructor:
  // * save write file
  // * close data and write files
  // * delete all pointers
  ~MedPCDataParser();
  // functions to read from datafile
  char * ReadBox(); 
  char * ReadSubject();
  char * ReadExperiment();
  char * ReadGroup();
  char * ReadMSN(); 
  char * ReadStart();
  char * ReadEnd(); 
  char * ReadData();
  // check if new bin
  bool IsNewBin();
  // save write file
  bool SaveWriteFile();
}

