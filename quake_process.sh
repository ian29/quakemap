#!/bin/bash
set -e -u

# GOALS:
# this script attempts to do the following, making it easier to make fast maps
# 	out of the USGS shakemap product: http://earthquake.usgs.gov/research/shakemap/
#
# 1. eat an .xyz file of earthquake data from USGS
# 2. clean + import that file to a postgres table
# 3. run some basic sql to get min,max and avg out of a user-specified column
# 4. use those values in a color ramp
# 5. export to geotiff, and then recolor that tif with the color ramp
#
# TODO:
# - correctly assign variable values for pg_values
# - gdaldem color-relief before export
# - && in conditional "do all the things"
# - use `min + some %` rather than `1` as for some ranges, 1 is not negligible 
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
-h              Display this help screen

Example:
    $0 -c psa03 -t costa_rica grid.xyz costa-rica-pga.tif

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
    tempm=$(mktemp)
    sed '1d' $inputfile > $tempm
    $pgcmd -c "copy $t (x,y,) from stdin with delimiter ' ' csv" < $1
    rm $tempm
}

pg_cleanup() {
    echo "Indexing..."
    $pgcmd -c "create index on $t (x,y,pga,pgv,mmi,psa03,psa10,psa30);"
}

pg_values() {
	echo "Calculating…"
	# is this really how you assign variables?
	min='$pgcmd -c "select min($c) from $table"'
	max='$pgcmd -c "select max($c) from $table"'
	avg='$pgcmd -c "select avg($c) from $table"'
}

write_ramp() {
	echo "Creating color ramp"
	min1=$[min + 1]
	echo "$min	255	255	255" > ${table}-ramp.txt
	echo "$min1	252	255	238" >> ${table}-ramp.txt
	echo "$avg	255	180	99" >> ${table}-ramp.txt
	echo "$max	255	86	78" >> ${table}-ramp.txt
}

export() {
    if [ -z $outfile ]; then
        outfile="${table}-${column}.tif"
    fi
    tempfile=$(mktemp)

    # Export as XYZ from the PostgreSQL DB to a temporary file
    $pgcmd -c "copy (select x, y, $c) to stdout with csv delimiter ' ';" > $temp1

    # Convert the tempfile to a GeoTIFF
    gdal_translate -co compress=lzw -a_srs EPSG:4326 $temp1 $temp2

    # Clean up
    rm $temp1
}

mapify() {
	# Colorize
	gdaldem color-relief ${table}-ramp.txt $temp2 $temp3 
	
	# Reproject
	gdalwarp -s_srs EPSG:4326 -t_srs EPSG:900913 $temp3 $outfile

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
#	but is the the right way to do 'and'??
if [ $opt_import = 0 ] && [ $opt_export = 0 ]; then
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