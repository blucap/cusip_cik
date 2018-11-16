# cusip_cik

I noticed that CUSIPs can be linked to CIK codes. See Ian Gow's repo  https://github.com/iangow-public/edgar 

I use a slightly different approach - I store the data on csv format. 

Step 1: run this curl script to download the SEC form files.

`curl -k -o "form#1.zip" "https://www.sec.gov/Archives/edgar/full-index/[2000-2017]/QTR4/form.zip"`

Step 2: after unpacking the forms run, the `linesform.py` script to extract the urls for SC 13D and SC 13G forms.

Step 3: run the perl script to extract the CUSIPS that belwong to a CIK.
