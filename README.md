The purpose is to monitor the contents of the directories /bin, /usr/bin, /sbin/, /usr/sbin. It's about checking if there are
changes in those directories respect to the original backup if the option "-l" is not specified in the script "compare_snapshot.sh". 
This verification allows you plan to do it periodically, for example once a week.

The changes that should be checked are at least the following four:
+ Deleted files
+ New files added
+ Changes in permissions of existing files
+ Changes in the content of existing files
The proposed strategy is as follows: first, the current configuration of
the directories will be saved, with the names of the files, permissions, lengths, etc. Periodically, that
saved settings will be compared to the current settings and if differences are found, it will
will generate an alert in a log file. Let's put it in /var/log/binchecker.

It is about monitoring changes in the files, comparing the current control sum with another one that
has previously been saved. For example, md5sum is used for the calculation of said sum of
control.
To meet these objectives, these two scripts sre developed:
1. Script [snapshot](https://github.com/Prashant-JT/MonitoringFileChanges/blob/master/snapshot.sh) that obtains a “photo” of the status of the folders /bin, /sbin, /usr/bin, /usr/sbin, which contains the names of the files there are, their access permissions and a sum of control of your content.

2. Script [compare_snapshot](https://github.com/Prashant-JT/MonitoringFileChanges/blob/master/compare_snapshot.sh) to compare the original “photo” with the current content of those folders and report any difference as a text entry in the file /var/log/binchecker. There is an "-l" option  which checks to the last backup and not to the original one (by default).
The text entry must be of the type: «the file /bin/ls has a different content.
Current control sum = 0e9b71b256c37eb521a4a2b0a66593a2.
Original control sum = 0e9b71b256c37eb521a4a2b0a6659rh3 ».
The script must sufficiently inform about the disparity that has been found.

Both of the scripts include an option "-h" for further help.

For more information (in Spanish): [Scripts explained](https://github.com/Prashant-JT/MonitoringFileChanges/blob/master/InformePractica6ASO.pdf)
