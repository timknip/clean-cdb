## clean-cdb

Utility to move older revisions of CDB model files to a backup directory.

# install

    npm install

# run

    coffee src/main.coffee [OPTIONS]

Options:

    -c, --cdb [DIR]             Location of CDB, default is /cdb
    -o, --outdir [DIR]          Output directory for backup, default is /cdb/backup/models
    -h, --help                  Shows this help message
