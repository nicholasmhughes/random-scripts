#!/usr/bin/env python2.6

from optparse import OptionParser
import csv
import json
import sys

parser = OptionParser()
parser.add_option("-t", "--type", dest="filetype",
                  help="set the inbound file type to TYPE", metavar="TYPE")
options, arguments = parser.parse_args()

infile = sys.stdin
jsonfile = sys.stdout

if options.filetype == "cidr_block":
    fieldnames = ["cidr_block"]
elif options.filetype == "domain":
    fieldnames = ["domain"]
elif options.filetype == "malware_domain":
    fieldnames = ["domain","type","source","dates_observed"]
elif options.filetype == "page_rank":
    fieldnames = ["rank","url"]
elif options.filetype == "shunlist":
    fieldnames = ["ip_address","timestamp","desc"]
elif options.filetype == "url":
    fieldnames = ["url"]
else:
    fieldnames = ["ip_address"]

if options.filetype == "malware_domain":
    for row in infile:
        if not row.startswith('#') and not row == '':
            row = row.strip().split('\t')
            row[3:] = [row[3:]]
            json.dump(dict(zip(fieldnames, row)), jsonfile)
            jsonfile.write('\n')
else:
    reader = csv.DictReader( (row for row in infile if not row.startswith('#') and not row == ''), fieldnames )
    for row in reader:
        json.dump(row, jsonfile)
        jsonfile.write('\n')
