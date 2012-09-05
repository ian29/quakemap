#!/bin/bash
set -e -u


# TODO: 
# - correctly assign variable values for pg_values
# - gdaldem color-relief before export
# - && in conditional "do all the things"
# - use sed to remove first line of stupid grid.xyz
# - import specified input file
# 	- test psql + COPY
# 	- test pg_values with table

usage() {
cat << EOF
usage: $0 [OPTION]

-i              Import all XYZ files
-e              Export a GeoTIFF
-c column       specify which column you want to make a map of
-t table       	name the table 
-o FILE         Path of the output file. Defaults to the name of the postgres table. 
-h -?	 		Display this help screen

Example:
    $0 -c psa03 -t costa_rica -o cosat-rica-pga.tif

Export example:
    $0 -e -f 201101 -t 201112 -o 2011_medians.tif
EOF
}

pgcmd='psql -U postgres -d earthquake'

pg_setup() {
	echo "Setting up postgres table"
	$pgcmd -c "drop table if exists $table"
	$pgcmd -c "create table $table (x float8, y float8, pga float8, pgv float8, mmi float8, psa03 float8, psa10 float8, psa30 float8)"
}

import_xyz() {
    echo "Importing $1..."
    $pgcmd -c "copy $t (x,y,) from stdin with delimiter ' ' csv" < $1
}

pg_cleanup() {
    echo "Indexing..."
    $pgcmd -c "create index on $t (x,y,pga,pgv,mmi,psa03,psa10,psa30);"
}

pg_values() {
	echo "Calculating…"
	min='$pgcmd -c "select min($c) from $table"'
	max='$pgcmd -c "select max($c) from $table"'
	avg='$pgcmd -c "select avg($c) from $table"'
}

write_ramp()
	echo "Create color ramp"
	min1=$[min + 1]
	echo "$min	255	255	255" > ${table}-ramp.txt
	echo "$min1	252	255	238" >> ${table}-ramp.txt
	echo "$avg	255	180	99" >> ${table}-ramp.txt
	echo "$max	255	86	78" >> ${table}-ramp.txt
}

export() {
    if [ -z $outfile ]; then
        outfile="${table}.tif"
    fi
    tempfile=$(mktemp)

    # Export as XYZ from the PostgreSQL DB to a temporary file
    $pgcmd -c "copy (select x, y, $c) to stdout with csv delimiter ' ';" > $tempfile

    # Convert the tempfile to a GeoTIFF
    gdal_translate -co compress=lzw -a_srs EPSG:4326 $tempfile $outfile

    # Clean up
    rm $tempfile
}

column=pga
table=
outfile=
opt_import=0
opt_export=0

while getopts “hief:t:o:” OPTION; do
    case $OPTION in
        h)  usage
            exit 1
            ;;
        i)  opt_import=1
            ;;
        e)  opt_export=1
            ;;
        c)  column=$OPTARG
            ;;
        t)  table=$OPTARG
            ;;
        o)  outfile=$OPTARG
            ;;
        ?)  usage
            exit
            ;;
    esac
done

# Do all the things!
if [ $opt_import = 0 ]; then
    pg_setup
    import_xyz $f
    pg_cleanup
    pg_values
    write_ramp
    export
fi

# Import, process
if [ $opt_import = 1 ]; then
    pg_setup
    import_xyz $f
    pg_cleanup
fi

# Run export
if [ $opt_export = 1 ]; then
    export_median
fi