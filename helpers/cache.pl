#!/usr/bin/perl
# Simple script to cache a value for later use
# Usage:
# cache.pl key value...

use strict;
use BerkeleyDB;
use English;
use Data::Dumper;
use vars qw(%cache $dbfile $db $retention_time);

# In seconds, every 1 hour or so something expires
my $HOME = $ENV{HOME};
$retention_time = 7200;
$dbfile = "$HOME/.sanoma_jenkins_cache.bdb";

mkdir "/tmp/bcache/";
my $env = new BerkeleyDB::Env
                  -Home   => "/tmp/bcache" ,
                  -Flags  => DB_CREATE| DB_INIT_CDB | DB_INIT_MPOOL
        or die "cannot open environment: $BerkeleyDB::Error\n";


sub write_cache {
    $db = tie %cache, 'BerkeleyDB::Btree',
     -Filename => $dbfile,
    -Flags => DB_CREATE,
    -Env => $env,
    -Mode => 0644 or die "Cannot open db: $BerkeleyDB::Error";
}


sub read_cache {
    $db = tie %cache, 'BerkeleyDB::Btree',
     -Filename => $dbfile,
    -Flags => DB_RDONLY,
    -Env => $env,
    -Mode => 0644 or die "Cannot open db: $BerkeleyDB::Error";
}

sub write_key {
    my $key = shift;
    my $ret = shift;
    my $val = shift;
    my $ts = time;
    $ret = $retention_time, if $ret == 0;
    $ts += $ret;
    my $lock;
    if($db->cds_enabled){
	$lock = $db->cds_lock();
    }
    $cache{$key} = $val;
    $cache{$key."timeout"} = $ts;
    if($db->cds_enabled){
	$lock->cds_unlock();
    }
}
sub delete_key {
    my $key = shift;
    undef $cache{$key};
    undef $cache{$key."timeout"};
}

sub get_key_ttl {
    my $key = shift;
    return $cache{$key."timeout"};
}

sub get_key {
    my $ts = time;
    my $key = shift;
    if($cache{$key} && $cache{$key."timeout"} > $ts){
	return $cache{$key};
    }
}
my $cmd = shift @ARGV;
my $key = shift @ARGV;

die "Need a command", unless $cmd ne "";
die "Need a key", unless $key ne "";


if ( $cmd eq "read" ) {
    read_cache;
    my $val = get_key($key);
    if($val){
	print $val;
    } else {
	exit 1;
    }
} elsif ($cmd eq "write")  {
    write_cache;
    my $ret = shift @ARGV;
    die "Need a retention time", unless $ret > 0;
    my $val =  join " ", @ARGV;
    write_key($key, $ret, $val);
} elsif ($cmd eq "delete") {

    write_cache;
    delete_key($key);
} elsif ($cmd eq "ttl"){
    read_cache;

	my $val = get_key_ttl($key);
    if($val){
	print $val;
    } else {
	exit 1;
    }
} else {
    die "Need one of read, write or delete";
}

untie %cache;
exit 0;
