#!/usr/bin/env bash
#
# Copyright (c) 2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C

TRAVIS_COMMIT_LOG=`git log --format=fuller -1`
export TRAVIS_COMMIT_LOG
OUTDIR=$BASE_OUTDIR/$TRAVIS_PULL_REQUEST/$TRAVIS_JOB_NUMBER-$HOST
BITCOIN_CONFIG_ALL="--disable-dependency-tracking --prefix=$TRAVIS_BUILD_DIR/depends/$HOST --bindir=$OUTDIR/bin --libdir=$OUTDIR/lib"

BEGIN_FOLD autogen
./autogen.sh
mkdir build
cd build || exit 1
END_FOLD

BEGIN_FOLD configure
../configure --cache-file=config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG || ( cat config.log && false)
END_FOLD

BEGIN_FOLD distdir
make distdir VERSION=$HOST
cd bitcoin-$HOST || exit 1
END_FOLD distdir

BEGIN_FOLD configure
./configure --cache-file=../config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG || ( cat config.log && false)
END_FOLD

BEGIN_FOLD compile
make $MAKEJOBS $GOAL  || ( echo "Build failure. Verbose build follows." && make $GOAL V=1 ; false )
END_FOLD

BEGIN_FOLD unit-tests
if [ "$RUN_TESTS" = "true" ]; then
    LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/depends/$HOST/lib make $MAKEJOBS check VERBOSE=1
fi
END_FOLD

BEGIN_FOLD functional-tests
if [ "$TRAVIS_EVENT_TYPE" = "cron" ]; then
    extended="--extended --exclude feature_pruning,feature_dbcrash"
fi
if [ "$RUN_TESTS" = "true" ]; then
    ./test/functional/test_runner.py --combinedlogslen=4000 --coverage --quiet --failfast ${extended}
fi
END_FOLD

