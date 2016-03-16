#!/usr/bin/perl
# -------------------------------
# Edit by Tony
# Version : 2014/12/29
# Purpose : VM Snapshot
#--------------------------------
use strict;
use warnings;
use VMware::VIM2Runtime;
use VMware::VILib;

# read and validate command-line parameters
Opts::parse();
Opts::validate();
Opts::set_option("username", "root");
Opts::set_option("password", 'xxxxxxx');
Opts::set_option("url", "https://192.168.1.101/sdk");

# connect to the server and login
Util::connect();

# get VirtualMachine views for all powered on virtual machines
my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                                      filter => { 'runtime.powerState' => 'poweredOn' });

# snapshot each virtual machine
foreach (@$vm_views) {
#   $_->CreateSnapshot(name => 'snapshot sample',
#                      description => 'Snapshot created from workshop sample',
#                      memory => 0,
#                      quiesce => 0);
   print "Snapshot complete for VM: " . $_->name . "\n";
}

# close server connection
Util::disconnect();
