zmlogmon:

The zmlogmon utility monitors a zimbra log file for
exceptions.

Typical usage is:

[zimbra@qa01 bin]$ tail -f /opt/zimbra/log/zimbra.log | ./zmlogmon

OR

[zimbra@qa01 bin]$ ./zmlogmon < /opt/zimbra/log/zimbra.log

zmlogmon_config:

The zmlogmon_config file contains data regarding known
exceptions.  Some exceptions are acceptable (e.g.
AccountServiceException: no such account), some exceptions
should only be caused by the QA SOAP Suite (e.g. ServiceException:
invalid request: missing required element), and some
exceptions are logged bugs.

The config file also contains a list of email addresses to
send notification emails.  Specify one email address per line
(see the example).

TODO List:

1. Known issue list:
 A. Implement the known issue list (it isn't implemented yet)
 B. Add the known bugs to the config file
 C. Add code to determine if the bug is open, resolved, or closed.
 D. Send mail if the bug is resolved or closed and is captured.
2. Add a mechanism to match any line in the stack trace, rather than just the first log message
3. Add command options to ignore:
 A. Ignore only acceptable exceptions
 B. Ignore acceptable exceptions and QA SOAP Suite exceptions
 C. Ignore no exceptions
4. Need to clean up the temp file usage so that permission problems don't occur
5. Need to clean up how the zmlogmon_config file is found.  Right now, the config file must exist in the CWD


