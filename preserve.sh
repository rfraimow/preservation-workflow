#!/bin/bash
SOURCE=$1
METADATA=$2
DEST1=$3
DEST2=$4

die() { echo "$@" 1>&2 ; exit 1; }

if [ $# -lt 4 ]; then
  die "USAGE: $0 SOURCE METADATA DEST1 DEST2"
fi 

which sweep   || die 'Require "sweep", a CLI to Sophos'
which fits.sh || die 'Add fits to PATH and chmod: "PATH=$PATH:/.../fits; chmod a+x "/.../fits/fits.sh"'

# Keep this after usage to keep output clean.
set -ex

mkdir $METADATA

###############
# Sophos scan
###############

( 
  if [ "$CI" = 'true' ]; then
    echo 'fake sophos output'
  else
    sweep $SOURCE # TODO: any non-default parameters?
  fi
) > $METADATA/sophos.txt

###################
# Clean filenames
###################

find $SOURCE | perl -ne 'chomp; next unless /[:;,]/; $clean=$_; $clean=~s/[:;,]/_/g; `mv "$_" "$clean"`'
# TODO: just get the script that's currently in use...

##############
# List files
##############

find $SOURCE > $METADATA/files.txt

########
# Copy
########

cp -a $SOURCE $DEST1
cp -a $SOURCE $DEST2

########
# Hook
########

if [ "$HOOK" ]; then
  eval $HOOK
fi

########
# Diff
########

diff -qr $SOURCE $DEST1
diff -qr $SOURCE $DEST2

########
# FITS
########

mkdir $METADATA/fits
if [ "$CI" = 'true' ]; then
  echo 'fake FITS output' > $METADATA/fits/fake-fits.xml
else
  fits.sh -i $SOURCE -o $METADATA/fits -r
fi
zip -r $METADATA/fits.zip $METADATA/fits
for FITS in `ls $METADATA/fits/*`; do mv $FITS $FITS.txt; done
