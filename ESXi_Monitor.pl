#!/usr/bin/perl
# -------------------------------
# Edit by Tony
# Version : 2015/01/29
# Purpose : ESXi Monitor
#--------------------------------
use strict;
use warnings;
use VMware::VIM2Runtime;
use VMware::VILib;
use VMware::VICredStore;

until ($#ARGV==1) {
    print "\nUsage: esxi_check.pl <ESXi Management IP> <Login Account>\n\n";
    exit 1;
}

my $host_address = $ARGV[0];
my $user = $ARGV[1];

my $credstore_file = "/root/.vmware/credstore/vicredentials_".$host_address.".xml";


# read and validate command-line parameters
Opts::parse();
#Opts::validate();
Opts::set_option("username", $user);
Opts::set_option("url", "https://$host_address/sdk");

VMware::VICredStore::init(filename => $credstore_file);
my $cred_password = VMware::VICredStore::get_password(server => $host_address, username => $user);
VMware::VICredStore::close();

# connect to the server and login
Util::connect("https://".$host_address, $user, $cred_password);


my $found = 0;
# get VirtualMachine views for all powered on virtual machines
my $host_views = Vim::find_entity_views(view_type => 'HostSystem');
#                                        properties => ['name', 'hardware', 'summary']);

foreach my $host_view (@$host_views) {
   my $esxhost_name = $host_view->name;
   my $cpu_usage = $host_view->summary->quickStats->overallCpuUsage;
   my $cpu_total = $host_view->hardware->cpuInfo->hz * $host_view->hardware->cpuInfo->numCpuCores / 1000000;
   my $cpu_free_percent = ($cpu_total-$cpu_usage) / $cpu_total * 100;
   my $mem_usage = $host_view->summary->quickStats->overallMemoryUsage;
   my $mem_total = $host_view->hardware->memorySize / 1024/1024;
   my $mem_free_percent = ($mem_total-$mem_usage) / $mem_total * 100;
   printf "ESXi_Name\t\t%s\n",$esxhost_name;
   printf "CPU\t\t\tFreePercent=%.1f\t\tTotal=%.2fGHz\tFree=%.2fGHz\n", $cpu_free_percent, $cpu_total, $cpu_total-$cpu_usage;
   printf "Memory\t\t\tFreePercent=%.1f\t\tTotal=%.0fMB\t\tFree=%.0fMB\n", $mem_free_percent, $mem_total, $mem_total-$mem_usage;

   my $datastores = Vim::get_views(mo_ref_array => $host_view->datastore);
   foreach my $datastore (@$datastores) {
        my $space_total = $datastore->summary->capacity / 1024/1024/1024;
        my $space_free = $datastore->summary->freeSpace / 1024/1024/1024;
        my $space_free_percent = $space_free/$space_total*100;
        my $datastorename = $datastore->summary->name;
        printf "%s\t\tFreePercent=%.1f\t\tTotal=%.2fGB\t\tFree=%.2fGB\n", $datastorename, $space_free_percent, $space_total, $space_free;
   }
}
# close server connection
Util::disconnect();
