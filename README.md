# LogParser

Thanks for trying out my log parser!

It is intended to make looking for important messages in the Jamf Pro server logs easier.

After selecting a log to load it will count the number of logs and dates, and then parse the first day of logs.

Features:
> - search for specific phrases
> - logs are organized by date (click the gear and then use the picker to load additional dates beyond the first)
> - Click the gear to expand filters:
-- search includes traces (reduces performance)
-- search ignores case
-- include errors
-- include warnings
> - click the log to expand the traces that were found
> - Open in Terminal: (opens terminal in the background) allows you to view where that line is in the context of the rest of the log
> - Copy to clipboard

bugs:
> - (somewhat fixed) open in terminal doesn't make Terminal the front window or maximize it 
> - details occasionally resize when other details are opened
> - certain logs cause truncation (...) to appear at end of text line
> - long traces truncate the bottom of the trace in the GUI
