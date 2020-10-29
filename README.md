## Sumologic<->deskpro comparator

> As of October 2020 this repo is no longer actively maintained by the GOV.UK Pay team, following the switch from
> Sumologic to Splunk in March 2019.

This was done as a one-off to check loglines for sumologic

The sumologic CSV output has these headings:

```
"_messagetimems","_messagetime","dest_host","dest_user","src_user"
```

The deskpro CSV output has these headings:
```
"ID","Subject","Agent Team","Agent Team ID","Message","Date Created","Date Resolved"
```

the report used to generate this output is [here](https://gaap.deskpro.com/agent/#reports:/builder/113/custom/).

The script works by doing the following:

1. parse all deskpro tickets, parses the html, extracts the table containing the count of sudo activity and builds a hash of the user and logline count from the output
2. parse all sumologic log lines, for each:
  1. attempt to find a deskpro ticket which occurred no more than 90 minutes after the log line
  2. for that ticket increment a counter for the given user
  3. if the counter exceeds the number of sudos listed in the deskpro ticket by more than 1, raise an error. Note: the margin of 1 was added to allow for the fact that some log-lines may have been re-ingested so there may be duplicate log lines in sumologic

At the end the script prints out the number of log lines for which no ticket was found.



    
