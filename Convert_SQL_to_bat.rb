#Script to produce BAT files for detailed UK TIMES sector analysis.
#Takes HumanReadableQueries.sql as input + template files (one for each sector)
#searches and replaces the former and inserts into the latter to produce a BAT
#for that sector. To run, provide the full path to HumanReadableQueries and
#ensure that there is a folder called "templates" with one template per BAT
#Fernley Symons 24-4-2017

require 'pathname'
require 'erb'
require 'fileutils'
require 'ostruct'
require 'optparse'
require 'thwait'
require 'logger'

dir = File.expand_path(File.dirname(ARGV[0] || '.'))
file_name=ARGV[0]
path=File.dirname(file_name)

found=0
fin = File.new(file_name, "r")
#string to which to append the contents of the Human Readable block
sql_to_run=""

# For each line in the human readable sql...
#...run through checking for the blocks which go into the BATs
while (line = fin.gets)
#when you find a block, determine which BAT file this should go in. Tell by finding the 
#BAT name in the header section for that particular file
#e.g. "(Elec.bat)". Delineated by 2 x *, presence of "bat" and absence of 'End of'
    if(line=~/\*{2}[^\*]/ && line !~/End of/ && line =~ /BAT/) 
      found=1
      line=line.gsub(/\).+/,"")
      fn=line.gsub(/^[^\(]+\(/,"")
      fn=fn.strip
    end
#check that it's not the end of the block using similar criteria to above   
    if(line=~/\*{2}[^\*]/ && line =~/End of/ && line =~ /BAT/)
      found=0
#If it is, open the appropriate template file. This has the header (to read in the Veda VD files) & 
#footer (to actually run the queries on postgres). Read the whole template file in at once
#Assumes that templates are in a subfolder "templates" of the current folder.      
      templatein = File.read(File.dirname(__FILE__) +'\\templates\\'+ fn.gsub(/\.(BAT)|(bat)/,"") + 'erb')
#Substitute in the whole block from "human readable"
#This uses the erb templating library. The templates have a section in them with <%= sql_to_run %>
#this automatically replaces this block with the contents of the sql_to_run variable.             
      renderer = ERB.new(templatein)
      templatein = renderer.result()
#Remove any blank lines. \r\n line endings get converted to \n by file.open so search and replace
#for more than one instance of this.      
      templatein=templatein.gsub(/\n{2,}/,"\n")
#Write the whole string to an output file in one go using anonymous function
#Is automagically closed by Ruby when function finishes      
      File.open(path + "\\"+ fn, 'w') { |file| file.write(templatein) }
      sql_to_run=""
    end
#Following is what to do when actually processing the block from Human readable. 
# = Perform a whole load of Regexp search and replace (detailed in the REM comments of the BAT)
# if there's a tilde with no preceding % replace with !textc!
    line=line.gsub(/([^%])[~]/,'\1!textc!')
# replace ^ with !textd!
    line=line.gsub("^","!textd!")
# replace "if not" with !textb!    
    line=line.gsub(/ ((IF)|(if)) ((NOT)|(not)) /," !textb! ")
# replace "if" with !texta!        
    line=line.gsub(/ ((IF)|(if)) /," !texta! ")
# replace any % not followed by a tilde with %%
    line=line.gsub(/%([^~])/,'%%\1')
# remove any in line SQL comments (start with "-"
    line=line.gsub(/--.+/,"")
# Escape pipe etc characters with "^"    
    line=line.gsub(/(\||<|>)/,'^\1')
# Only process those lines which are not comments (which start with --) 
    if !( line =~ /(^--.+)/) && line.length>1 && !(line=="\n")
# Pre- and post fix them with DOS "echo" and destination
      line="echo " + line.strip + " >> " + fn.to_s.gsub(/(\.BAT)|(\.bat)/,"") + ".sql\n"
# Double the line which has the query title so it's more readable in the BAT          
      line=line.gsub(/echo (\/\*.+\/)/,'rem \1'+"\r"+'echo \1')
# Only append to string "sql_to_run" those lines which are not blank (which don't consist of prefix+postfix only)
#and check for any entries which are 'echo /* >> ...' [i.e. with single opening comment]
      if found==1 && !(line=~/\*{2}[^\*]/ && line !~/End of/ && line!="" && line =~ /BAT/) && !(line=~/echo \/\* \>\>/) && !(line=~/echo  \>\>/)
        sql_to_run<<line 
      end
    end
  end
fin.close

